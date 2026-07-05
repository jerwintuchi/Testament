import type { RoomManager } from '../RoomManager.js';
import type { ReconnectTokenStore } from '../ReconnectTokenStore.js';
import type { EmitFn, EmitToFn, BroadcastFn } from '../types.js';
import { buildStubFieldData } from '../fieldData.js';
import { assertPhase } from '../phaseGuard.js';
import { deriveAmbientSigns } from '../../incarnate/deriveSigns.js';
import { perceivedChannelsFor, filterSigns } from '../perception.js';
import { generateSite } from '../../site/generateSite.js';
import { startFieldTick } from '../fieldTick.js';
import { createRng, hashSeed } from '../../rng/seeded.js';
import { SERVER_MESSAGES, TILE_SIZE } from '@testament/shared';
import type { SiteLayout, PlayerPositions } from '@testament/shared';

// Distinct feet spawn points (px, tile centers) drawn from floor tiles nearest
// the APPROACH node by 4-neighbor BFS — so the whole party lands inside the
// Approach room. Deterministic (fixed neighbor order): same site → same spawns.
function spawnPoints(site: SiteLayout, count: number): Array<{ x: number; y: number }> {
  const approach = site.nodes.find(n => n.kind === 'APPROACH')!;
  const { width, height, rows } = site.grid;
  const seen = new Set<string>([`${approach.x},${approach.y}`]);
  const order: Array<{ x: number; y: number }> = [{ x: approach.x, y: approach.y }];
  const queue: Array<{ x: number; y: number }> = [{ x: approach.x, y: approach.y }];
  while (queue.length > 0 && order.length < count) {
    const { x, y } = queue.shift()!;
    for (const [dx, dy] of [[1, 0], [-1, 0], [0, 1], [0, -1]] as const) {
      const nx = x + dx;
      const ny = y + dy;
      const key = `${nx},${ny}`;
      if (nx < 0 || ny < 0 || nx >= width || ny >= height || seen.has(key)) continue;
      if (rows[ny]![nx] !== '.') continue;
      seen.add(key);
      order.push({ x: nx, y: ny });
      queue.push({ x: nx, y: ny });
    }
  }
  return order.slice(0, count).map(t => ({
    x: t.x * TILE_SIZE + TILE_SIZE / 2,
    y: t.y * TILE_SIZE + TILE_SIZE / 2,
  }));
}

export function handleDeploy(
  socketId: string,
  roomManager: RoomManager,
  tokenStore: ReconnectTokenStore,
  emit: EmitFn,
  emitTo: EmitToFn,
  broadcast: BroadcastFn,
): void {
  const room = roomManager.getRoomBySocketId(socketId);
  if (!assertPhase(room, 'DEPLOYING', emit)) return;

  const sender = room.players.find(p => p.socketId === socketId);
  if (!sender?.isLeader) {
    emit(SERVER_MESSAGES.LOBBY_ERROR, { code: 'NOT_LEADER', message: 'Only the leader can initiate deployment.' });
    return;
  }

  // room.contract is guaranteed non-null when phase is DEPLOYING (set by acceptContract).
  const contract  = room.contract!;
  const fieldData = buildStubFieldData(contract);
  // Ambient signs only — the REACTION channel is probe-gated (R58, P22).
  const signs     = deriveAmbientSigns(contract.traitRoll, contract.tier);

  // Field-space (R85): generate the site on its own seed stream so contract and
  // trait-roll streams are untouched, then spawn the party in the Approach room.
  const site  = generateSite(createRng(hashSeed(contract.expeditionSeed + ':site')));
  const spawns = spawnPoints(site, room.players.length);
  const positions: PlayerPositions = {};
  room.players.forEach((player, i) => {
    player.pos = spawns[i]!;
    player.moveIntent = { dx: 0, dy: 0 };
    positions[player.playerId] = spawns[i]!;
  });

  room.phase         = 'FIELD';
  room.fieldData     = fieldData;
  room.exposure      = 0;
  room.revealedSigns = [];
  room.site          = site;

  // Distributed Perception (R66): perception is a consequence of the bag (TD-007).
  // Solo perceives all tier channels regardless of gear (TD-008).
  const isSolo = room.players.length === 1;

  // FIELD_STARTED is per-player: own reconnect token, own filtered signs.
  for (const player of room.players) {
    player.perceivedChannels = perceivedChannelsFor(player.bag, isSolo, contract.tier);
    const token = tokenStore.issue(player.playerId, room.code);
    emitTo(player.socketId, SERVER_MESSAGES.FIELD_STARTED, {
      fieldData,
      reconnectToken:    token,
      signs:             filterSigns(signs, player.perceivedChannels),
      perceivedChannels: player.perceivedChannels,
      site,
      positions,
    });
  }

  // Start the authoritative movement tick now that positions exist (R87).
  startFieldTick(room, broadcast);
}

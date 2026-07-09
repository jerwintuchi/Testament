import type { RoomManager } from '../RoomManager.js';
import type { ReconnectTokenStore } from '../ReconnectTokenStore.js';
import type { EmitFn, EmitToFn, BroadcastFn } from '../types.js';
import { buildStubFieldData } from '../fieldData.js';
import { toContractIntel } from '../../incarnate/generateContract.js';
import { deriveAmbientSigns } from '../../incarnate/deriveSigns.js';
import { perceivedChannelsFor, filterSigns } from '../perception.js';
import { generateSite } from '../../site/generateSite.js';
import { spawnFanOut } from '../../site/spawn.js';
import { atStation } from '../stations.js';
import { createRng, hashSeed } from '../../rng/seeded.js';
import { SERVER_MESSAGES } from '@testament/shared';
import type { PlayerPositions } from '@testament/shared';

export function handleDeploy(
  socketId: string,
  roomManager: RoomManager,
  tokenStore: ReconnectTokenStore,
  emit: EmitFn,
  emitTo: EmitToFn,
  broadcast: BroadcastFn,
): void {
  const room = roomManager.getRoomBySocketId(socketId);
  if (!room) {
    emit(SERVER_MESSAGES.LOBBY_ERROR, { code: 'NOT_IN_ROOM', message: 'You are not in any room.' });
    return;
  }
  if (room.phase !== 'WAITING' && room.phase !== 'DEPLOYING') {
    emit(SERVER_MESSAGES.LOBBY_ERROR, { code: 'WRONG_PHASE', message: `Cannot deploy in ${room.phase}.` });
    return;
  }

  const sender = room.players.find(p => p.socketId === socketId);
  if (!sender?.isLeader) {
    emit(SERVER_MESSAGES.LOBBY_ERROR, { code: 'NOT_LEADER', message: 'Only the leader can initiate deployment.' });
    return;
  }
  // Deploy is an action at the Deploy Gate (R101), the mirror of field
  // Extraction: the leader must stand on the gate to send the party out.
  if (!atStation(sender.pos, 'DEPLOY_GATE')) {
    emit(SERVER_MESSAGES.LOBBY_ERROR, { code: 'NOT_AT_DEPLOY_GATE', message: 'Stand at the Deploy Gate to deploy.' });
    return;
  }

  // Stage 1 — commit (TD-041): WAITING -> DEPLOYING. The reversible selection made
  // at the Contract Board is committed here (this is where the Surety will be staked
  // once that system lands), opening the pre-deployment staging (Quartermaster
  // requisition). A commit with no contract selected is rejected to the sender only,
  // no mutation (I2).
  if (room.phase === 'WAITING') {
    if (!room.contract) {
      emit(SERVER_MESSAGES.LOBBY_ERROR, { code: 'NO_CONTRACT_SELECTED', message: 'Select a contract at the board before deploying.' });
      return;
    }
    room.phase = 'DEPLOYING';
    broadcast(room.code, SERVER_MESSAGES.ROOM_DEPLOYING, { contract: toContractIntel(room.contract) });
    return;
  }

  // Stage 2 — launch: DEPLOYING -> FIELD. room.contract is guaranteed non-null in
  // DEPLOYING (set at selection, required at the Stage-1 commit).
  const contract  = room.contract!;
  const fieldData = buildStubFieldData(contract);
  // Ambient signs only — the REACTION channel is probe-gated (R58, P22).
  const signs     = deriveAmbientSigns(contract.traitRoll, contract.tier);

  // Field-space (R85): generate the site on its own seed stream so contract and
  // trait-roll streams are untouched, then spawn the party in the Approach room.
  const site  = generateSite(createRng(hashSeed(contract.expeditionSeed + ':site')));
  const approach = site.nodes.find(n => n.kind === 'APPROACH')!;
  const spawns = spawnFanOut(site.grid, approach, room.players.length);
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

  // No tick start here: the movement tick has run since room creation (Collegium
  // R96); entering FIELD just sets room.site, so activeGrid() swaps the party
  // from the Collegium grid to the site grid under the already-running tick.
}

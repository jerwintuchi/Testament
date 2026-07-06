// Wire-protocol message payload types for the Field Phase system.
// Types only — no logic (invariant I4). All messages use the envelope:
//   { "type": "EVENT_NAME", "payload": { ... } }

import type { StubFieldData, StubTestament, StubArchiveEntry } from './fieldPhase.js';
import type { Channel, Sign, Stimulus } from './signs.js';
import type { SiteLayout } from './site.js';

// Feet position in px. playerId → point. Used in FIELD_STARTED, POSITIONS, and
// the reconnect snapshot.
export type PlayerPositions = Record<string, { x: number; y: number }>;

// ── Client → Server ───────────────────────────────────────────────────────────

export type DeployPayload = Record<string, never>;

export type ExtractPayload = Record<string, never>;

export type ProbePayload = { stimulus: Stimulus };

// Movement intent — a direction, each component in [-1, 1], plus an optional
// `walk` modifier (default false = run). The server samples it once per field
// tick and applies the authoritative speed (run vs walk); message rate cannot
// outrun the speed the server chooses (I1). `walk` is optional so an older
// client that omits it simply runs.
export type MovePayload = { dx: number; dy: number; walk?: boolean };

// ── Server → Client ───────────────────────────────────────────────────────────

export type FieldStartedPayload = {
  fieldData:         StubFieldData;
  reconnectToken:    string;     // per-player token; delivered individually, not as a broadcast
  signs:             Sign[];     // ambient signs, filtered to this player's perceived channels
  perceivedChannels: Channel[];  // this player's own perception set — never other players' sets
  site:              SiteLayout;      // the field-space this party deploys into
  positions:         PlayerPositions; // every player's spawn feet-position, px
};

// Server → Room delta: players whose position changed this field tick. Only
// moved players appear (I6); a tick with no movement broadcasts nothing.
export type PositionsPayload = { positions: PlayerPositions };

export type FieldTestamentPayload = {
  testament: StubTestament;
};

export type ArchiveUpdatedPayload = {
  entries: StubArchiveEntry[];
};

export type ProbeResultPayload = {
  playerId: string;       // who probed (the party sees who spent the exposure)
  stimulus: Stimulus;     // echo of the client-chosen stimulus — party behavior, not trait data
  sign:     Sign | null;  // the reaction sign for REACTION perceivers; null = "you cannot read it"
  exposure: number;       // room exposure after this probe — party noise, not Incarnate knowledge
};

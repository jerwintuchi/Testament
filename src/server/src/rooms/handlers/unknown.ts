import type { EmitFn } from '../types.js';
import { SERVER_MESSAGES } from '@testament/shared';

export function handleUnknownMessage(
  socketId: string,
  type: string,
  emit: EmitFn,
): void {
  emit(SERVER_MESSAGES.LOBBY_ERROR, {
    code: 'INVALID_PAYLOAD',
    message: `Unrecognized message type: "${type}"`,
  });
}

import { WebSocketServer, WebSocket } from "ws";
import { Server as HttpServer } from "http";
import jwt from "jsonwebtoken";
import { IncomingMessage } from "http";

interface JwtPayload {
  sub: string;
  role: string;
}

interface Connection {
  ws: WebSocket;
  role: string;
}

const connectedUsers = new Map<string, Connection>();

export function initWsServer(server: HttpServer): void {
  const wss = new WebSocketServer({ server });

  wss.on("connection", (ws: WebSocket, req: IncomingMessage) => {
    const rawUrl = req.url ?? "";
    const queryStart = rawUrl.indexOf("?");
    const token = queryStart !== -1
      ? new URLSearchParams(rawUrl.slice(queryStart)).get("token")
      : null;

    if (!token) {
      ws.close(1008, "Token não fornecido");
      return;
    }

    const secret = process.env.JWT_SECRET;
    if (!secret) {
      ws.close(1011, "JWT_SECRET não configurado");
      return;
    }

    let userId: string;
    let role: string;
    try {
      const payload = jwt.verify(token, secret) as JwtPayload;
      const sub = (payload as any).sub as string | undefined;
      if (!sub) {
        ws.close(1008, "Invalid token payload");
        return;
      }
      userId = sub;
      role = payload.role;
    } catch {
      ws.close(1008, "Token inválido ou expirado");
      return;
    }

    connectedUsers.set(userId, { ws, role });

    ws.on("close", () => {
      connectedUsers.delete(userId);
    });
  });

  console.log("[wsServer] WebSocket server inicializado");
}

export function notifyUser(userId: string, payload: object): void {
  const conn = connectedUsers.get(userId);
  if (!conn || conn.ws.readyState !== WebSocket.OPEN) {
    return;
  }
  try {
    conn.ws.send(JSON.stringify(payload));
  } catch (err) {
    console.error(`[wsServer] Erro ao enviar mensagem para usuário ${userId}:`, err);
  }
}

export function notifyRole(role: string, payload: object): void {
  const message = JSON.stringify(payload);
  for (const [userId, conn] of connectedUsers) {
    if (conn.role !== role || conn.ws.readyState !== WebSocket.OPEN) {
      continue;
    }
    try {
      conn.ws.send(message);
    } catch (err) {
      console.error(`[wsServer] Erro ao enviar mensagem para usuário ${userId}:`, err);
    }
  }
}

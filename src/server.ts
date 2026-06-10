import "reflect-metadata";
import dotenv from "dotenv";
dotenv.config();

import http from "http";
import { AppDataSource } from "./config/database";
import app from "./app";
import { startConsumers } from "./events/consumers/OrderConsumer";
import { initWsServer } from "./websocket/wsServer";

const PORT = process.env.PORT || 3000;

AppDataSource.initialize()
  .then(async () => {
    console.log("Banco de dados conectado");
    try {
      await startConsumers();
    } catch (err) {
      console.error("Erro ao conectar ao RabbitMQ:", err);
      process.exit(1);
    }
    const server = http.createServer(app);
    initWsServer(server);
    server.listen(PORT, () => {
      console.log(`UaiKiFome backend rodando na porta ${PORT}`);
    });
  })
  .catch((err) => {
    console.error("Erro ao conectar ao banco:", err);
    process.exit(1);
  });

import { ValueTransformer } from "typeorm";

// pg retorna colunas "decimal"/"numeric" como string para evitar perda de precisão.
// Sem isso, o valor volta como string nas consultas (mas como number no insert),
// quebrando o parsing no app (ex: cardápio fica vazio após relogin).
export const decimalTransformer: ValueTransformer = {
  to: (value?: number) => value,
  from: (value?: string) => (value === null || value === undefined ? value : parseFloat(value)),
};

-- =============================================================
-- PRJ1 - MATA60 (Marco 1)
-- ÍNDICES 100% SQL (ANSI) - PostgreSQL 12+
-- =============================================================

-- IMPORTANTE:
-- "Baseline" aqui significa SEM ÍNDICES ADICIONAIS criados pelo usuário.
-- Índices implícitos de PK/UK permanecem (não devem ser removidos,
-- pois são parte da integridade referencial).
--
-- Fluxo sugerido para avaliação de desempenho:
-- 1) Executar BLOCO A (BASELINE) -> medir 20x cada consulta.
-- 2) Executar BLOCO B (OTIMIZADO) -> medir 20x cada consulta.
-- 3) Calcular média, desvio padrão e speedup.

-- =============================================================
-- BLOCO A — BASELINE (remover índices adicionais do usuário)
-- =============================================================

-- DROP INDEX só remove índices criados no DDL de otimização.
-- PK/UK continuam (índices internos do PostgreSQL atrelados a constraints).

-- Comente/descomente este bloco quando for medir o baseline.
-- BEGIN;

DROP INDEX IF EXISTS IDX_TB_ATIVIDADE_ID_EVENTO;
DROP INDEX IF EXISTS IDX_TB_ATIVIDADE_DT_ATIVIDADE;
DROP INDEX IF EXISTS IDX_RL_AI_ID_INSTRUTOR;
DROP INDEX IF EXISTS IDX_RL_EP_ID_PARCEIRO;
DROP INDEX IF EXISTS IDX_TB_INSCRICAO_PARTICIPANTE;
DROP INDEX IF EXISTS IDX_TB_INSCRICAO_ATIVIDADE;
DROP INDEX IF EXISTS IDX_TB_FEEDBACK_PARTICIPANTE;
DROP INDEX IF EXISTS IDX_TB_FEEDBACK_ATIVIDADE;
DROP INDEX IF EXISTS IDX_TB_CERTIFICADO_PARTICIPANTE;
DROP INDEX IF EXISTS IDX_TB_CERTIFICADO_ATIVIDADE;
DROP INDEX IF EXISTS IDX_TB_PARTICIPANTE_CPF;
DROP INDEX IF EXISTS IDX_TB_PARCEIRO_CNPJ;
DROP INDEX IF EXISTS IDX_TA_AUDITORIA_DT;

-- (Opcional) confirmar que não restaram índices do usuário:
-- SELECT schemaname, indexname, tablename
-- FROM pg_indexes
-- WHERE indexname LIKE 'idx_%' ESCAPE '\'
-- ORDER BY tablename, indexname;

-- COMMIT;

-- =============================================================
-- BLOCO B — OTIMIZADO (criar índices recomendados)
-- =============================================================

-- Comente/descomente este bloco quando for medir a versão otimizada.
-- BEGIN;

-- ATIVIDADE: junções por evento e filtros por data
CREATE INDEX IF NOT EXISTS IDX_TB_ATIVIDADE_ID_EVENTO
    ON TB_ATIVIDADE (ID_EVENTO);

CREATE INDEX IF NOT EXISTS IDX_TB_ATIVIDADE_DT_ATIVIDADE
    ON TB_ATIVIDADE (DT_ATIVIDADE);

-- Relações N:N: acelerar junções pelo segundo lado
CREATE INDEX IF NOT EXISTS IDX_RL_AI_ID_INSTRUTOR
    ON RL_ATIVIDADE_INSTRUTOR (ID_INSTRUTOR);

CREATE INDEX IF NOT EXISTS IDX_RL_EP_ID_PARCEIRO
    ON RL_EVENTO_PARCEIRO (ID_PARCEIRO);

-- INSCRICAO: consultas por participante/atividade
CREATE INDEX IF NOT EXISTS IDX_TB_INSCRICAO_PARTICIPANTE
    ON TB_INSCRICAO (ID_PARTICIPANTE);

CREATE INDEX IF NOT EXISTS IDX_TB_INSCRICAO_ATIVIDADE
    ON TB_INSCRICAO (ID_ATIVIDADE);

-- FEEDBACK: análises por participante/atividade
CREATE INDEX IF NOT EXISTS IDX_TB_FEEDBACK_PARTICIPANTE
    ON TB_FEEDBACK (ID_PARTICIPANTE);

CREATE INDEX IF NOT EXISTS IDX_TB_FEEDBACK_ATIVIDADE
    ON TB_FEEDBACK (ID_ATIVIDADE);

-- CERTIFICADO: validações e relatórios por participante/atividade
CREATE INDEX IF NOT EXISTS IDX_TB_CERTIFICADO_PARTICIPANTE
    ON TB_CERTIFICADO (ID_PARTICIPANTE);

CREATE INDEX IF NOT EXISTS IDX_TB_CERTIFICADO_ATIVIDADE
    ON TB_CERTIFICADO (ID_ATIVIDADE);

-- CHAVES DE NEGÓCIO: buscas por CPF/CNPJ (únicas mas úteis para lookup)
CREATE INDEX IF NOT EXISTS IDX_TB_PARTICIPANTE_CPF
    ON TB_PARTICIPANTE (CD_CPF);

CREATE INDEX IF NOT EXISTS IDX_TB_PARCEIRO_CNPJ
    ON TB_PARCEIRO (CD_CNPJ);

-- AUDITORIA: séries temporais por data de operação
CREATE INDEX IF NOT EXISTS IDX_TA_AUDITORIA_DT
    ON TA_AUDITORIA (DT_OPERACAO);

-- COMMIT;

-- =============================================================
-- BLOCO C — ATUALIZAR ESTATÍSTICAS (ANALYZE)
-- =============================================================

-- Execute após criar os índices (bloco B) para que o otimizador
-- tenha estatísticas atualizadas nas tabelas mais consultadas.

ANALYZE TB_EVENTO;
ANALYZE TB_ATIVIDADE;
ANALYZE TB_PARTICIPANTE;
ANALYZE TB_INSTRUTOR;
ANALYZE TB_PARCEIRO;
ANALYZE RL_ATIVIDADE_INSTRUTOR;
ANALYZE RL_EVENTO_PARCEIRO;
ANALYZE TB_INSCRICAO;
ANALYZE TB_FEEDBACK;
ANALYZE TB_CERTIFICADO;
ANALYZE TA_AUDITORIA;

-- =============================================================
-- (Opcional) INSPEÇÃO RÁPIDA
-- =============================================================
-- SELECT schemaname, indexname, tablename
-- FROM pg_indexes
-- WHERE tablename IN (
--     'tb_evento','tb_atividade','tb_participante','tb_instrutor','tb_parceiro',
--     'rl_atividade_instrutor','rl_evento_parceiro','tb_inscricao','tb_feedback','tb_certificado','ta_auditoria'
-- )
-- ORDER BY tablename, indexname;

-- =============================================================
-- FIM DO indices_prj1.sql
-- =============================================================

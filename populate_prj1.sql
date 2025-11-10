-- =============================================================
-- PRJ1 - MATA60 (Marco 1)
-- POPULAÇÃO 100% SQL (ANSI) - PostgreSQL 12+
-- =============================================================

BEGIN;

TRUNCATE TABLE
    TB_CERTIFICADO,
    TB_FEEDBACK,
    TB_INSCRICAO,
    RL_EVENTO_PARCEIRO,
    RL_ATIVIDADE_INSTRUTOR,
    TB_ATIVIDADE,
    TB_EVENTO,
    TB_PARTICIPANTE,
    TB_INSTRUTOR,
    TB_PARCEIRO,
    TA_AUDITORIA
RESTART IDENTITY CASCADE;

-- EVENTOS
INSERT INTO TB_EVENTO (DS_TITULO, DS_DESCRICAO, DT_INICIO, DT_FIM, DS_LOCAL)
SELECT
    'Evento ' || g,
    'Edição ' || g || ' do evento institucional.',
    (DATE '2025-03-01' + ((g-1) * 7))::date,
    (DATE '2025-03-01' + ((g-1) * 7) + 4)::date,
    'Campus Principal - Bloco ' || ((g-1) % 5 + 1)
FROM generate_series(1, 20) AS g;

-- ATIVIDADES
INSERT INTO TB_ATIVIDADE (
    ID_EVENTO, DS_TITULO, DS_DESCRICAO, DT_ATIVIDADE,
    HR_INICIO, HR_FIM, TP_MODALIDADE, QT_VAGAS, DS_LOCAL, ST_ATIVA
)
SELECT
    ((g-1) % 20) + 1,
    'Atividade ' || g,
    'Atividade #' || g || ' do Evento ' || (((g-1) % 20) + 1),
    (SELECT DT_INICIO FROM TB_EVENTO e WHERE e.ID_EVENTO = ((g-1) % 20) + 1) + ((g-1) % 5),
    TIME '09:00' + make_interval(hours => ((g-1) % 6)),
    TIME '10:30' + make_interval(hours => ((g-1) % 6)),
    (ARRAY['palestra','minicurso','mesa','workshop'])[((g-1) % 4) + 1],
    20 + ((g-1) % 31),
    'Sala ' || ((g-1) % 12 + 101),
    TRUE
FROM generate_series(1, 400) AS g;

-- PARTICIPANTES
INSERT INTO TB_PARTICIPANTE (NM_PARTICIPANTE, CD_CPF, DS_EMAIL, DT_NASCIMENTO, SG_SEXO, DS_TELEFONE)
SELECT
    'Participante ' || g,
    LPAD((10000000000 + g)::text, 11, '0'),
    'p' || g || '@mail.com',
    (DATE '1970-01-01' + ((g % 18000))::int),
    (ARRAY['M','F'])[(g % 2) + 1],
    '(71) 9' || LPAD((g % 99999999)::text, 8, '0')
FROM generate_series(1, 6000) AS g;

-- INSTRUTORES
INSERT INTO TB_INSTRUTOR (NM_INSTRUTOR, DS_EMAIL, CD_CPF, DS_FORMACAO, DS_AREA_ATUACAO)
SELECT
    'Instrutor ' || g,
    'i' || g || '@mail.com',
    LPAD((20000000000 + g)::text, 11, '0'),
    (ARRAY['Mestrado','Doutorado','Especialização'])[(g % 3) + 1],
    (ARRAY['Computação','Gestão','Educação','Engenharia'])[(g % 4) + 1]
FROM generate_series(1, 120) AS g;

-- PARCEIROS
INSERT INTO TB_PARCEIRO (NM_PARCEIRO, CD_CNPJ, DS_CONTATO, DS_EMAIL)
SELECT
    'Parceiro ' || g,
    LPAD((30000000000000 + g)::text, 14, '0'),
    'Contato ' || g,
    'parceiro' || g || '@mail.com'
FROM generate_series(1, 50) AS g;

-- RL ATIVIDADE x INSTRUTOR (garante não duplicar pares)
-- 1) Titular (sempre)
INSERT INTO RL_ATIVIDADE_INSTRUTOR (ID_ATIVIDADE, ID_INSTRUTOR, DS_PAPEL)
SELECT a_id, ((a_id - 1) % 120) + 1, 'titular'
FROM generate_series(1, 400) AS a_id;

-- 2) Apoio #1 (metade das atividades), evitando colisão com a PK
INSERT INTO RL_ATIVIDADE_INSTRUTOR (ID_ATIVIDADE, ID_INSTRUTOR, DS_PAPEL)
SELECT a_id,
       ((a_id * 7 - 1) % 120) + 1,
       'apoio'
FROM generate_series(1, 200) AS a_id
WHERE NOT EXISTS (
    SELECT 1
    FROM RL_ATIVIDADE_INSTRUTOR r
    WHERE r.ID_ATIVIDADE = a_id
      AND r.ID_INSTRUTOR = ((a_id * 7 - 1) % 120) + 1
);

-- 3) Apoio #2 (um quarto das atividades), evitando colisão
INSERT INTO RL_ATIVIDADE_INSTRUTOR (ID_ATIVIDADE, ID_INSTRUTOR, DS_PAPEL)
SELECT a_id,
       ((a_id * 11 - 1) % 120) + 1,
       'apoio'
FROM generate_series(1, 100) AS a_id
WHERE NOT EXISTS (
    SELECT 1
    FROM RL_ATIVIDADE_INSTRUTOR r
    WHERE r.ID_ATIVIDADE = a_id
      AND r.ID_INSTRUTOR = ((a_id * 11 - 1) % 120) + 1
);

-- RL EVENTO x PARCEIRO
INSERT INTO RL_EVENTO_PARCEIRO (ID_EVENTO, ID_PARCEIRO, DS_PAPEL)
SELECT e_id, ((e_id - 1) % 50) + 1, 'patrocinador'
FROM generate_series(1, 20) AS e_id;

INSERT INTO RL_EVENTO_PARCEIRO (ID_EVENTO, ID_PARCEIRO, DS_PAPEL)
SELECT e_id, ((e_id * 3 - 1) % 50) + 1, 'apoio'
FROM generate_series(1, 20) AS e_id;

INSERT INTO RL_EVENTO_PARCEIRO (ID_EVENTO, ID_PARCEIRO, DS_PAPEL)
SELECT e_id, ((e_id * 5 - 1) % 50) + 1, 'apoio'
FROM generate_series(1, 10) AS e_id;

INSERT INTO RL_EVENTO_PARCEIRO (ID_EVENTO, ID_PARCEIRO, DS_PAPEL)
SELECT e_id, ((e_id * 7 - 1) % 50) + 1, 'apoiador'
FROM generate_series(1, 5) AS e_id;

-- INSCRIÇÕES (12.000 pares únicos)
INSERT INTO TB_INSCRICAO (ID_PARTICIPANTE, ID_ATIVIDADE, DT_INSCRICAO, ST_CONFIRMADA)
SELECT ((g-1) % 6000) + 1,
       (((g-1) % 400) + 1),
       (DATE '2025-02-01' + ((g-1) % 60)),
       ((g % 10) <> 0)
FROM generate_series(1, 6000) AS g;

INSERT INTO TB_INSCRICAO (ID_PARTICIPANTE, ID_ATIVIDADE, DT_INSCRICAO, ST_CONFIRMADA)
SELECT ((g-1) % 6000) + 1,
       ((((g-1) % 400) + 1 + 1) - 1) % 400 + 1,  -- desloca atividade +1
       (DATE '2025-02-01' + ((g-1) % 60)),
       ((g % 10) <> 0)
FROM generate_series(6001, 12000) AS g;

-- FEEDBACK (~ 2/3 das confirmadas)
INSERT INTO TB_FEEDBACK (
    ID_PARTICIPANTE, ID_ATIVIDADE,
    VL_NOTA_CONTEUDO, VL_NOTA_INSTRUTOR, VL_NOTA_ORGANIZACAO,
    DS_COMENTARIO, DT_AVALIACAO
)
SELECT i.ID_PARTICIPANTE,
       i.ID_ATIVIDADE,
       ((i.ID_INSCRICAO        % 5) + 1),
       (((i.ID_INSCRICAO * 3)  % 5) + 1),
       (((i.ID_INSCRICAO * 11) % 5) + 1),
       'Feedback da inscrição #' || i.ID_INSCRICAO,
       (i.DT_INSCRICAO + ((i.ID_INSCRICAO % 7)))::date
FROM TB_INSCRICAO i
WHERE i.ST_CONFIRMADA = TRUE
  AND (i.ID_INSCRICAO % 3) <> 0;

-- CERTIFICADO (~ 50% das confirmadas)
INSERT INTO TB_CERTIFICADO (
    ID_PARTICIPANTE, ID_ATIVIDADE, NR_CARGA_HORARIA, DT_EMISSAO, CD_VALIDACAO
)
SELECT i.ID_PARTICIPANTE,
       i.ID_ATIVIDADE,
       ((i.ID_ATIVIDADE % 4) + 1) * 2.5::numeric(4,1),
       (i.DT_INSCRICAO + ((i.ID_INSCRICAO % 10)))::date,
       LPAD(TO_HEX(i.ID_INSCRICAO), 8, '0') || LPAD(TO_HEX(i.ID_PARTICIPANTE), 8, '0')
       || LPAD(TO_HEX(i.ID_ATIVIDADE), 8, '0') || LPAD(TO_HEX((i.ID_INSCRICAO * 13) % 65536), 4, '0')
FROM TB_INSCRICAO i
WHERE i.ST_CONFIRMADA = TRUE
  AND (i.ID_INSCRICAO % 2) = 0;

COMMIT;

-- =============================================================
-- VERIFICAÇÕES RÁPIDAS (opcionais)
-- =============================================================
-- SELECT COUNT(*) AS eventos       FROM TB_EVENTO;
-- SELECT COUNT(*) AS atividades    FROM TB_ATIVIDADE;
-- SELECT COUNT(*) AS participantes FROM TB_PARTICIPANTE;
-- SELECT COUNT(*) AS instrutores   FROM TB_INSTRUTOR;
-- SELECT COUNT(*) AS parceiros     FROM TB_PARCEIRO;
-- SELECT COUNT(*) AS rl_ativ_instr FROM RL_ATIVIDADE_INSTRUTOR;
-- SELECT COUNT(*) AS rl_evt_parc   FROM RL_EVENTO_PARCEIRO;
-- SELECT COUNT(*) AS inscricoes    FROM TB_INSCRICAO;
-- SELECT COUNT(*) AS feedbacks     FROM TB_FEEDBACK;
-- SELECT COUNT(*) AS certificados  FROM TB_CERTIFICADO;

-- Sanidade:
-- 1) Toda atividade tem instrutor?
--    SELECT COUNT(*) FROM TB_ATIVIDADE a
--    WHERE NOT EXISTS (SELECT 1 FROM RL_ATIVIDADE_INSTRUTOR r WHERE r.ID_ATIVIDADE = a.ID_ATIVIDADE);
--
-- 2) Feedback único por (participante, atividade)?
--    SELECT COUNT(*) FROM TB_FEEDBACK GROUP BY ID_PARTICIPANTE, ID_ATIVIDADE HAVING COUNT(*) > 1;
--
-- 3) Certificado único por (participante, atividade)?
--    SELECT COUNT(*) FROM TB_CERTIFICADO GROUP BY ID_PARTICIPANTE, ID_ATIVIDADE HAVING COUNT(*) > 1;

-- =============================================================
-- FIM DO populate_prj1.sql
-- =============================================================

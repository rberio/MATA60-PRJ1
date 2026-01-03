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

-- EVENTOS (usando CTE recursiva ANSI)
WITH RECURSIVE series_20(g) AS (
    SELECT 1
    UNION ALL
    SELECT g + 1 FROM series_20 WHERE g < 20
)
INSERT INTO TB_EVENTO (DS_TITULO, DS_DESCRICAO, DT_INICIO, DT_FIM, DS_LOCAL)
SELECT
    'Evento ' || g,
    'Edição ' || g || ' do evento institucional.',
    CURRENT_DATE + (CAST((g - 10) * 7 AS INTEGER)),
    CURRENT_DATE + (CAST((g - 10) * 7 + 4 AS INTEGER)),
    'Campus Principal - Bloco ' || ((g-1) % 5 + 1)
FROM series_20;

-- ATIVIDADES
WITH RECURSIVE series_400(g) AS (
    SELECT 1
    UNION ALL
    SELECT g + 1 FROM series_400 WHERE g < 400
)
INSERT INTO TB_ATIVIDADE (
    ID_EVENTO, DS_TITULO, DS_DESCRICAO, DT_ATIVIDADE,
    HR_INICIO, HR_FIM, TP_MODALIDADE, QT_VAGAS, QT_CARGA_HORARIA,
    DS_LOCAL, ST_ATIVA, TP_FORMATO
)
SELECT
    ((g-1) % 20) + 1,
    'Atividade ' || g,
    'Atividade #' || g || ' do Evento ' || (((g-1) % 20) + 1),
    (SELECT DT_INICIO FROM TB_EVENTO e WHERE e.ID_EVENTO = ((g-1) % 20) + 1) + ((g-1) % 5),
    TIME '09:00' + CAST(((g-1) % 6) || ' hours' AS INTERVAL),
    TIME '10:30' + CAST(((g-1) % 6) || ' hours' AS INTERVAL),
    CASE ((g-1) % 4)
        WHEN 0 THEN 'palestra'
        WHEN 1 THEN 'minicurso'
        WHEN 2 THEN 'mesa'
        WHEN 3 THEN 'workshop'
    END,
    20 + ((g-1) % 31),
    CAST(((g % 4) + 1) * 2.0 AS NUMERIC(4,1)),
    'Sala ' || ((g-1) % 12 + 101),
    TRUE,
    CASE (g % 5) 
        WHEN 0 THEN 'Online' 
        ELSE 'Presencial' 
    END
FROM series_400;

-- PARTICIPANTES
WITH RECURSIVE series_6000(g) AS (
    SELECT 1
    UNION ALL
    SELECT g + 1 FROM series_6000 WHERE g < 6000
)
INSERT INTO TB_PARTICIPANTE (NM_PARTICIPANTE, CD_CPF, DS_EMAIL, DT_NASCIMENTO, SG_SEXO, DS_TELEFONE)
SELECT
    'Participante ' || g,
    LPAD(CAST((10000000000 + g) AS VARCHAR), 11, '0'),
    -- DIVERSIFICAÇÃO DE DOMÍNIOS
    'p' || g || (
        CASE (g % 4)
            WHEN 0 THEN '@gmail.com'
            WHEN 1 THEN '@outlook.com'
            WHEN 2 THEN '@ufba.br'
            ELSE '@servidor.gov'
        END
    ),
    -- DIVERSIFICAÇÃO DE IDADES
    -- Gera datas entre 1965 e 2006 (espalhando os dias com g * 7 para não ficar sequencial)
    DATE '1965-01-01' + (CAST((g * 7) % 15000 AS INTEGER)),
    CASE (g % 2)
        WHEN 0 THEN 'M'
        ELSE 'F'
    END,
    '(71) 9' || LPAD(CAST((g % 99999999) AS VARCHAR), 8, '0')
FROM series_6000;

-- INSTRUTORES
WITH RECURSIVE series_120(g) AS (
    SELECT 1
    UNION ALL
    SELECT g + 1 FROM series_120 WHERE g < 120
)
INSERT INTO TB_INSTRUTOR (NM_INSTRUTOR, DS_EMAIL, CD_CPF, DS_FORMACAO, DS_AREA_ATUACAO)
SELECT
    'Instrutor ' || g,
    'i' || g || '@mail.com',
    LPAD(CAST((20000000000 + g) AS VARCHAR), 11, '0'),
    CASE (g % 3)
        WHEN 0 THEN 'Mestrado'
        WHEN 1 THEN 'Doutorado'
        WHEN 2 THEN 'Especialização'
    END,
    CASE (g % 4)
        WHEN 0 THEN 'Computação'
        WHEN 1 THEN 'Gestão'
        WHEN 2 THEN 'Educação'
        WHEN 3 THEN 'Engenharia'
    END
FROM series_120;

-- PARCEIROS
WITH RECURSIVE series_50(g) AS (
    SELECT 1
    UNION ALL
    SELECT g + 1 FROM series_50 WHERE g < 50
)
INSERT INTO TB_PARCEIRO (NM_PARCEIRO, CD_CNPJ, DS_CONTATO, DS_EMAIL)
SELECT
    'Parceiro ' || g,
    LPAD(CAST((30000000000000 + g) AS VARCHAR), 14, '0'),
    'Contato ' || g,
    'parceiro' || g || '@mail.com'
FROM series_50;

-- RL ATIVIDADE x INSTRUTOR (garante não duplicar pares)
-- 1) Titular (sempre)
WITH RECURSIVE series_400_a(a_id) AS (
    SELECT 1
    UNION ALL
    SELECT a_id + 1 FROM series_400_a WHERE a_id < 400
)
INSERT INTO RL_ATIVIDADE_INSTRUTOR (ID_ATIVIDADE, ID_INSTRUTOR, DS_PAPEL)
SELECT a_id, ((a_id - 1) % 120) + 1, 'titular'
FROM series_400_a;

-- 2) Apoio #1 (metade das atividades), evitando colisão com a PK
WITH RECURSIVE series_200(a_id) AS (
    SELECT 1
    UNION ALL
    SELECT a_id + 1 FROM series_200 WHERE a_id < 200
)
INSERT INTO RL_ATIVIDADE_INSTRUTOR (ID_ATIVIDADE, ID_INSTRUTOR, DS_PAPEL)
SELECT a_id,
       ((a_id * 7 - 1) % 120) + 1,
       'apoio'
FROM series_200
WHERE NOT EXISTS (
    SELECT 1
    FROM RL_ATIVIDADE_INSTRUTOR r
    WHERE r.ID_ATIVIDADE = a_id
      AND r.ID_INSTRUTOR = ((a_id * 7 - 1) % 120) + 1
);

-- 3) Apoio #2 (um quarto das atividades), evitando colisão
WITH RECURSIVE series_100(a_id) AS (
    SELECT 1
    UNION ALL
    SELECT a_id + 1 FROM series_100 WHERE a_id < 100
)
INSERT INTO RL_ATIVIDADE_INSTRUTOR (ID_ATIVIDADE, ID_INSTRUTOR, DS_PAPEL)
SELECT a_id,
       ((a_id * 11 - 1) % 120) + 1,
       'apoio'
FROM series_100
WHERE NOT EXISTS (
    SELECT 1
    FROM RL_ATIVIDADE_INSTRUTOR r
    WHERE r.ID_ATIVIDADE = a_id
      AND r.ID_INSTRUTOR = ((a_id * 11 - 1) % 120) + 1
);

-- RL EVENTO x PARCEIRO
WITH RECURSIVE series_20_e(e_id) AS (
    SELECT 1
    UNION ALL
    SELECT e_id + 1 FROM series_20_e WHERE e_id < 20
)
INSERT INTO RL_EVENTO_PARCEIRO (ID_EVENTO, ID_PARCEIRO, DS_PAPEL)
SELECT e_id, ((e_id - 1) % 50) + 1, 'patrocinador'
FROM series_20_e;

WITH RECURSIVE series_20_e(e_id) AS (
    SELECT 1
    UNION ALL
    SELECT e_id + 1 FROM series_20_e WHERE e_id < 20
)
INSERT INTO RL_EVENTO_PARCEIRO (ID_EVENTO, ID_PARCEIRO, DS_PAPEL)
SELECT e_id, ((e_id * 3 - 1) % 50) + 1, 'apoio'
FROM series_20_e;

WITH RECURSIVE series_10(e_id) AS (
    SELECT 1
    UNION ALL
    SELECT e_id + 1 FROM series_10 WHERE e_id < 10
)
INSERT INTO RL_EVENTO_PARCEIRO (ID_EVENTO, ID_PARCEIRO, DS_PAPEL)
SELECT e_id, ((e_id * 5 - 1) % 50) + 1, 'apoio'
FROM series_10;

WITH RECURSIVE series_5(e_id) AS (
    SELECT 1
    UNION ALL
    SELECT e_id + 1 FROM series_5 WHERE e_id < 5
)
INSERT INTO RL_EVENTO_PARCEIRO (ID_EVENTO, ID_PARCEIRO, DS_PAPEL)
SELECT e_id, ((e_id * 7 - 1) % 50) + 1, 'apoiador'
FROM series_5;

-- INSCRIÇÕES (12.000 pares únicos)
WITH RECURSIVE series_6000_g(g) AS (
    SELECT 1
    UNION ALL
    SELECT g + 1 FROM series_6000_g WHERE g < 6000
)

-- Insere inscrições de forma variada
INSERT INTO TB_INSCRICAO (ID_PARTICIPANTE, ID_ATIVIDADE, DT_INSCRICAO, ST_CONFIRMADA)
SELECT 
    id_participante, 
    id_atividade, 
    dt_inscricao,
    CASE 
        WHEN fila <= qt_vagas_limite THEN TRUE 
        ELSE FALSE 
    END AS st_confirmada
FROM (
    SELECT 
        p.ID_PARTICIPANTE, 
        a.ID_ATIVIDADE,
        a.QT_VAGAS AS qt_vagas_limite,
        -- Cálculo robusto de data 
        a.DT_ATIVIDADE - (random() * 20 * INTERVAL '1 day') AS dt_inscricao,
        -- Função de Janela (Window Function) - SQL Avançado
        ROW_NUMBER() OVER (PARTITION BY a.ID_ATIVIDADE ORDER BY random()) AS fila
    FROM TB_PARTICIPANTE p
    CROSS JOIN TB_ATIVIDADE a
    WHERE random() < 0.08 -- Sorteia cerca de 8% da combinação total
) AS sub; -- O "AS sub" é obrigatório pelo padrão ANSI


-- Insere feedbacks de forma variada
INSERT INTO TB_FEEDBACK (ID_PARTICIPANTE, ID_ATIVIDADE, VL_NOTA_CONTEUDO, VL_NOTA_INSTRUTOR, VL_NOTA_ORGANIZACAO, DT_AVALIACAO)
SELECT 
    ID_PARTICIPANTE, 
    ID_ATIVIDADE,
    (FLOOR(RANDOM() * 3 + 3)), -- Notas entre 3 e 5
    (FLOOR(RANDOM() * 5 + 1)), -- Notas entre 1 e 5 (variabilidade para o Instrutor)
    (FLOOR(RANDOM() * 2 + 4)), -- Notas entre 4 e 5 (Organização geralmente é estável)
    CURRENT_DATE
FROM TB_INSCRICAO
WHERE ST_CONFIRMADA = TRUE 
  AND RANDOM() < 0.6; -- Apenas 60% dos confirmados deixam feedback, e de forma aleatória


-- Gera certificados baseados na realidade dos feedbacks
INSERT INTO TB_CERTIFICADO (
    ID_PARTICIPANTE, 
    ID_ATIVIDADE, 
    DT_EMISSAO, 
    CD_VALIDACAO
)
SELECT 
    i.ID_PARTICIPANTE,
    i.ID_ATIVIDADE,
    a.DT_ATIVIDADE,
    UPPER(LEFT(MD5(i.ID_PARTICIPANTE::TEXT || i.ID_ATIVIDADE::TEXT || RANDOM()::TEXT), 40))
FROM TB_INSCRICAO i
JOIN TB_ATIVIDADE a ON i.ID_ATIVIDADE = a.ID_ATIVIDADE
WHERE i.ST_CONFIRMADA = TRUE
  AND RANDOM() < 0.85; -- 85% dos que confirmaram presença geram certificado (Gera variabilidade)

-- =============================================================
-- VERIFICAÇÕES DE INTEGRIDADE REFERENCIAL
-- =============================================================

-- Verificar se há certificados sem inscrição correspondente
-- Esta consulta deve retornar 0 linhas
SELECT 'ALERTA: Certificados sem inscrição' AS verificacao,
       COUNT(*) AS quantidade
FROM TB_CERTIFICADO c
WHERE NOT EXISTS (
    SELECT 1 FROM TB_INSCRICAO i
    WHERE i.ID_PARTICIPANTE = c.ID_PARTICIPANTE
      AND i.ID_ATIVIDADE = c.ID_ATIVIDADE
) FETCH FIRST 1 ROWS ONLY;

-- Verificar se há feedbacks sem inscrição correspondente  
-- Esta consulta deve retornar 0 linhas
SELECT 'ALERTA: Feedbacks sem inscrição' AS verificacao,
       COUNT(*) AS quantidade
FROM TB_FEEDBACK f
WHERE NOT EXISTS (
    SELECT 1 FROM TB_INSCRICAO i
    WHERE i.ID_PARTICIPANTE = f.ID_PARTICIPANTE
      AND i.ID_ATIVIDADE = f.ID_ATIVIDADE
) FETCH FIRST 1 ROWS ONLY;

-- Verificar se há inscrições confirmadas duplicadas
SELECT 'ALERTA: Inscrições confirmadas duplicadas' AS verificacao,
       COUNT(*) AS quantidade
FROM (
    SELECT ID_PARTICIPANTE, ID_ATIVIDADE, COUNT(*) AS cnt
    FROM TB_INSCRICAO
    WHERE ST_CONFIRMADA = TRUE
    GROUP BY ID_PARTICIPANTE, ID_ATIVIDADE
    HAVING COUNT(*) > 1
) AS duplicados FETCH FIRST 1 ROWS ONLY;

-- =============================================================
-- BLOCO DE CENÁRIOS CONTROLADOS (IDs SEGUROS 9000+)
-- =============================================================

-- 1. ATIVIDADE NO PASSADO (Tela 1 - Erro de Data)
INSERT INTO TB_ATIVIDADE (ID_ATIVIDADE, ID_EVENTO, DS_TITULO, DT_ATIVIDADE, HR_INICIO, HR_FIM, TP_MODALIDADE, QT_VAGAS, QT_CARGA_HORARIA, ST_ATIVA)
OVERRIDING SYSTEM VALUE 
VALUES (9001, 1, 'Workshop de Legado', '2025-01-01', '09:00', '12:00', 'Presencial', 10, 3.0, TRUE);

-- 2. ATIVIDADE SEM VAGAS (Tela 1 - Erro de Vagas)
INSERT INTO TB_ATIVIDADE (ID_ATIVIDADE, ID_EVENTO, DS_TITULO, DT_ATIVIDADE, HR_INICIO, HR_FIM, TP_MODALIDADE, QT_VAGAS, QT_CARGA_HORARIA, ST_ATIVA)
OVERRIDING SYSTEM VALUE
VALUES (9002, 1, 'Palestra Lotada', '2026-01-15', '14:00', '16:00', 'Online', 0, 2.0, TRUE);

-- 3. ATIVIDADE FUTURA COM VAGAS (Sucesso na Tela 1 e 2)
INSERT INTO TB_ATIVIDADE (ID_ATIVIDADE, ID_EVENTO, DS_TITULO, DT_ATIVIDADE, HR_INICIO, HR_FIM, TP_MODALIDADE, QT_VAGAS, QT_CARGA_HORARIA, ST_ATIVA)
OVERRIDING SYSTEM VALUE
VALUES (9003, 1, 'Inovação 2026', '2026-02-01', '10:00', '12:00', 'Presencial', 50, 2.0, TRUE);

-- 4. PARTICIPANTE DE TESTE
INSERT INTO TB_PARTICIPANTE (ID_PARTICIPANTE, NM_PARTICIPANTE, DS_EMAIL, DT_NASCIMENTO)
OVERRIDING SYSTEM VALUE
VALUES (9999, 'Aluno Teste Lab', 'teste@lab.com', '2000-01-01');

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

-- =============================================================
-- FIM DO populate_prj1.sql
-- =============================================================
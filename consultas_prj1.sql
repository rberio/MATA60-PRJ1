-- =============================================================
-- PRJ1 - MATA60 (Marco 1)
-- CONSULTAS (10 Intermediárias + 20 Avançadas) - SQL puro
-- PostgreSQL 12+
-- =============================================================


/* REQ-01
   Título: Atividades por evento (mar/2025) com inscritos
   Justificativa: Demanda por período (JOIN + GROUP BY + COUNT) */
SELECT
  e.id_evento, e.ds_titulo AS titulo_evento,
  a.id_atividade, a.ds_titulo AS titulo_atividade, a.dt_atividade,
  COUNT(i.id_inscricao) AS total_inscritos
FROM tb_evento e
JOIN tb_atividade a  ON a.id_evento = e.id_evento
LEFT JOIN tb_inscricao i ON i.id_atividade = a.id_atividade
WHERE a.dt_atividade BETWEEN DATE '2025-03-01' AND DATE '2025-03-31'
GROUP BY e.id_evento, e.ds_titulo, a.id_atividade, a.ds_titulo, a.dt_atividade
ORDER BY e.id_evento, a.dt_atividade, a.id_atividade;


/* REQ-02
   Título: Taxa de confirmação por atividade
   Justificativa: Indicador operacional (JOIN + GROUP BY + COUNT) */
SELECT
  e.id_evento, a.id_atividade, a.ds_titulo,
  COUNT(*) AS total_inscricoes,
  SUM(CASE WHEN i.st_confirmada THEN 1 ELSE 0 END) AS confirmadas,
  ROUND(100.0 * SUM(CASE WHEN i.st_confirmada THEN 1 ELSE 0 END)::numeric
              / NULLIF(COUNT(*),0), 2) AS taxa_confirmacao_pct
FROM tb_evento e
JOIN tb_atividade a ON a.id_evento = e.id_evento
JOIN tb_inscricao i ON i.id_atividade = a.id_atividade
GROUP BY e.id_evento, a.id_atividade, a.ds_titulo
ORDER BY taxa_confirmacao_pct DESC, total_inscricoes DESC
LIMIT 50;


/* REQ-03
   Título: Ranking de atividades por inscritos (por evento)
   Justificativa: Priorização (JOIN + GROUP BY + WINDOW) */
WITH inscritos AS (
  SELECT a.id_evento, a.id_atividade, COUNT(i.id_inscricao) AS qtd
  FROM tb_atividade a
  LEFT JOIN tb_inscricao i ON i.id_atividade = a.id_atividade
  GROUP BY a.id_evento, a.id_atividade
)
SELECT
  e.id_evento, e.ds_titulo AS evento,
  a.id_atividade, a.ds_titulo AS atividade,
  s.qtd,
  RANK() OVER (PARTITION BY e.id_evento ORDER BY s.qtd DESC) AS posicao_no_evento
FROM inscritos s
JOIN tb_atividade a ON a.id_atividade = s.id_atividade
JOIN tb_evento e    ON e.id_evento = a.id_evento
ORDER BY e.id_evento, posicao_no_evento;


/* REQ-04
   Título: Médias de notas por atividade e por evento
   Justificativa: Qualidade percebida (JOIN + GROUP BY + AVG) */
SELECT
  e.id_evento, e.ds_titulo AS evento,
  a.id_atividade, a.ds_titulo AS atividade,
  ROUND(AVG(f.vl_nota_conteudo)::numeric, 2)    AS media_conteudo,
  ROUND(AVG(f.vl_nota_instrutor)::numeric, 2)   AS media_instrutor,
  ROUND(AVG(f.vl_nota_organizacao)::numeric, 2) AS media_organizacao,
  COUNT(f.id_feedback) AS qtd_feedbacks
FROM tb_evento e
JOIN tb_atividade a ON a.id_evento = e.id_evento
LEFT JOIN tb_feedback f ON f.id_atividade = a.id_atividade
GROUP BY e.id_evento, e.ds_titulo, a.id_atividade, a.ds_titulo
ORDER BY e.id_evento, a.id_atividade;


/* REQ-05
   Título: Participantes com certificados por atividade/evento
   Justificativa: Valida conclusão (JOIN + GROUP BY + COUNT) */
SELECT
  p.id_participante, p.nm_participante,
  e.id_evento, a.id_atividade, a.ds_titulo AS atividade,
  COUNT(c.id_certificado) AS certificados
FROM tb_participante p
JOIN tb_certificado c ON c.id_participante = p.id_participante
JOIN tb_atividade   a ON a.id_atividade = c.id_atividade
JOIN tb_evento      e ON e.id_evento    = a.id_evento
GROUP BY p.id_participante, p.nm_participante, e.id_evento, a.id_atividade, a.ds_titulo
ORDER BY certificados DESC, p.id_participante
LIMIT 100;


/* REQ-06
   Título: Distribuição de modalidades por evento
   Justificativa: Diversidade de oferta (JOIN + GROUP BY + COUNT) */
SELECT
  e.id_evento, e.ds_titulo AS evento,
  a.tp_modalidade,
  COUNT(*) AS qtd_atividades
FROM tb_evento e
JOIN tb_atividade a ON a.id_evento = e.id_evento
JOIN tb_inscricao i ON i.id_atividade = a.id_atividade
GROUP BY e.id_evento, e.ds_titulo, a.tp_modalidade
ORDER BY e.id_evento, qtd_atividades DESC;


/* REQ-07
   Título: Instrutores por atividade e evento
   Justificativa: Dimensionamento de equipe (JOIN + GROUP BY + COUNT) */
SELECT
  e.id_evento, e.ds_titulo AS evento,
  a.id_atividade, a.ds_titulo AS atividade,
  COUNT(DISTINCT r.id_instrutor) AS qtd_instrutores
FROM tb_evento e
JOIN tb_atividade a ON a.id_evento = e.id_evento
JOIN rl_atividade_instrutor r ON r.id_atividade = a.id_atividade
JOIN tb_instrutor t ON t.id_instrutor = r.id_instrutor
GROUP BY e.id_evento, e.ds_titulo, a.id_atividade, a.ds_titulo
ORDER BY e.id_evento, a.id_atividade;


/* REQ-08
   Título: Parceiros por evento e papel
   Justificativa: Governança/captação (JOIN + GROUP BY + COUNT) */
SELECT
  e.id_evento, e.ds_titulo AS evento,
  r.ds_papel,
  COUNT(*) AS qtd_parceiros
FROM tb_evento e
JOIN rl_evento_parceiro r ON r.id_evento = e.id_evento
JOIN tb_parceiro p        ON p.id_parceiro = r.id_parceiro
GROUP BY e.id_evento, e.ds_titulo, r.ds_papel
ORDER BY e.id_evento, qtd_parceiros DESC;


/* REQ-09
   Título: Lotação (inscritos vs vagas) por atividade
   Justificativa: Gestão de capacidade (JOIN + GROUP BY + COUNT) */
SELECT
  e.id_evento, a.id_atividade, a.ds_titulo,
  a.qt_vagas,
  COUNT(i.id_inscricao) AS inscritos,
  ROUND(100.0 * COUNT(i.id_inscricao)::numeric / NULLIF(a.qt_vagas,0), 2) AS ocupacao_pct
FROM tb_evento e
JOIN tb_atividade a ON a.id_evento = e.id_evento
LEFT JOIN tb_inscricao i ON i.id_atividade = a.id_atividade
GROUP BY e.id_evento, a.id_atividade, a.ds_titulo, a.qt_vagas
ORDER BY ocupacao_pct DESC NULLS LAST
LIMIT 100;


/* REQ-10
   Título: Top participantes por engajamento (confirmações)
   Justificativa: Reconhecer engajamento (JOIN + WINDOW + COUNT) */
WITH conf AS (
  SELECT id_participante, COUNT(*) AS qtd_conf
  FROM tb_inscricao
  WHERE st_confirmada = TRUE
  GROUP BY id_participante
)
SELECT
  p.id_participante, p.nm_participante, c.qtd_conf,
  ROW_NUMBER() OVER (ORDER BY c.qtd_conf DESC, p.id_participante) AS pos
FROM conf c
JOIN tb_participante p ON p.id_participante = c.id_participante
JOIN tb_inscricao i ON i.id_participante = p.id_participante
ORDER BY pos
LIMIT 50;


/* REQ-11
   Título: Acima/abaixo da média de inscritos (por evento)
   Justificativa: Comparação intra-evento (SUBQUERY + JOIN + WINDOW) */
WITH inscritos AS (
  SELECT a.id_evento, a.id_atividade, COUNT(i.id_inscricao) AS qtd
  FROM tb_atividade a
  LEFT JOIN tb_inscricao i ON i.id_atividade = a.id_atividade
  GROUP BY a.id_evento, a.id_atividade
),
media_evento AS (
  SELECT id_evento, AVG(qtd) AS media_evt
  FROM inscritos
  GROUP BY id_evento
)
SELECT
  e.id_evento, e.ds_titulo AS evento,
  a.id_atividade, a.ds_titulo AS atividade,
  s.qtd, m.media_evt,
  CASE WHEN s.qtd >= m.media_evt THEN 'ACIMA' ELSE 'ABAIXO' END AS pos_rel_evento,
  RANK() OVER (PARTITION BY e.id_evento ORDER BY s.qtd DESC) AS ranking_evt
FROM inscritos s
JOIN tb_atividade a ON a.id_atividade = s.id_atividade
JOIN tb_evento e    ON e.id_evento = a.id_evento
JOIN media_evento m ON m.id_evento = e.id_evento
ORDER BY e.id_evento, ranking_evt;


/* REQ-12
   Título: Instrutores top por média de avaliação
   Justificativa: Mérito/qualidade (SUBQUERY + JOIN + GROUP BY) */
SELECT
  t.id_instrutor, t.nm_instrutor,
  ROUND(AVG(sub.media_atividade)::numeric, 2) AS media_instrutor
FROM tb_instrutor t
JOIN rl_atividade_instrutor r ON r.id_instrutor = t.id_instrutor
JOIN (
  SELECT
    a.id_atividade,
    AVG((f.vl_nota_conteudo + f.vl_nota_instrutor + f.vl_nota_organizacao)/3.0) AS media_atividade
  FROM tb_atividade a
  JOIN tb_feedback f ON f.id_atividade = a.id_atividade
  GROUP BY a.id_atividade
) sub ON sub.id_atividade = r.id_atividade
GROUP BY t.id_instrutor, t.nm_instrutor
HAVING COUNT(*) >= 2
ORDER BY media_instrutor DESC, t.id_instrutor
LIMIT 50;


/* REQ-13
   Título: Elegíveis a certificado (confirmados + feedback)
   Justificativa: Elegibilidade de emissão (EXISTS + JOIN) */
SELECT
  p.id_participante, p.nm_participante,
  COUNT(*) AS atividades_elegiveis
FROM tb_participante p
JOIN tb_inscricao i ON i.id_participante = p.id_participante AND i.st_confirmada = TRUE
WHERE EXISTS (
  SELECT 1
  FROM tb_feedback f
  WHERE f.id_participante = p.id_participante
    AND f.id_atividade   = i.id_atividade
)
GROUP BY p.id_participante, p.nm_participante
ORDER BY atividades_elegiveis DESC, p.id_participante
LIMIT 100;


/* REQ-14
   Título: Análise diária — atividades e média móvel de notas
   Justificativa: Tendência temporal (JOIN + GROUP BY + WINDOW) */
WITH notas_dia AS (
  SELECT
    e.id_evento,
    a.dt_atividade AS dia,
    AVG((f.vl_nota_conteudo + f.vl_nota_instrutor + f.vl_nota_organizacao)/3.0) AS media_notas
  FROM tb_evento e
  JOIN tb_atividade a ON a.id_evento = e.id_evento
  JOIN tb_feedback f  ON f.id_atividade = a.id_atividade
  GROUP BY e.id_evento, a.dt_atividade
)
SELECT
  e.id_evento, e.ds_titulo AS evento,
  a.dt_atividade AS dia,
  COUNT(DISTINCT a.id_atividade) AS atividades_no_dia,
  ROUND(AVG(n.media_notas) OVER (PARTITION BY e.id_evento
                                 ORDER BY a.dt_atividade
                                 ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)::numeric, 2) AS media_movel_notas
FROM tb_evento e
JOIN tb_atividade a ON a.id_evento = e.id_evento
LEFT JOIN notas_dia n ON n.id_evento = e.id_evento AND n.dia = a.dt_atividade
GROUP BY e.id_evento, e.ds_titulo, a.dt_atividade, n.media_notas
ORDER BY e.id_evento, dia;


/* REQ-15
   Título: Nº de instrutores × média de notas (comparativo)
   Justificativa: Impacto de equipe (SUBQUERY + JOIN + GROUP BY) */
WITH qtd_instr AS (
  SELECT a.id_atividade, COUNT(*) AS instrutores
  FROM rl_atividade_instrutor r
  JOIN tb_atividade a ON a.id_atividade = r.id_atividade
  GROUP BY a.id_atividade
),
nota_ativ AS (
  SELECT a.id_atividade,
         AVG((f.vl_nota_conteudo + f.vl_nota_instrutor + f.vl_nota_organizacao)/3.0) AS media
  FROM tb_atividade a
  JOIN tb_feedback f ON f.id_atividade = a.id_atividade
  GROUP BY a.id_atividade
)
SELECT
  qi.instrutores,
  ROUND(AVG(na.media)::numeric, 2) AS media_notas_grupo,
  COUNT(*) AS qtd_atividades
FROM qtd_instr qi
JOIN nota_ativ na ON na.id_atividade = qi.id_atividade
GROUP BY qi.instrutores
ORDER BY qi.instrutores;


/* REQ-16
   Título: Diversidade de modalidades por evento
   Justificativa: Amplitude programática (JOIN + COUNT DISTINCT) */
SELECT
  e.id_evento, e.ds_titulo AS evento,
  COUNT(DISTINCT a.tp_modalidade) AS modalidades_distintas,
  COUNT(*) AS total_atividades
FROM tb_evento e
JOIN tb_atividade a ON a.id_evento = e.id_evento
JOIN tb_inscricao i ON i.id_atividade = a.id_atividade
GROUP BY e.id_evento, e.ds_titulo
ORDER BY modalidades_distintas DESC, total_atividades DESC;


/* REQ-17
   Título: Outliers (z-score) de inscritos por atividade
   Justificativa: Detecção de extremos (SUBQUERY + JOIN + WINDOW) */
WITH inscritos AS (
  SELECT a.id_evento, a.id_atividade, COUNT(i.id_inscricao) AS qtd
  FROM tb_atividade a
  LEFT JOIN tb_inscricao i ON i.id_atividade = a.id_atividade
  GROUP BY a.id_evento, a.id_atividade
),
estat AS (
  SELECT id_evento,
         AVG(qtd) AS media,
         STDDEV_SAMP(qtd) AS desvio
  FROM inscritos
  GROUP BY id_evento
)
SELECT
  e.id_evento, e.ds_titulo AS evento,
  a.id_atividade, a.ds_titulo AS atividade,
  s.qtd,
  es.media, es.desvio,
  CASE WHEN es.desvio > 0 THEN (s.qtd - es.media)/es.desvio ELSE 0 END AS z_score
FROM inscritos s
JOIN tb_atividade a ON a.id_atividade = s.id_atividade
JOIN tb_evento e    ON e.id_evento    = a.id_evento
JOIN estat es       ON es.id_evento   = e.id_evento
ORDER BY e.id_evento, z_score DESC NULLS LAST
LIMIT 200;


/* REQ-18
   Título: Parceiros “centrais” (≥2 eventos e papéis distintos)
   Justificativa: Centralidade de rede (JOIN + GROUP BY + HAVING) */
SELECT
  p.id_parceiro, p.nm_parceiro,
  COUNT(DISTINCT r.id_evento) AS eventos,
  COUNT(DISTINCT r.ds_papel)  AS papeis
FROM tb_parceiro p
JOIN rl_evento_parceiro r ON r.id_parceiro = p.id_parceiro
JOIN tb_evento e ON e.id_evento = r.id_evento
GROUP BY p.id_parceiro, p.nm_parceiro
HAVING COUNT(DISTINCT r.id_evento) >= 2
   AND COUNT(DISTINCT r.ds_papel)  >= 2
ORDER BY eventos DESC, papeis DESC, p.id_parceiro;


/* REQ-19
   Título: Inconsistência — certificado sem feedback
   Justificativa: Qualidade/validação (LEFT JOIN ... IS NULL) */
SELECT
  c.id_certificado, c.id_participante, p.nm_participante,
  c.id_atividade, a.ds_titulo AS atividade, c.cd_validacao
FROM tb_certificado c
JOIN tb_participante p ON p.id_participante = c.id_participante
JOIN tb_atividade   a ON a.id_atividade    = c.id_atividade
LEFT JOIN tb_feedback f
       ON f.id_participante = c.id_participante
      AND f.id_atividade    = c.id_atividade
WHERE f.id_feedback IS NULL
ORDER BY c.id_certificado
LIMIT 200;


/* REQ-20
   Título: Top 10 por nota composta (nota × ln(1+confirmados))
   Justificativa: Priorização (SUBQUERY + JOIN + WINDOW) */
WITH notas AS (
  SELECT a.id_atividade,
         AVG((f.vl_nota_conteudo + f.vl_nota_instrutor + f.vl_nota_organizacao)/3.0) AS media_nota
  FROM tb_atividade a
  JOIN tb_feedback f ON f.id_atividade = a.id_atividade
  GROUP BY a.id_atividade
),
conf AS (
  SELECT a.id_atividade, COUNT(*) AS confirmados
  FROM tb_atividade a
  JOIN tb_inscricao i ON i.id_atividade = a.id_atividade AND i.st_confirmada = TRUE
  GROUP BY a.id_atividade
),
score AS (
  SELECT
    a.id_atividade,
    COALESCE(n.media_nota, 0) AS media_nota,
    COALESCE(c.confirmados, 0) AS confirmados,
    COALESCE(n.media_nota,0) * LN(1 + COALESCE(c.confirmados,0)) AS nota_composta
  FROM tb_atividade a
  LEFT JOIN notas n ON n.id_atividade = a.id_atividade
  LEFT JOIN conf  c ON c.id_atividade = a.id_atividade
)
SELECT
  e.id_evento, e.ds_titulo AS evento,
  a.id_atividade, a.ds_titulo AS atividade,
  ROUND(s.media_nota::numeric,2) AS media_nota,
  s.confirmados,
  ROUND(s.nota_composta::numeric,3) AS nota_composta,
  RANK() OVER (ORDER BY s.nota_composta DESC) AS pos_global
FROM score s
JOIN tb_atividade a ON a.id_atividade = s.id_atividade
JOIN tb_evento e    ON e.id_evento    = a.id_evento
ORDER BY pos_global
LIMIT 10;


/* REQ-21
   Título: Taxa de feedback por atividade
   Justificativa: Adesão pós-evento (SUBQUERY + JOIN + GROUP BY) */
WITH conf AS (
  SELECT id_atividade, COUNT(*) AS confs
  FROM tb_inscricao
  WHERE st_confirmada = TRUE
  GROUP BY id_atividade
),
fb AS (
  SELECT id_atividade, COUNT(*) AS fbs
  FROM tb_feedback
  GROUP BY id_atividade
)
SELECT
  e.id_evento, a.id_atividade, a.ds_titulo,
  c.confs, COALESCE(f.fbs,0) AS feedbacks,
  ROUND(100.0 * COALESCE(f.fbs,0)::numeric / NULLIF(c.confs,0), 2) AS taxa_fb_pct
FROM tb_atividade a
JOIN tb_evento e ON e.id_evento = a.id_evento
JOIN conf c ON c.id_atividade = a.id_atividade
LEFT JOIN fb f ON f.id_atividade = a.id_atividade
ORDER BY taxa_fb_pct DESC NULLS LAST, c.confs DESC;


/* REQ-22
   Título: Certificados por evento (total e carga média)
   Justificativa: Resultado educacional (JOIN + GROUP BY + AVG) */
SELECT
  e.id_evento, e.ds_titulo AS evento,
  COUNT(c.id_certificado) AS total_certificados,
  ROUND(AVG(c.nr_carga_horaria)::numeric,2) AS carga_media
FROM tb_evento e
JOIN tb_atividade a ON a.id_evento = e.id_evento
JOIN tb_certificado c ON c.id_atividade = a.id_atividade
GROUP BY e.id_evento, e.ds_titulo
ORDER BY total_certificados DESC, e.id_evento;


/* REQ-23
   Título: Atividades superlotadas (>100% das vagas)
   Justificativa: Alerta de capacidade (JOIN + GROUP BY + HAVING) */
SELECT
  e.id_evento, a.id_atividade, a.ds_titulo,
  a.qt_vagas, COUNT(i.id_inscricao) AS inscritos
FROM tb_evento e
JOIN tb_atividade a ON a.id_evento = e.id_evento
LEFT JOIN tb_inscricao i ON i.id_atividade = a.id_atividade
GROUP BY e.id_evento, a.id_atividade, a.ds_titulo, a.qt_vagas
HAVING COUNT(i.id_inscricao) > a.qt_vagas
ORDER BY (COUNT(i.id_inscricao) - a.qt_vagas) DESC;


/* REQ-24
   Título: Idade média dos participantes por evento
   Justificativa: Perfil de público (JOIN + GROUP BY + AVG) */
SELECT
  e.id_evento, e.ds_titulo AS evento,
  ROUND(AVG(EXTRACT(YEAR FROM AGE(CURRENT_DATE, p.dt_nascimento)))::numeric,1) AS idade_media
FROM tb_evento e
JOIN tb_atividade a ON a.id_evento = e.id_evento
JOIN tb_inscricao i ON i.id_atividade = a.id_atividade
JOIN tb_participante p ON p.id_participante = i.id_participante
GROUP BY e.id_evento, e.ds_titulo
ORDER BY idade_media DESC NULLS LAST;


/* REQ-25
   Título: Participantes com maior diversidade de modalidades
   Justificativa: Amplitude de interesse (JOIN + COUNT DISTINCT) */
SELECT
  p.id_participante, p.nm_participante,
  COUNT(DISTINCT a.tp_modalidade) AS modalidades_distintas,
  COUNT(*) AS total_inscricoes
FROM tb_participante p
JOIN tb_inscricao i ON i.id_participante = p.id_participante
JOIN tb_atividade a ON a.id_atividade = i.id_atividade
GROUP BY p.id_participante, p.nm_participante
ORDER BY modalidades_distintas DESC, total_inscricoes DESC
LIMIT 100;


/* REQ-26
   Título: Conversão inscrição→certificado (por atividade)
   Justificativa: Eficiência pedagógica (SUBQUERY + JOIN + GROUP BY) */
WITH conf AS (
  SELECT id_atividade, COUNT(*) AS confs
  FROM tb_inscricao
  WHERE st_confirmada = TRUE
  GROUP BY id_atividade
),
cert AS (
  SELECT id_atividade, COUNT(*) AS certs
  FROM tb_certificado
  GROUP BY id_atividade
)
SELECT
  e.id_evento, a.id_atividade, a.ds_titulo,
  c.confs, COALESCE(t.certs,0) AS certs,
  ROUND(100.0 * COALESCE(t.certs,0)::numeric / NULLIF(c.confs,0), 2) AS conversao_pct
FROM tb_atividade a
JOIN tb_evento e ON e.id_evento = a.id_evento
JOIN conf c ON c.id_atividade = a.id_atividade
LEFT JOIN cert t ON t.id_atividade = a.id_atividade
ORDER BY conversao_pct DESC NULLS LAST, c.confs DESC;


/* REQ-27
   Título: Retenção — em quantos eventos cada participante esteve
   Justificativa: Fidelização (JOIN + COUNT DISTINCT) */
SELECT
  p.id_participante, p.nm_participante,
  COUNT(DISTINCT e.id_evento) AS eventos_distintos
FROM tb_participante p
JOIN tb_inscricao i ON i.id_participante = p.id_participante
JOIN tb_atividade a ON a.id_atividade = i.id_atividade
JOIN tb_evento e ON e.id_evento = a.id_evento
GROUP BY p.id_participante, p.nm_participante
ORDER BY eventos_distintos DESC, p.id_participante
LIMIT 100;


/* REQ-28
   Título: Sazonalidade — atividades por semana do ano
   Justificativa: Planejamento temporal (JOIN + GROUP BY) */
SELECT
  e.id_evento, e.ds_titulo AS evento,
  EXTRACT(WEEK FROM a.dt_atividade)::int AS semana,
  COUNT(*) AS atividades_semana
FROM tb_evento e
JOIN tb_atividade a ON a.id_evento = e.id_evento
GROUP BY e.id_evento, e.ds_titulo, EXTRACT(WEEK FROM a.dt_atividade)
ORDER BY e.id_evento, semana;


/* REQ-29
   Título: Certificados por faixa de carga horária
   Justificativa: Análise de produto/curso (JOIN + GROUP BY + CASE) */
SELECT
  e.id_evento, e.ds_titulo AS evento,
  CASE
    WHEN c.nr_carga_horaria < 5   THEN '<5h'
    WHEN c.nr_carga_horaria < 8   THEN '5–7.5h'
    ELSE '>=8h'
  END AS faixa_ch,
  COUNT(*) AS qtd
FROM tb_evento e
JOIN tb_atividade a ON a.id_evento = e.id_evento
JOIN tb_certificado c ON c.id_atividade = a.id_atividade
GROUP BY e.id_evento, e.ds_titulo, faixa_ch
ORDER BY e.id_evento, faixa_ch;


/* REQ-30
   Título: Trilha de excelência (nota ≥4 e alto nº de confirmadas)
   Justificativa: Curadoria (SUBQUERY + JOIN + HAVING/ORDER) */
WITH media AS (
  SELECT a.id_atividade,
         AVG((f.vl_nota_conteudo + f.vl_nota_instrutor + f.vl_nota_organizacao)/3.0) AS media
  FROM tb_atividade a
  JOIN tb_feedback f ON f.id_atividade = a.id_atividade
  GROUP BY a.id_atividade
),
conf AS (
  SELECT id_atividade, COUNT(*) AS confirmadas
  FROM tb_inscricao
  WHERE st_confirmada = TRUE
  GROUP BY id_atividade
)
SELECT
  e.id_evento, e.ds_titulo AS evento,
  a.id_atividade, a.ds_titulo AS atividade,
  ROUND(m.media::numeric,2) AS media_notas,
  c.confirmadas
FROM tb_atividade a
JOIN tb_evento e ON e.id_evento = a.id_evento
JOIN media m ON m.id_atividade = a.id_atividade
JOIN conf  c ON c.id_atividade = a.id_atividade
WHERE m.media >= 4.0
ORDER BY c.confirmadas DESC, m.media DESC
LIMIT 50;

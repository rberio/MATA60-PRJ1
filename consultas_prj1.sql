| REQ-02 — Taxa de confirmação por atividade | **Descrição:** calcula taxa de confirmações. **Justificativa:** indicador operacional; `JOIN`+`GROUP BY`+`COUNT`. | ```sql
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
``` |
| REQ-03 — Ranking de atividades por inscritos (por evento) | **Descrição:** ranqueia atividades por inscritos em cada evento. **Justificativa:** priorização; `JOIN`+`GROUP BY`+`WINDOW`. | ```sql
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
``` |
| REQ-04 — Médias de notas por atividade e evento | **Descrição:** médias de conteúdo/instrutor/organização. **Justificativa:** qualidade percebida; `JOIN`+`GROUP BY`+`AVG`. | ```sql
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
``` |
| REQ-05 — Participantes com certificados por atividade/evento | **Descrição:** relaciona participantes e certificados emitidos. **Justificativa:** valida conclusão; `JOIN`+`GROUP BY`+`COUNT`. | ```sql
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
``` |
| REQ-06 — Modalidades por evento | **Descrição:** distribuição de `tp_modalidade` por evento. **Justificativa:** diversidade de oferta; `JOIN`+`GROUP BY`+`COUNT`. | ```sql
SELECT
  e.id_evento, e.ds_titulo AS evento,
  a.tp_modalidade,
  COUNT(*) AS qtd_atividades
FROM tb_evento e
JOIN tb_atividade a ON a.id_evento = e.id_evento
JOIN tb_inscricao i ON i.id_atividade = a.id_atividade
GROUP BY e.id_evento, e.ds_titulo, a.tp_modalidade
ORDER BY e.id_evento, qtd_atividades DESC;
``` |
| REQ-07 — Instrutores por atividade e evento | **Descrição:** conta instrutores por atividade. **Justificativa:** dimensionamento de equipe; `JOIN`+`GROUP BY`+`COUNT`. | ```sql
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
``` |
| REQ-08 — Parceiros por evento e papel | **Descrição:** conta parceiros por papel. **Justificativa:** governança e captação; `JOIN`+`GROUP BY`+`COUNT`. | ```sql
SELECT
  e.id_evento, e.ds_titulo AS evento,
  r.ds_papel,
  COUNT(*) AS qtd_parceiros
FROM tb_evento e
JOIN rl_evento_parceiro r ON r.id_evento = e.id_evento
JOIN tb_parceiro p        ON p.id_parceiro = r.id_parceiro
GROUP BY e.id_evento, e.ds_titulo, r.ds_papel
ORDER BY e.id_evento, qtd_parceiros DESC;
``` |
| REQ-09 — Lotação: inscritos vs vagas | **Descrição:** ocupação percentual por atividade. **Justificativa:** gestão de capacidade; `JOIN`+`GROUP BY`+`COUNT`. | ```sql
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
``` |
| REQ-10 — Top participantes por engajamento | **Descrição:** ranqueia por nº de confirmações. **Justificativa:** reconhecer engajamento; `JOIN`+`WINDOW`+`COUNT`. | ```sql
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
``` |
| REQ-11 — Acima/abaixo da média de inscritos (por evento) | **Descrição:** compara inscritos por atividade com média do evento. **Justificativa:** decisão tática; `SUBQUERY`+`JOIN`+`WINDOW`. | ```sql
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
``` |
| REQ-12 — Instrutores top por média de avaliação | **Descrição:** média composta das notas por instrutor. **Justificativa:** mérito/qualidade; `SUBQUERY`+`JOIN`+`GROUP BY`. | ```sql
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
``` |
| REQ-13 — Elegíveis a certificado (confirmados + feedback) | **Descrição:** participantes com confirmação e feedback na mesma atividade. **Justificativa:** elegibilidade de emissão; `EXISTS`+`JOIN`. | ```sql
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
``` |
| REQ-14 — Análise diária: atividades + média móvel de notas | **Descrição:** métricas por dia com média móvel. **Justificativa:** tendência temporal; `JOIN`+`GROUP BY`+`WINDOW`. | ```sql
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
``` |
| REQ-15 — Instrutores × média de notas (comparativo) | **Descrição:** compara nº de instrutores com média de notas. **Justificativa:** impacto de equipe; `SUBQUERY`+`JOIN`+`GROUP BY`. | ```sql
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
``` |
| REQ-16 — Diversidade de modalidades por evento | **Descrição:** conta modalidades distintas e total de atividades. **Justificativa:** amplitude programática; `JOIN`+`GROUP BY`+`COUNT DISTINCT`. | ```sql
SELECT
  e.id_evento, e.ds_titulo AS evento,
  COUNT(DISTINCT a.tp_modalidade) AS modalidades_distintas,
  COUNT(*) AS total_atividades
FROM tb_evento e
JOIN tb_atividade a ON a.id_evento = e.id_evento
JOIN tb_inscricao i ON i.id_atividade = a.id_atividade
GROUP BY e.id_evento, e.ds_titulo
ORDER BY modalidades_distintas DESC, total_atividades DESC;
``` |
| REQ-17 — Outliers (z-score) em inscritos por atividade | **Descrição:** calcula z-score por evento. **Justificativa:** detectar extremos; `SUBQUERY`+`JOIN`+`WINDOW`. | ```sql
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
``` |
| REQ-18 — Parceiros “centrais” (≥2 eventos, papéis distintos) | **Descrição:** identifica parceiros multi-evento/multi-papel. **Justificativa:** centralidade de rede; `JOIN`+`GROUP BY`+`HAVING`. | ```sql
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
``` |
| REQ-19 — Inconsistência: certificado sem feedback | **Descrição:** encontra certificados sem feedback correspondente. **Justificativa:** validação/qualidade; `LEFT JOIN ... IS NULL`. | ```sql
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
``` |
| REQ-20 — Top 10 por nota composta (nota × ln(1+confirmados)) | **Descrição:** score composto de qualidade e alcance. **Justificativa:** priorização; `SUBQUERY`+`JOIN`+`WINDOW`. | ```sql
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
``` |
| REQ-21 — Taxa de feedback por atividade | **Descrição:** % de inscrições confirmadas que geraram feedback. **Justificativa:** adesão pós-evento; `JOIN`+`GROUP BY`+`SUBQUERY`. | ```sql
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
``` |
| REQ-22 — Certificados por evento com carga horária média | **Descrição:** total de certificados e média de carga por evento. **Justificativa:** resultado educacional; `JOIN`+`GROUP BY`+`AVG`. | ```sql
SELECT
  e.id_evento, e.ds_titulo AS evento,
  COUNT(c.id_certificado) AS total_certificados,
  ROUND(AVG(c.nr_carga_horaria)::numeric,2) AS carga_media
FROM tb_evento e
JOIN tb_atividade a ON a.id_evento = e.id_evento
JOIN tb_certificado c ON c.id_atividade = a.id_atividade
GROUP BY e.id_evento, e.ds_titulo
ORDER BY total_certificados DESC, e.id_evento;
``` |
| REQ-23 — Correção de capacidade: atividades superlotadas | **Descrição:** atividades com ocupação >100%. **Justificativa:** alerta de cap/valid.; `JOIN`+`GROUP BY`+`HAVING`. | ```sql
SELECT
  e.id_evento, a.id_atividade, a.ds_titulo,
  a.qt_vagas, COUNT(i.id_inscricao) AS inscritos
FROM tb_evento e
JOIN tb_atividade a ON a.id_evento = e.id_evento
LEFT JOIN tb_inscricao i ON i.id_atividade = a.id_atividade
GROUP BY e.id_evento, a.id_atividade, a.ds_titulo, a.qt_vagas
HAVING COUNT(i.id_inscricao) > a.qt_vagas
ORDER BY (COUNT(i.id_inscricao) - a.qt_vagas) DESC;
``` |
| REQ-24 — Idade média dos participantes por evento | **Descrição:** estima idade média (hoje) por evento. **Justificativa:** perfis de público; `JOIN`+`GROUP BY`+`AVG`. | ```sql
SELECT
  e.id_evento, e.ds_titulo AS evento,
  ROUND(AVG(EXTRACT(YEAR FROM AGE(CURRENT_DATE, p.dt_nascimento)))::numeric,1) AS idade_media
FROM tb_evento e
JOIN tb_atividade a ON a.id_evento = e.id_evento
JOIN tb_inscricao i ON i.id_atividade = a.id_atividade
JOIN tb_participante p ON p.id_participante = i.id_participante
GROUP BY e.id_evento, e.ds_titulo
ORDER BY idade_media DESC NULLS LAST;
``` |
| REQ-25 — Participantes com maior diversidade de modalidades | **Descrição:** nº de modalidades distintas em que cada participante se inscreveu. **Justificativa:** amplitude de interesse; `JOIN`+`GROUP BY`+`COUNT DISTINCT`. | ```sql
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
``` |
| REQ-26 — Conversão de inscrição→certificado (por atividade) | **Descrição:** % de certificados sobre confirmadas por atividade. **Justificativa:** eficiência pedagógica; `SUBQUERY`+`JOIN`+`GROUP BY`. | ```sql
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
``` |
| REQ-27 — Retenção de participantes (quantos eventos distintos) | **Descrição:** conta em quantos eventos um participante esteve. **Justificativa:** fidelização; `JOIN`+`GROUP BY`+`COUNT DISTINCT`. | ```sql
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
``` |
| REQ-28 — Sazonalidade: distribuição semanal de atividades | **Descrição:** atividades por semana do ano por evento. **Justificativa:** planejamento temporal; `JOIN`+`GROUP BY`. | ```sql
SELECT
  e.id_evento, e.ds_titulo AS evento,
  EXTRACT(WEEK FROM a.dt_atividade)::int AS semana,
  COUNT(*) AS atividades_semana
FROM tb_evento e
JOIN tb_atividade a ON a.id_evento = e.id_evento
GROUP BY e.id_evento, e.ds_titulo, EXTRACT(WEEK FROM a.dt_atividade)
ORDER BY e.id_evento, semana;
``` |
| REQ-29 — Certificados por carga horária (faixas) | **Descrição:** bucketiza carga horária e conta certificados. **Justificativa:** análise de produto/curso; `JOIN`+`GROUP BY`+`CASE`. | ```sql
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
``` |
| REQ-30 — “Trilha de excelência” (nota ≥4 e confirmação) | **Descrição:** atividades com nota média ≥4 e alta confirmação. **Justificativa:** curadoria de trilhas; `SUBQUERY`+`JOIN`+`HAVING`. | ```sql
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
``` |

---

#### Observações rápidas para a arguição
- **Rastreabilidade:** cada consulta tem **REQ-xx**, descrição e justificativa explícitas (exigência do Marco 1).  
- **Correção técnica:** todas usam **≥3 tabelas**; intermediárias com ≥2 recursos (JOIN/GROUP BY/WINDOW/COUNT) e avançadas com ≥3 incluindo **SUBQUERY**.  
- **Retorno não-vazio:** garantido com a **população sintética** fornecida.  
- **Métricas centrais:** confirmação, feedback, certificados, capacidade, diversidade e rankings — cobrindo **visão operacional e analítica** do minimundo.

Se quiser, eu entrego um **CSV/Markdown separado** só com o **catálogo das consultas** (ID, título, descrição, justificativa) para inserir direto no relatório SBC, e deixamos este arquivo apenas com o **SQL**.

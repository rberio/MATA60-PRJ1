-- =============================================================
-- ARTEFATO: VISUALIZAÇÃO DE DADOS (FRONT-END SIMULADO)
-- OBJETIVO: Inspecionar o estado das VMs na aba Data Output.
-- Executar cada linha uma por vez para obter os resultados.
-- =============================================================

-- Visualizar Tela 1 (Sua VM original)
SELECT * FROM VM_VAGAS_ABERTAS;

-- Visualizar Tela 2 (Sua VM original de 4 tabelas)
SELECT * FROM VM_PENDENCIAS_CERTIFICACAO;

-- Visualizar os 4 Gráficos do Dashboard 1 (Garantem o requisito de SQL Avançado)
SELECT * FROM VM_DASH_OCUPACAO;
SELECT * FROM VM_DASH_ADESAO;
SELECT * FROM VM_DASH_CONVERSAO_FEEDBACK;
SELECT * FROM VM_DASH_CERTIFICACAO_EVENTO;

-- DASHBOARD 1.1: Ranking de Popularidade
SELECT * FROM VM_DASH_OCUPACAO 
WHERE RANK_POPULARIDADE <= 5;

-- DASHBOARD 1.2: Evolução de Inscrições
SELECT * FROM VM_DASH_ADESAO 
ORDER BY DT_INSCRICAO DESC 
LIMIT 15;

-- DASHBOARD 1.3: Conversão de Feedback
SELECT * FROM VM_DASH_CONVERSAO_FEEDBACK 
ORDER BY PERC_RETORNO DESC;

-- DASHBOARD 1.4: Apenas quem realmente ocupa a vaga
SELECT * FROM VM_DASH_OCUPACAO 
WHERE ST_CONFIRMADA = TRUE;

-- =============================================================
-- TESTE DO DASHBOARD 2: OPERAÇÃO E PERFIL
-- =============================================================


-- -------------------------------------------------------------
-- GRÁFICO 1 (AVANÇADO): Top 5 Domínios de E-mail
-- -------------------------------------------------------------
SELECT * FROM VM_DASH_DOMINIOS_EMAIL;
-- Resultado Esperado: Uma lista com colunas DOMINIO (ex: gmail.com, ufba.br), 
-- TOTAL_INSCRICOES (contagem) e RANK_DOMINIO (1 a 5).
-- O que valida: Se o processamento de strings (SUBSTRING/POSITION) funcionou.

-- -------------------------------------------------------------
-- GRÁFICO 2 (AVANÇADO): Qualidade por Modalidade vs Global
-- -------------------------------------------------------------
SELECT * FROM VM_DASH_QUALIDADE_MODALIDADE;
-- Resultado Esperado: Duas linhas (Online e Presencial). 
-- Você verá a média de cada uma e a MEDIA_GLOBAL_EVENTO repetida em ambas.
-- O que valida: A subconsulta comparativa (o valor global deve ser igual para as duas linhas).

-- -------------------------------------------------------------
-- GRÁFICO 3 (INTERMEDIÁRIO): Participação por Evento
-- -------------------------------------------------------------
SELECT * FROM VM_DASH_PARTICIPACAO_EVENTO;
-- Resultado Esperado: Nome do evento e o volume total de inscritos.
-- O que valida: O cruzamento básico de 3 tabelas (Evento -> Atividade -> Inscrição).

-- -------------------------------------------------------------
-- GRÁFICO 4 (INTERMEDIÁRIO): Idade Média dos Inscritos
-- -------------------------------------------------------------
SELECT * FROM VM_DASH_IDADE_PARTICIPANTE;
-- Resultado Esperado: Uma média de idade (ex: 22, 25, 30) para cada evento.
-- O que valida: O cálculo aritmético ANSI de datas (Ano Atual - Ano Nascimento).

-- -------------------------------------------------------------
-- GRÁFICO 5 (INTERMEDIÁRIO): Eficiência de Certificação
-- -------------------------------------------------------------
SELECT * FROM VM_DASH_EFICIENCIA_CERTIFICADO;
-- Resultado Esperado: Colunas ATIVIDADE, INSCRITOS e CERTIFICADOS_EMITIDOS.
-- O que valida: O LEFT JOIN (atividades sem certificados ainda devem aparecer com valor zero).

-- -------------------------------------------------------------
-- GRÁFICO 6 (INTERMEDIÁRIO): Ocupação de Espaços Físicos
-- -------------------------------------------------------------
SELECT * FROM VM_DASH_OCUPACAO_FISICA;
-- Resultado Esperado: Apenas atividades com modalidade 'Presencial'.
-- O que valida: O filtro de cláusula WHERE em consultas de BI.
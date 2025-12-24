-- =============================================================
-- PROJETO PRJ1 - MATA60 (Marco 1 - Corrigido)
-- DDL 100% SQL (ANSI), pronto para PostgreSQL 12+
-- =============================================================

-- =============================================================
-- TABELAS PRINCIPAIS
-- =============================================================

-- EVENTO: container macro (congresso, semana de extensão, etc.)
CREATE TABLE TB_EVENTO (
    ID_EVENTO            INTEGER GENERATED ALWAYS AS IDENTITY,
    DS_TITULO            VARCHAR(100)     NOT NULL,
    DS_DESCRICAO         VARCHAR(1000),
    DT_INICIO            DATE             NOT NULL,
    DT_FIM               DATE             NOT NULL,
    DS_LOCAL             VARCHAR(100),
    CONSTRAINT PK_TB_EVENTO PRIMARY KEY (ID_EVENTO),
    CONSTRAINT CK_TB_EVENTO_DT CHECK (DT_INICIO <= DT_FIM)
);

-- ATIVIDADE: unidade ofertada dentro de um evento (palestra, minicurso, etc.)
CREATE TABLE TB_ATIVIDADE (
    ID_ATIVIDADE         INTEGER GENERATED ALWAYS AS IDENTITY,
    ID_EVENTO            INTEGER          NOT NULL,
    DS_TITULO            VARCHAR(100)     NOT NULL,
    DS_DESCRICAO         VARCHAR(1000),
    DT_ATIVIDADE         DATE             NOT NULL,
    HR_INICIO            TIME,
    HR_FIM               TIME,
    TP_MODALIDADE        VARCHAR(30),      -- ex.: 'palestra','minicurso','mesa'
    QT_VAGAS             INTEGER,
    DS_LOCAL             VARCHAR(100),
    ST_ATIVA             BOOLEAN          DEFAULT TRUE,
    CONSTRAINT PK_TB_ATIVIDADE PRIMARY KEY (ID_ATIVIDADE),
    CONSTRAINT FK_TB_ATIVIDADE_EVENTO
        FOREIGN KEY (ID_EVENTO)
        REFERENCES TB_EVENTO (ID_EVENTO)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT CK_TB_ATIVIDADE_HORAS CHECK (HR_INICIO IS NULL OR HR_FIM IS NULL OR HR_INICIO <= HR_FIM)
);

-- PARTICIPANTE: pessoa que se inscreve nas atividades
CREATE TABLE TB_PARTICIPANTE (
    ID_PARTICIPANTE      INTEGER GENERATED ALWAYS AS IDENTITY,
    NM_PARTICIPANTE      VARCHAR(120)     NOT NULL,
    CD_CPF               VARCHAR(14),     -- formato livre (com/sem pontuação)
    DS_EMAIL             VARCHAR(150),
    DT_NASCIMENTO        DATE,
    SG_SEXO              CHAR(1),
    DS_TELEFONE          VARCHAR(30),
    CONSTRAINT PK_TB_PARTICIPANTE PRIMARY KEY (ID_PARTICIPANTE),
    CONSTRAINT UK_TB_PARTICIPANTE_CPF UNIQUE (CD_CPF),
    CONSTRAINT UK_TB_PARTICIPANTE_EMAIL UNIQUE (DS_EMAIL)
);

-- INSTRUTOR: quem ministra atividades
CREATE TABLE TB_INSTRUTOR (
    ID_INSTRUTOR         INTEGER GENERATED ALWAYS AS IDENTITY,
    NM_INSTRUTOR         VARCHAR(120)     NOT NULL,
    DS_EMAIL             VARCHAR(150),
    CD_CPF               VARCHAR(14),
    DS_FORMACAO          VARCHAR(120),
    DS_AREA_ATUACAO      VARCHAR(120),
    CONSTRAINT PK_TB_INSTRUTOR PRIMARY KEY (ID_INSTRUTOR),
    CONSTRAINT UK_TB_INSTRUTOR_EMAIL UNIQUE (DS_EMAIL),
    CONSTRAINT UK_TB_INSTRUTOR_CPF UNIQUE (CD_CPF)
);

-- PARCEIRO: instituição parceira de um evento
CREATE TABLE TB_PARCEIRO (
    ID_PARCEIRO          INTEGER GENERATED ALWAYS AS IDENTITY,
    NM_PARCEIRO          VARCHAR(150)     NOT NULL,
    CD_CNPJ              VARCHAR(20),
    DS_CONTATO           VARCHAR(120),
    DS_EMAIL             VARCHAR(150),
    CONSTRAINT PK_TB_PARCEIRO PRIMARY KEY (ID_PARCEIRO),
    CONSTRAINT UK_TB_PARCEIRO_CNPJ UNIQUE (CD_CNPJ)
);

-- =============================================================
-- RELACIONAMENTOS N:N
-- =============================================================

-- Qual instrutor ministra qual atividade; pode haver papel (p.ex. 'titular','apoio')
CREATE TABLE RL_ATIVIDADE_INSTRUTOR (
    ID_ATIVIDADE         INTEGER NOT NULL,
    ID_INSTRUTOR         INTEGER NOT NULL,
    DS_PAPEL             VARCHAR(30),
    CONSTRAINT PK_RL_ATIVIDADE_INSTRUTOR PRIMARY KEY (ID_ATIVIDADE, ID_INSTRUTOR),
    CONSTRAINT FK_RL_AI_ATIVIDADE
        FOREIGN KEY (ID_ATIVIDADE)
        REFERENCES TB_ATIVIDADE (ID_ATIVIDADE)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT FK_RL_AI_INSTRUTOR
        FOREIGN KEY (ID_INSTRUTOR)
        REFERENCES TB_INSTRUTOR (ID_INSTRUTOR)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

-- Quais parceiros apoiam um evento; pode haver papel (p.ex. 'patrocinador','apoio')
CREATE TABLE RL_EVENTO_PARCEIRO (
    ID_EVENTO            INTEGER NOT NULL,
    ID_PARCEIRO          INTEGER NOT NULL,
    DS_PAPEL             VARCHAR(30),
    CONSTRAINT PK_RL_EVENTO_PARCEIRO PRIMARY KEY (ID_EVENTO, ID_PARCEIRO),
    CONSTRAINT FK_RL_EP_EVENTO
        FOREIGN KEY (ID_EVENTO)
        REFERENCES TB_EVENTO (ID_EVENTO)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT FK_RL_EP_PARCEIRO
        FOREIGN KEY (ID_PARCEIRO)
        REFERENCES TB_PARCEIRO (ID_PARCEIRO)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

-- =============================================================
-- TABELAS OPERACIONAIS
-- =============================================================

-- INSCRICAO: vínculo participante-atividade; uma por participante por atividade
CREATE TABLE TB_INSCRICAO (
    ID_INSCRICAO         INTEGER GENERATED ALWAYS AS IDENTITY,
    ID_PARTICIPANTE      INTEGER NOT NULL,
    ID_ATIVIDADE         INTEGER NOT NULL,
    DT_INSCRICAO         DATE    NOT NULL DEFAULT CURRENT_DATE,
    ST_CONFIRMADA        BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT PK_TB_INSCRICAO PRIMARY KEY (ID_INSCRICAO),
    CONSTRAINT UK_TB_INSCRICAO_UNICA UNIQUE (ID_PARTICIPANTE, ID_ATIVIDADE),
    CONSTRAINT FK_TB_INSCRICAO_PARTICIPANTE
        FOREIGN KEY (ID_PARTICIPANTE)
        REFERENCES TB_PARTICIPANTE (ID_PARTICIPANTE)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT FK_TB_INSCRICAO_ATIVIDADE
        FOREIGN KEY (ID_ATIVIDADE)
        REFERENCES TB_ATIVIDADE (ID_ATIVIDADE)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

-- FEEDBACK: avaliação da atividade por um participante (uma por participante/atividade)
CREATE TABLE TB_FEEDBACK (
    ID_FEEDBACK          INTEGER GENERATED ALWAYS AS IDENTITY,
    ID_PARTICIPANTE      INTEGER NOT NULL,
    ID_ATIVIDADE         INTEGER NOT NULL,
    VL_NOTA_CONTEUDO     INTEGER NOT NULL, -- 1..5
    VL_NOTA_INSTRUTOR    INTEGER NOT NULL, -- 1..5
    VL_NOTA_ORGANIZACAO  INTEGER NOT NULL, -- 1..5
    DS_COMENTARIO        VARCHAR(500),
    DT_AVALIACAO         DATE    NOT NULL DEFAULT CURRENT_DATE,
    CONSTRAINT PK_TB_FEEDBACK PRIMARY KEY (ID_FEEDBACK),
    CONSTRAINT UK_TB_FEEDBACK_UNICA UNIQUE (ID_PARTICIPANTE, ID_ATIVIDADE),
    CONSTRAINT CK_TB_FEEDBACK_ESCALA CHECK (
        VL_NOTA_CONTEUDO    BETWEEN 1 AND 5 AND
        VL_NOTA_INSTRUTOR   BETWEEN 1 AND 5 AND
        VL_NOTA_ORGANIZACAO BETWEEN 1 AND 5
    ),
    CONSTRAINT FK_TB_FEEDBACK_INSCRICAO
        FOREIGN KEY (ID_PARTICIPANTE, ID_ATIVIDADE)
        REFERENCES TB_INSCRICAO (ID_PARTICIPANTE, ID_ATIVIDADE)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

-- CERTIFICADO: emissão para participante que concluiu atividade
CREATE TABLE TB_CERTIFICADO (
    ID_CERTIFICADO       INTEGER GENERATED ALWAYS AS IDENTITY,
    ID_PARTICIPANTE      INTEGER NOT NULL,
    ID_ATIVIDADE         INTEGER NOT NULL,
    NR_CARGA_HORARIA     NUMERIC(4,1) NOT NULL,
    DT_EMISSAO           DATE         NOT NULL DEFAULT CURRENT_DATE,
    CD_VALIDACAO         VARCHAR(40)  NOT NULL,
    CONSTRAINT PK_TB_CERTIFICADO PRIMARY KEY (ID_CERTIFICADO),
    CONSTRAINT UK_TB_CERTIFICADO_VALIDACAO UNIQUE (CD_VALIDACAO),
    CONSTRAINT UK_TB_CERTIFICADO_UNICO UNIQUE (ID_PARTICIPANTE, ID_ATIVIDADE),
    CONSTRAINT FK_TB_CERTIFICADO_INSCRICAO
        FOREIGN KEY (ID_PARTICIPANTE, ID_ATIVIDADE)
        REFERENCES TB_INSCRICAO (ID_PARTICIPANTE, ID_ATIVIDADE)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

-- =============================================================
-- AUDITORIA (MAD/PPP) - somente estrutura; gravação pode ser explícita via SQL
-- =============================================================

CREATE TABLE TA_AUDITORIA (
    ID_AUDITORIA         INTEGER GENERATED ALWAYS AS IDENTITY,
    DT_OPERACAO          TIMESTAMP        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    NM_TABELA            VARCHAR(50)      NOT NULL,
    TP_OPERACAO          VARCHAR(10)      NOT NULL,   -- 'INSERT','UPDATE','DELETE'
    ID_REGISTRO          VARCHAR(60),                 -- armazenar PK do registro afetado
    USUARIO_RESPONSAVEL  VARCHAR(120),
    DETALHE              VARCHAR(1000),
    CONSTRAINT PK_TA_AUDITORIA PRIMARY KEY (ID_AUDITORIA)
);

-- =============================================================
-- ÍNDICES (padrão MAD1: prefixo IDX_)
-- =============================================================

-- FKs/joins e filtros típicos
CREATE INDEX IDX_TB_ATIVIDADE_ID_EVENTO      ON TB_ATIVIDADE (ID_EVENTO);
CREATE INDEX IDX_TB_ATIVIDADE_DT_ATIVIDADE   ON TB_ATIVIDADE (DT_ATIVIDADE);
CREATE INDEX IDX_RL_AI_ID_INSTRUTOR          ON RL_ATIVIDADE_INSTRUTOR (ID_INSTRUTOR);
CREATE INDEX IDX_RL_EP_ID_PARCEIRO           ON RL_EVENTO_PARCEIRO (ID_PARCEIRO);
CREATE INDEX IDX_TB_INSCRICAO_PARTICIPANTE   ON TB_INSCRICAO (ID_PARTICIPANTE);
CREATE INDEX IDX_TB_INSCRICAO_ATIVIDADE      ON TB_INSCRICAO (ID_ATIVIDADE);
CREATE INDEX IDX_TB_FEEDBACK_PARTICIPANTE    ON TB_FEEDBACK (ID_PARTICIPANTE);
CREATE INDEX IDX_TB_FEEDBACK_ATIVIDADE       ON TB_FEEDBACK (ID_ATIVIDADE);
CREATE INDEX IDX_TB_CERTIFICADO_PARTICIPANTE ON TB_CERTIFICADO (ID_PARTICIPANTE);
CREATE INDEX IDX_TB_CERTIFICADO_ATIVIDADE    ON TB_CERTIFICADO (ID_ATIVIDADE);
CREATE INDEX IDX_TB_PARTICIPANTE_CPF         ON TB_PARTICIPANTE (CD_CPF);
CREATE INDEX IDX_TB_PARCEIRO_CNPJ            ON TB_PARCEIRO (CD_CNPJ);
CREATE INDEX IDX_TA_AUDITORIA_DT             ON TA_AUDITORIA (DT_OPERACAO);

-- =============================================================
-- DOCUMENTAÇÃO (MAD/PPP) - COMMENT ON
-- =============================================================

COMMENT ON TABLE  TB_EVENTO                      IS 'Evento acadêmico principal (container de atividades).';
COMMENT ON COLUMN TB_EVENTO.DS_TITULO            IS 'Título do evento.';
COMMENT ON COLUMN TB_EVENTO.DT_INICIO            IS 'Data de início do evento.';
COMMENT ON COLUMN TB_EVENTO.DT_FIM               IS 'Data de término do evento.';

COMMENT ON TABLE  TB_ATIVIDADE                   IS 'Atividade (palestra, minicurso, etc.) pertencente a um evento.';
COMMENT ON COLUMN TB_ATIVIDADE.ID_EVENTO         IS 'FK para TB_EVENTO.';
COMMENT ON COLUMN TB_ATIVIDADE.DT_ATIVIDADE      IS 'Data de realização da atividade.';
COMMENT ON COLUMN TB_ATIVIDADE.QT_VAGAS          IS 'Vagas ofertadas (quando aplicável).';

COMMENT ON TABLE  TB_PARTICIPANTE                IS 'Pessoa que se inscreve nas atividades.';
COMMENT ON COLUMN TB_PARTICIPANTE.CD_CPF         IS 'CPF (único, formato flexível).';
COMMENT ON COLUMN TB_PARTICIPANTE.DS_EMAIL       IS 'E-mail do participante (único).';

COMMENT ON TABLE  TB_INSTRUTOR                   IS 'Pessoa que ministra atividades.';
COMMENT ON COLUMN TB_INSTRUTOR.DS_EMAIL          IS 'E-mail do instrutor (único).';
COMMENT ON COLUMN TB_INSTRUTOR.CD_CPF            IS 'CPF do instrutor (único).';

COMMENT ON TABLE  TB_PARCEIRO                    IS 'Instituição parceira de um evento.';
COMMENT ON COLUMN TB_PARCEIRO.CD_CNPJ            IS 'CNPJ (único).';

COMMENT ON TABLE  RL_ATIVIDADE_INSTRUTOR         IS 'Relação N:N entre atividade e instrutor (com papel).';
COMMENT ON TABLE  RL_EVENTO_PARCEIRO             IS 'Relação N:N entre evento e parceiro (com papel).';

COMMENT ON TABLE  TB_INSCRICAO                   IS 'Inscrição de participante em atividade (única por participante/atividade).';
COMMENT ON COLUMN TB_INSCRICAO.ST_CONFIRMADA     IS 'Confirmação da inscrição pelo organizador.';

COMMENT ON TABLE  TB_FEEDBACK                    IS 'Avaliação da atividade pelo participante (única por participante/atividade).';
COMMENT ON COLUMN TB_FEEDBACK.VL_NOTA_CONTEUDO   IS 'Nota 1..5 para conteúdo.';
COMMENT ON COLUMN TB_FEEDBACK.VL_NOTA_INSTRUTOR  IS 'Nota 1..5 para instrutor.';
COMMENT ON COLUMN TB_FEEDBACK.VL_NOTA_ORGANIZACAO IS 'Nota 1..5 para organização.';

COMMENT ON TABLE  TB_CERTIFICADO                 IS 'Certificado emitido ao participante que concluiu atividade.';
COMMENT ON COLUMN TB_CERTIFICADO.CD_VALIDACAO    IS 'Código único de validação do certificado.';

COMMENT ON TABLE  TA_AUDITORIA                   IS 'Trilha de auditoria (MAD/PPP). Registros feitos explicitamente por SQL nas rotinas de manipulação.';

-- PRJ1 – Banco de Dados do Sistema de Gestão de Atividades de Extensão Universitária (Projeto MATA60)

-- =============================================================
-- FIM DO DDL
-- =============================================================

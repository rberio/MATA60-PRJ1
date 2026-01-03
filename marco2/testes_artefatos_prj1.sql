-- =============================================================
-- PROJETO: GESTÃO DE EVENTOS ACADÊMICOS
-- ARTEFATO: ROTEIRO DE TESTES (TELA 1 E TELA 2)
-- OBJETIVO: Validar regras de negócio e integridade dos dados
-- =============================================================

-- PREPARAÇÃO: Limpar possíveis resíduos de testes anteriores




-- =============================================================
-- ARTEFATO: TESTES DE PROCESSAMENTO (BACK-END)
-- OBJETIVO: Executar rotinas e verificar logs na aba Messages.
-- =============================================================

DELETE FROM TB_CERTIFICADO WHERE ID_PARTICIPANTE = 9999;
DELETE FROM TB_FEEDBACK    WHERE ID_PARTICIPANTE = 9999;
DELETE FROM TB_INSCRICAO   WHERE ID_PARTICIPANTE = 9999;

-- =============================================================
-- ROTEIRO DE TESTES CONSOLIDADO - RELATÓRIO DE EXECUÇÃO
-- =============================================================

DO $$ 
DECLARE
    v_total_vagas  INTEGER;
    v_status_insc  BOOLEAN;
    v_ch_cert      DECIMAL;
    v_count        INTEGER;
BEGIN 
    RAISE NOTICE 'Iniciando bateria de testes dos artefatos...';

    -- PREPARAÇÃO (SILENCIOSA)
    DELETE FROM TB_CERTIFICADO WHERE ID_PARTICIPANTE = 9999;
    DELETE FROM TB_FEEDBACK    WHERE ID_PARTICIPANTE = 9999;
    DELETE FROM TB_INSCRICAO   WHERE ID_PARTICIPANTE = 9999;

    -- 1. Teste da Rotina de Manutenção do Dashboard 1
    RAISE NOTICE '1. Atualizando fontes de dados analíticas (Dashboard 1)...';
    -- 1. Atualiza o Dashboard 1 e 2
    CALL SP_MANUTENCAO_DASHBOARD_1();
    CALL SP_MANUTENCAO_DASHBOARD_2();

    -- 2. Atualiza a VM da sua TELA 1
    REFRESH MATERIALIZED VIEW VM_VAGAS_ABERTAS;

    -- 3. Atualiza a VM da sua TELA 2
    REFRESH MATERIALIZED VIEW VM_PENDENCIAS_CERTIFICACAO;

    RAISE NOTICE '✓ Todos os artefatos (Dashboard + Telas) atualizados com sucesso.';

        -- ---------------------------------------------------------
    -- TELA 1: TESTES DE INSCRIÇÃO
    -- ---------------------------------------------------------
    
    -- Teste 1.1: Atividade Inexistente
    BEGIN
        CALL SP_REALIZAR_INSCRICAO(9999, 8888, 'Portal');
    EXCEPTION WHEN OTHERS THEN 
        RAISE NOTICE '✓ 1.1 Esperado (Erro Ativ): %', SQLERRM;
    END;

    -- Teste 1.2: Atividade Passada (ID 9001)
    BEGIN
        CALL SP_REALIZAR_INSCRICAO(9999, 9001, 'Portal');
    EXCEPTION WHEN OTHERS THEN 
        RAISE NOTICE '✓ 1.2 Esperado (Erro Data): %', SQLERRM;
    END;

    -- Teste 1.3: Atividade sem vagas (ID 9002 - Palestra Lotada)
    -- Esperado: ERROR: Não há vagas disponíveis.
    BEGIN
        CALL SP_REALIZAR_INSCRICAO(9999, 9002, 'Portal_Aluno');
    EXCEPTION WHEN OTHERS THEN 
        RAISE NOTICE '✓ Teste 1.3 (Resposta para Ativ. Sem Vagas): %', SQLERRM;
    END;

-- Teste 1.4: Sucesso na Inscrição (ID 9003)
    BEGIN
        CALL SP_REALIZAR_INSCRICAO(9999, 9003, 'Portal');
        RAISE NOTICE '✓ 1.4 Sucesso: Inscrição do aluno 9999 na atividade 9003 realizada.';
    END;

    -- VERIFICAÇÃO DA VM (VAGAS)
    EXECUTE 'REFRESH MATERIALIZED VIEW VM_VAGAS_ABERTAS';
    SELECT QT_VAGAS INTO v_total_vagas FROM TB_ATIVIDADE WHERE ID_ATIVIDADE = 9003;
    RAISE NOTICE '✓ Verificação VM: Vagas restantes na Atividade 9003: %', v_total_vagas;

-- CASO 1.5: Tentativa de duplicidade (Mesmo aluno na mesma atividade)
-- Esperado: O banco deve barrar por Primary Key ou validação.
    BEGIN
        CALL SP_REALIZAR_INSCRICAO(9999, 9003, 'Portal_Aluno');
    EXCEPTION WHEN OTHERS THEN 
        RAISE NOTICE '✓ Teste 1.5 (Resposta para Duplicidade): %', SQLERRM;
    END;

    RAISE NOTICE '2. Simulando rotina de inscrição de teste...';
    -- -------------------------------------------------------------
-- SEÇÃO 2: TESTES DA TELA 2 (PRESENÇA E CERTIFICAÇÃO)
-- -------------------------------------------------------------

-- CASO 2.1: Inscrição não encontrada (Tentando certificar em ativ. onde não se inscreveu)
-- Esperado: ERROR: Inscrição não encontrada.
    BEGIN
        CALL SP_GESTAO_PRESENCA_CERTIFICADO(9999, 9001, 'CONFIRMAR');
    EXCEPTION WHEN OTHERS THEN 
        RAISE NOTICE '✓ Teste 2.1 (Resposta para Sem Inscrição): %', SQLERRM;
    END;

-- Teste 2.2: Confirmar SEM Feedback
    BEGIN
        CALL SP_GESTAO_PRESENCA_CERTIFICADO(9999, 9003, 'CONFIRMAR');
    EXCEPTION WHEN OTHERS THEN 
        RAISE NOTICE '✓ 2.2 Esperado (Erro Feedback): %', SQLERRM;
    END;

    -- Teste 2.3: Sucesso (Feedback + Certificação)
-- Teste 2.3: Sucesso (Feedback + Certificação)
    BEGIN
        -- Simula Feedback
        INSERT INTO TB_FEEDBACK (
            ID_PARTICIPANTE, ID_ATIVIDADE,
            VL_NOTA_CONTEUDO, VL_NOTA_INSTRUTOR, VL_NOTA_ORGANIZACAO, DT_AVALIACAO
        )
        VALUES (9999, 9003, 5, 5, 5, CURRENT_DATE);
        
        -- Certifica
        CALL SP_GESTAO_PRESENCA_CERTIFICADO(9999, 9003, 'CONFIRMAR');
        
        -- Verificação correta: carga horária vem da ATIVIDADE
        SELECT A.QT_CARGA_HORARIA
        INTO v_ch_cert
        FROM TB_CERTIFICADO C
        JOIN TB_ATIVIDADE A ON A.ID_ATIVIDADE = C.ID_ATIVIDADE
        WHERE C.ID_PARTICIPANTE = 9999
        AND C.ID_ATIVIDADE = 9003;
        
        RAISE NOTICE 
            '✓ 2.3 Sucesso: Presença confirmada. Certificado gerado para atividade com % horas.',
            v_ch_cert;
    END;

    -- Teste 2.4: Cancelamento (Delete)
    BEGIN
        CALL SP_GESTAO_PRESENCA_CERTIFICADO(9999, 9003, 'CANCELAR');
        
        SELECT COUNT(*) INTO v_count FROM TB_INSCRICAO 
        WHERE ID_PARTICIPANTE = 9999 AND ID_ATIVIDADE = 9003;
        
        IF v_count = 0 THEN
            RAISE NOTICE '✓ 2.4 Sucesso: Inscrição 9999/9003 removida do banco (DELETE OK).';
        END IF;
    END;

    -- CASO 2.5: Cancelar inscrição que já foi deletada
    -- Esperado: ERROR: Inscrição não encontrada.
    BEGIN
        CALL SP_GESTAO_PRESENCA_CERTIFICADO(9999, 9003, 'CANCELAR');
    EXCEPTION WHEN OTHERS THEN 
        RAISE NOTICE '✓ Teste 2.5 (Resposta para Exclusão Dupla): %', SQLERRM;
    END;

    RAISE NOTICE '✓ Todos os artefatos foram processados com sucesso.';
END $$;
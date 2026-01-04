-- ============================================
-- SCRIPT DE TESTE DE INTEGRIDADE - PRJ1 (MARCO 2 - ETAPA 0)
-- ============================================
DO $$
DECLARE
    v_certificados_sem_inscricao INTEGER;
    v_feedbacks_sem_inscricao INTEGER;
    v_duplicatas_confirmadas INTEGER;
BEGIN
    RAISE NOTICE '=== INICIANDO TESTES DE INTEGRIDADE ===';
    
    -- Teste 1: Certificados devem ter inscrição
    SELECT COUNT(*) INTO v_certificados_sem_inscricao
    FROM tb_certificado c
    WHERE NOT EXISTS (
        SELECT 1 FROM tb_inscricao i
        WHERE i.id_participante = c.id_participante
        AND i.id_atividade = c.id_atividade
    );
    
    IF v_certificados_sem_inscricao = 0 THEN
        RAISE NOTICE '✓ Teste 1 PASS: Todos certificados têm inscrição';
    ELSE
        RAISE NOTICE '✗ Teste 1 FAIL: % certificados sem inscrição', v_certificados_sem_inscricao;
    END IF;
    
    -- Teste 2: Feedbacks devem ter inscrição
    SELECT COUNT(*) INTO v_feedbacks_sem_inscricao
    FROM tb_feedback f
    WHERE NOT EXISTS (
        SELECT 1 FROM tb_inscricao i
        WHERE i.id_participante = f.id_participante
        AND i.id_atividade = f.id_atividade
    );
    
    IF v_feedbacks_sem_inscricao = 0 THEN
        RAISE NOTICE '✓ Teste 2 PASS: Todos feedbacks têm inscrição';
    ELSE
        RAISE NOTICE '✗ Teste 2 FAIL: % feedbacks sem inscrição', v_feedbacks_sem_inscricao;
    END IF;
    
    -- Teste 3: Não deve haver inscrições confirmadas duplicadas
    SELECT COUNT(*) INTO v_duplicatas_confirmadas
    FROM (
        SELECT id_participante, id_atividade
        FROM tb_inscricao
        WHERE st_confirmada = TRUE
        GROUP BY id_participante, id_atividade
        HAVING COUNT(*) > 1
    ) AS dup;
    
    IF v_duplicatas_confirmadas = 0 THEN
        RAISE NOTICE '✓ Teste 3 PASS: Não há inscrições confirmadas duplicadas';
    ELSE
        RAISE NOTICE '✗ Teste 3 FAIL: % pares duplicados confirmados', v_duplicatas_confirmadas;
    END IF;
    
    RAISE NOTICE '';
    RAISE NOTICE '=== VERIFICANDO NOVAS CONSTRAINTS (ETAPA 0) ===';
    
    -- Teste 4: Foreign Keys (Comportamento já existente)
    BEGIN
        INSERT INTO tb_certificado (id_participante, id_atividade, dt_emissao, cd_validacao)
        VALUES (999999, 999999, CURRENT_DATE, 'TESTE_FAIL');
        RAISE NOTICE '✗ Teste 4 FAIL: Inserção ilegal de certificado permitida';
    EXCEPTION WHEN foreign_key_violation THEN
        RAISE NOTICE '✓ Teste 4 PASS: FK impede certificado sem registro pai';
    END;

    -- Teste 5.1: Regra de Vagas (Ajuste que fizemos na TB_ATIVIDADE)
    BEGIN
        -- Tenta inserir uma atividade com -5 vagas (assumindo que o Evento 1 existe)
        INSERT INTO tb_atividade (id_evento, ds_titulo, dt_atividade, qt_vagas, qt_carga_horaria)
        VALUES (1, 'Atividade Fantasma', CURRENT_DATE, -5, 5.0);
        RAISE NOTICE '✗ Teste 5.1 FAIL: Inserção de vagas negativas permitida';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE '✓ Teste 5.1 PASS: CHECK constraint impediu vagas negativas';
    END;

    -- Teste 5.2: Regra de Carga Horaria (Ajuste na TB_ATIVIDADE)
    BEGIN
        -- Tenta inserir uma atividade com -5 de carga horária (assumindo que o Evento 1 existe)
        INSERT INTO tb_atividade (id_evento, ds_titulo, dt_atividade, qt_vagas, qt_carga_horaria)
        VALUES (1, 'Atividade Fantasma', CURRENT_DATE, 5, -5.0);
        RAISE NOTICE '✗ Teste 5.2 FAIL: Inserção de carga horária negativa permitida';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE '✓ Teste 5.2 PASS: CHECK constraint impediu carga horária negativa';
    END;

    -- Teste 6: Integridade Temporal de Eventos (Início <= Fim)
    BEGIN
        INSERT INTO tb_evento (ds_titulo, dt_inicio, dt_fim)
        VALUES ('Evento Temporal Impossível', '2025-12-31', '2025-01-01');
        RAISE NOTICE '✗ Teste 6 FAIL: Evento com data de fim anterior ao início permitido';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE '✓ Teste 6 PASS: CHECK constraint impediu datas de evento inconsistentes';
    END;

    RAISE NOTICE '';
    RAISE NOTICE '=== VERIFICANDO CONFORMIDADE MAD (AUDITORIA) ===';

    -- Teste 7: Existência das colunas obrigatórias na TA_AUDITORIA
    -- O comando PERFORM tenta selecionar as colunas; se faltar alguma, lança erro.
    BEGIN
        PERFORM tp_operacao, nm_usuario_bd, nm_usuario_aplicacao, nm_terminal, ds_valor_antigo, ds_valor_novo 
        FROM ta_auditoria LIMIT 0;
        RAISE NOTICE '✓ Teste 7 PASS: TA_AUDITORIA possui todas as colunas exigidas pela MAD e ISO';
    EXCEPTION WHEN undefined_column THEN
        RAISE NOTICE '✗ Teste 7 FAIL: TA_AUDITORIA não está em conformidade com o padrão MAD (faltam colunas)';
    END;
    
    RAISE NOTICE '';
    RAISE NOTICE '=== TESTES CONCLUÍDOS ===';

END $$;

-- TaskCloud | MariaDB 10.11 | DDL de revisao, NAO EXECUTADO
-- Executar somente apos aprovacao expressa, backup e validacao em ambiente de teste.
-- Banco taskcloud deve existir; este script NAO cria banco nem altera XAMPP.
-- Datas em UTC gerenciadas pela aplicacao. Tabelas InnoDB/utf8mb4.
-- Operacoes DDL fazem commits implicitos: nao pressupor rollback transacional.
-- Importar este arquivo em um banco taskcloud VAZIO.
-- NAO importar junto com as migracoes individuais (duplicacao).

-- Tabela: empresas
CREATE TABLE IF NOT EXISTS `empresas` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `razao_social` VARCHAR(200) NOT NULL,
  `nome_fantasia` VARCHAR(200) NULL,
  `cnpj` CHAR(14) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  `email_contato` VARCHAR(254) NOT NULL,
  `status` ENUM('ativa','suspensa','excluida') NOT NULL DEFAULT 'ativa',
  `criado_em` DATETIME NOT NULL,
  `atualizado_em` DATETIME NOT NULL,
  `suspensa_em` DATETIME NULL,
  `excluida_em` DATETIME NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_emp_cnpj` (`cnpj`),
  KEY `ix_emp_status` (`status`),
  CONSTRAINT `ck_emp_cnpj` CHECK (`cnpj` REGEXP '^[0-9]{14}$')
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Tabela: usuarios
CREATE TABLE IF NOT EXISTS `usuarios` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `empresa_id` BIGINT UNSIGNED NOT NULL,
  `nome` VARCHAR(150) NOT NULL,
  `email` VARCHAR(254) NOT NULL,
  `senha_hash` VARCHAR(255) NOT NULL,
  `papel` ENUM('principal','administrador','funcionario') NOT NULL,
  `status` ENUM('ativo','inativo') NOT NULL DEFAULT 'ativo',
  `criado_em` DATETIME NOT NULL,
  `atualizado_em` DATETIME NOT NULL,
  `ultimo_login_em` DATETIME NULL,
  `desativado_em` DATETIME NULL,
  `desativado_por` BIGINT UNSIGNED NULL,
  `empresa_principal_unica` BIGINT UNSIGNED GENERATED ALWAYS AS (CASE WHEN `papel` = 'principal' THEN `empresa_id` ELSE NULL END) PERSISTENT,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_usr_email` (`email`),
  UNIQUE KEY `uq_usr_tenant_id` (`empresa_id`,`id`),
  UNIQUE KEY `uq_usr_principal` (`empresa_principal_unica`),
  KEY `ix_usr_status` (`empresa_id`,`status`),
  KEY `ix_usr_papel` (`empresa_id`,`papel`),
  CONSTRAINT `fk_usr_empresa` FOREIGN KEY (`empresa_id`) REFERENCES `empresas` (`id`) ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT `fk_usr_desativador` FOREIGN KEY (`empresa_id`, `desativado_por`) REFERENCES `usuarios` (`empresa_id`, `id`) ON UPDATE RESTRICT ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Tabela: configuracoes_empresa
CREATE TABLE IF NOT EXISTS `configuracoes_empresa` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `empresa_id` BIGINT UNSIGNED NOT NULL,
  `nome_exibicao` VARCHAR(200) NULL,
  `fuso_horario` VARCHAR(64) NOT NULL DEFAULT 'America/Sao_Paulo',
  `formato_data` VARCHAR(20) NOT NULL DEFAULT 'DD/MM/YYYY',
  `idioma` VARCHAR(10) NOT NULL DEFAULT 'pt-BR',
  `criado_em` DATETIME NOT NULL,
  `atualizado_em` DATETIME NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_cfg_empresa` (`empresa_id`),
  CONSTRAINT `fk_cfg_empresa` FOREIGN KEY (`empresa_id`) REFERENCES `empresas` (`id`) ON UPDATE RESTRICT ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Tabela: convites
CREATE TABLE IF NOT EXISTS `convites` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `empresa_id` BIGINT UNSIGNED NOT NULL,
  `email_convidado` VARCHAR(254) NOT NULL,
  `papel_convidado` ENUM('administrador','funcionario') NOT NULL,
  `token_hash` CHAR(64) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  `convidado_por` BIGINT UNSIGNED NOT NULL,
  `criado_em` DATETIME NOT NULL,
  `expira_em` DATETIME NOT NULL,
  `aceito_em` DATETIME NULL,
  `revogado_em` DATETIME NULL,
  `usuario_criado_id` BIGINT UNSIGNED NULL,
  `email_pendente_unico` VARCHAR(254) GENERATED ALWAYS AS (CASE WHEN `aceito_em` IS NULL AND `revogado_em` IS NULL THEN `email_convidado` ELSE NULL END) PERSISTENT,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_conv_token` (`token_hash`),
  UNIQUE KEY `uq_conv_pendente` (`empresa_id`,`email_pendente_unico`),
  KEY `ix_conv_exp` (`empresa_id`,`expira_em`),
  CONSTRAINT `fk_conv_empresa_usuario` FOREIGN KEY (`empresa_id`, `convidado_por`) REFERENCES `usuarios` (`empresa_id`, `id`) ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT `fk_conv_criado_usuario` FOREIGN KEY (`empresa_id`, `usuario_criado_id`) REFERENCES `usuarios` (`empresa_id`, `id`) ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT `ck_conv_datas` CHECK (`expira_em` > `criado_em`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Tabela: recuperacoes_senha
CREATE TABLE IF NOT EXISTS `recuperacoes_senha` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `usuario_id` BIGINT UNSIGNED NOT NULL,
  `token_hash` CHAR(64) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  `criado_em` DATETIME NOT NULL,
  `expira_em` DATETIME NOT NULL,
  `utilizado_em` DATETIME NULL,
  `revogado_em` DATETIME NULL,
  `solicitado_ip` VARBINARY(16) NULL,
  `solicitado_user_agent` VARCHAR(512) NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_rec_token` (`token_hash`),
  KEY `ix_rec_user_created` (`usuario_id`,`criado_em`),
  KEY `ix_rec_user_exp` (`usuario_id`,`expira_em`),
  CONSTRAINT `fk_rec_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT `ck_rec_datas` CHECK (`expira_em` > `criado_em`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Tabela: dispositivos_reconhecidos
CREATE TABLE IF NOT EXISTS `dispositivos_reconhecidos` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `empresa_id` BIGINT UNSIGNED NOT NULL,
  `usuario_id` BIGINT UNSIGNED NOT NULL,
  `token_hash` CHAR(64) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  `nome_dispositivo` VARCHAR(150) NULL,
  `primeiro_acesso_em` DATETIME NOT NULL,
  `ultimo_acesso_em` DATETIME NOT NULL,
  `expira_em` DATETIME NOT NULL,
  `revogado_em` DATETIME NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_disp_token` (`token_hash`),
  UNIQUE KEY `uq_disp_tenant_user_id` (`empresa_id`,`usuario_id`,`id`),
  KEY `ix_disp_user_rev_exp` (`usuario_id`,`revogado_em`,`expira_em`),
  CONSTRAINT `fk_disp_usuario` FOREIGN KEY (`empresa_id`, `usuario_id`) REFERENCES `usuarios` (`empresa_id`, `id`) ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT `ck_disp_datas` CHECK (`expira_em` > `primeiro_acesso_em`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Tabela: sessoes_usuario
CREATE TABLE IF NOT EXISTS `sessoes_usuario` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `empresa_id` BIGINT UNSIGNED NOT NULL,
  `usuario_id` BIGINT UNSIGNED NOT NULL,
  `identificador_hash` CHAR(64) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  `dispositivo_id` BIGINT UNSIGNED NULL,
  `criado_em` DATETIME NOT NULL,
  `ultima_atividade_em` DATETIME NOT NULL,
  `expira_em` DATETIME NOT NULL,
  `encerrado_em` DATETIME NULL,
  `motivo_encerramento` VARCHAR(50) NULL,
  `endereco_ip` VARBINARY(16) NULL,
  `user_agent` VARCHAR(512) NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_ses_ident` (`identificador_hash`),
  KEY `ix_ses_user_end` (`usuario_id`,`encerrado_em`),
  KEY `ix_ses_empresa_user` (`empresa_id`,`usuario_id`),
  KEY `ix_ses_exp` (`expira_em`),
  CONSTRAINT `fk_ses_usuario` FOREIGN KEY (`empresa_id`, `usuario_id`) REFERENCES `usuarios` (`empresa_id`, `id`) ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT `fk_ses_dispositivo` FOREIGN KEY (`empresa_id`, `usuario_id`, `dispositivo_id`) REFERENCES `dispositivos_reconhecidos` (`empresa_id`, `usuario_id`, `id`) ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT `ck_ses_datas` CHECK (`expira_em` > `criado_em`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Tabela: tarefas
CREATE TABLE IF NOT EXISTS `tarefas` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `empresa_id` BIGINT UNSIGNED NOT NULL,
  `titulo` VARCHAR(200) NOT NULL,
  `descricao` TEXT NULL,
  `prioridade` ENUM('baixa','media','alta','urgente') NOT NULL DEFAULT 'media',
  `status` ENUM('pendente','em_andamento','aguardando_aprovacao','concluida') NOT NULL DEFAULT 'pendente',
  `progresso` TINYINT UNSIGNED NOT NULL DEFAULT 0,
  `prazo_em` DATETIME NULL,
  `criado_por` BIGINT UNSIGNED NOT NULL,
  `criado_em` DATETIME NOT NULL,
  `atualizado_em` DATETIME NOT NULL,
  `enviado_aprovacao_em` DATETIME NULL,
  `concluido_em` DATETIME NULL,
  `arquivado_em` DATETIME NULL,
  `arquivado_por` BIGINT UNSIGNED NULL,
  `versao` BIGINT UNSIGNED NOT NULL DEFAULT 1,
  `ciclo_aprovacao` INT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_tar_tenant_id` (`empresa_id`,`id`),
  KEY `ix_tar_status` (`empresa_id`,`status`),
  KEY `ix_tar_prioridade` (`empresa_id`,`prioridade`),
  KEY `ix_tar_prazo` (`empresa_id`,`prazo_em`),
  KEY `ix_tar_arquivo` (`empresa_id`,`arquivado_em`),
  KEY `ix_tar_criado` (`empresa_id`,`criado_em`),
  CONSTRAINT `fk_tar_criador` FOREIGN KEY (`empresa_id`, `criado_por`) REFERENCES `usuarios` (`empresa_id`, `id`) ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT `fk_tar_arquivador` FOREIGN KEY (`empresa_id`, `arquivado_por`) REFERENCES `usuarios` (`empresa_id`, `id`) ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT `ck_tar_progresso` CHECK (`progresso` BETWEEN 0 AND 100),
  CONSTRAINT `ck_tar_versao` CHECK (`versao` >= 1)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Tabela: tarefa_responsaveis
CREATE TABLE IF NOT EXISTS `tarefa_responsaveis` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `empresa_id` BIGINT UNSIGNED NOT NULL,
  `tarefa_id` BIGINT UNSIGNED NOT NULL,
  `usuario_id` BIGINT UNSIGNED NOT NULL,
  `atribuido_por` BIGINT UNSIGNED NOT NULL,
  `atribuido_em` DATETIME NOT NULL,
  `removido_em` DATETIME NULL,
  `removido_por` BIGINT UNSIGNED NULL,
  `usuario_ativo_id` BIGINT UNSIGNED GENERATED ALWAYS AS (CASE WHEN `removido_em` IS NULL THEN `usuario_id` ELSE NULL END) PERSISTENT,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_resp_ativo` (`empresa_id`,`tarefa_id`,`usuario_ativo_id`),
  KEY `ix_resp_usuario` (`empresa_id`,`usuario_id`,`removido_em`),
  KEY `ix_resp_tarefa` (`empresa_id`,`tarefa_id`,`removido_em`),
  CONSTRAINT `fk_resp_tarefa` FOREIGN KEY (`empresa_id`, `tarefa_id`) REFERENCES `tarefas` (`empresa_id`, `id`) ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT `fk_resp_usuario` FOREIGN KEY (`empresa_id`, `usuario_id`) REFERENCES `usuarios` (`empresa_id`, `id`) ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT `fk_resp_atribuidor` FOREIGN KEY (`empresa_id`, `atribuido_por`) REFERENCES `usuarios` (`empresa_id`, `id`) ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT `fk_resp_removedor` FOREIGN KEY (`empresa_id`, `removido_por`) REFERENCES `usuarios` (`empresa_id`, `id`) ON UPDATE RESTRICT ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Tabela: tarefa_progresso_historico
CREATE TABLE IF NOT EXISTS `tarefa_progresso_historico` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `empresa_id` BIGINT UNSIGNED NOT NULL,
  `tarefa_id` BIGINT UNSIGNED NOT NULL,
  `usuario_id` BIGINT UNSIGNED NOT NULL,
  `progresso_anterior` TINYINT UNSIGNED NOT NULL,
  `progresso_novo` TINYINT UNSIGNED NOT NULL,
  `justificativa` VARCHAR(255) NULL,
  `origem_alteracao` ENUM('usuario','devolucao_administrativa') NOT NULL DEFAULT 'usuario',
  `criado_em` DATETIME NOT NULL,
  PRIMARY KEY (`id`),
  KEY `ix_prog_tarefa` (`empresa_id`,`tarefa_id`,`criado_em`),
  KEY `ix_prog_usuario` (`empresa_id`,`usuario_id`,`criado_em`),
  CONSTRAINT `fk_prog_tarefa` FOREIGN KEY (`empresa_id`, `tarefa_id`) REFERENCES `tarefas` (`empresa_id`, `id`) ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT `fk_prog_usuario` FOREIGN KEY (`empresa_id`, `usuario_id`) REFERENCES `usuarios` (`empresa_id`, `id`) ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT `ck_prog_valores` CHECK (`progresso_anterior` <= 100 AND `progresso_novo` <= 100),
  CONSTRAINT `ck_prog_just` CHECK (`progresso_novo` >= `progresso_anterior` OR (`justificativa` IS NOT NULL AND CHAR_LENGTH(TRIM(`justificativa`)) > 0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Tabela: tarefa_comentarios
CREATE TABLE IF NOT EXISTS `tarefa_comentarios` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `empresa_id` BIGINT UNSIGNED NOT NULL,
  `tarefa_id` BIGINT UNSIGNED NOT NULL,
  `usuario_id` BIGINT UNSIGNED NOT NULL,
  `conteudo` VARCHAR(500) NOT NULL,
  `criado_em` DATETIME NOT NULL,
  PRIMARY KEY (`id`),
  KEY `ix_com_tarefa` (`empresa_id`,`tarefa_id`,`criado_em`),
  CONSTRAINT `fk_com_tarefa` FOREIGN KEY (`empresa_id`, `tarefa_id`) REFERENCES `tarefas` (`empresa_id`, `id`) ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT `fk_com_usuario` FOREIGN KEY (`empresa_id`, `usuario_id`) REFERENCES `usuarios` (`empresa_id`, `id`) ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT `ck_com_texto` CHECK (CHAR_LENGTH(TRIM(`conteudo`)) > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Tabela: tarefa_anexos
CREATE TABLE IF NOT EXISTS `tarefa_anexos` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `empresa_id` BIGINT UNSIGNED NOT NULL,
  `tarefa_id` BIGINT UNSIGNED NOT NULL,
  `enviado_por` BIGINT UNSIGNED NOT NULL,
  `nome_original` VARCHAR(255) NOT NULL,
  `nome_armazenado` VARCHAR(255) NOT NULL,
  `caminho_arquivo` VARCHAR(500) NOT NULL,
  `tipo_mime` VARCHAR(150) NOT NULL,
  `tamanho_bytes` BIGINT UNSIGNED NOT NULL,
  `hash_arquivo` CHAR(64) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  `criado_em` DATETIME NOT NULL,
  `excluido_em` DATETIME NULL,
  `excluido_por` BIGINT UNSIGNED NULL,
  `exclusao_prevista_em` DATETIME NULL,
  `eliminado_em` DATETIME NULL,
  `recuperado_em` DATETIME NULL,
  `recuperado_por` BIGINT UNSIGNED NULL,
  `status` ENUM('ativo','excluido','eliminado') NOT NULL DEFAULT 'ativo',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_anexo_nome` (`nome_armazenado`),
  KEY `ix_anexo_tarefa_status` (`empresa_id`,`tarefa_id`,`status`),
  KEY `ix_anexo_exp` (`status`,`exclusao_prevista_em`),
  CONSTRAINT `fk_anexo_tarefa` FOREIGN KEY (`empresa_id`, `tarefa_id`) REFERENCES `tarefas` (`empresa_id`, `id`) ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT `fk_anexo_enviador` FOREIGN KEY (`empresa_id`, `enviado_por`) REFERENCES `usuarios` (`empresa_id`, `id`) ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT `fk_anexo_excluidor` FOREIGN KEY (`empresa_id`, `excluido_por`) REFERENCES `usuarios` (`empresa_id`, `id`) ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT `fk_anexo_recuperador` FOREIGN KEY (`empresa_id`, `recuperado_por`) REFERENCES `usuarios` (`empresa_id`, `id`) ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT `ck_anexo_tamanho` CHECK (`tamanho_bytes` > 0 AND `tamanho_bytes` <= 20971520)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Tabela: tarefa_aprovacoes
CREATE TABLE IF NOT EXISTS `tarefa_aprovacoes` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `empresa_id` BIGINT UNSIGNED NOT NULL,
  `tarefa_id` BIGINT UNSIGNED NOT NULL,
  `ciclo_aprovacao` INT UNSIGNED NOT NULL,
  `enviado_por` BIGINT UNSIGNED NOT NULL,
  `enviado_em` DATETIME NOT NULL,
  `administrador_id` BIGINT UNSIGNED NOT NULL,
  `decisao` ENUM('aprovada','devolvida') NOT NULL,
  `justificativa` VARCHAR(255) NULL,
  `progresso_apos_devolucao` TINYINT UNSIGNED NULL,
  `criado_em` DATETIME NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_aprov_ciclo` (`empresa_id`,`tarefa_id`,`ciclo_aprovacao`),
  KEY `ix_aprov_admin` (`empresa_id`,`administrador_id`,`criado_em`),
  CONSTRAINT `fk_aprov_tarefa` FOREIGN KEY (`empresa_id`, `tarefa_id`) REFERENCES `tarefas` (`empresa_id`, `id`) ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT `fk_aprov_enviador` FOREIGN KEY (`empresa_id`, `enviado_por`) REFERENCES `usuarios` (`empresa_id`, `id`) ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT `fk_aprov_admin` FOREIGN KEY (`empresa_id`, `administrador_id`) REFERENCES `usuarios` (`empresa_id`, `id`) ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT `ck_aprov_ciclo` CHECK (`ciclo_aprovacao` >= 1),
  CONSTRAINT `ck_aprov_just` CHECK (`decisao` <> 'devolvida' OR (`justificativa` IS NOT NULL AND CHAR_LENGTH(TRIM(`justificativa`)) > 0)),
  CONSTRAINT `ck_aprov_prog` CHECK ((`decisao` = 'devolvida' AND `progresso_apos_devolucao` = 99) OR (`decisao` = 'aprovada' AND `progresso_apos_devolucao` IS NULL))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Tabela: notificacoes
CREATE TABLE IF NOT EXISTS `notificacoes` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `empresa_id` BIGINT UNSIGNED NOT NULL,
  `usuario_id` BIGINT UNSIGNED NOT NULL,
  `tipo` VARCHAR(60) NOT NULL,
  `titulo` VARCHAR(200) NOT NULL,
  `mensagem` TEXT NOT NULL,
  `tarefa_id` BIGINT UNSIGNED NULL,
  `criado_em` DATETIME NOT NULL,
  `lido_em` DATETIME NULL,
  `chave_deduplicacao` VARCHAR(191) NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_not_dedup` (`empresa_id`,`usuario_id`,`chave_deduplicacao`),
  KEY `ix_not_usuario` (`empresa_id`,`usuario_id`,`lido_em`,`criado_em`),
  KEY `ix_not_criado` (`criado_em`),
  KEY `ix_not_tarefa` (`empresa_id`,`tarefa_id`),
  CONSTRAINT `fk_not_usuario` FOREIGN KEY (`empresa_id`, `usuario_id`) REFERENCES `usuarios` (`empresa_id`, `id`) ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT `fk_not_tarefa` FOREIGN KEY (`empresa_id`, `tarefa_id`) REFERENCES `tarefas` (`empresa_id`, `id`) ON UPDATE RESTRICT ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Tabela: preferencias_notificacao
CREATE TABLE IF NOT EXISTS `preferencias_notificacao` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `empresa_id` BIGINT UNSIGNED NOT NULL,
  `usuario_id` BIGINT UNSIGNED NOT NULL,
  `categoria` VARCHAR(60) NOT NULL,
  `email_ativo` BOOLEAN NOT NULL DEFAULT TRUE,
  `criado_em` DATETIME NOT NULL,
  `atualizado_em` DATETIME NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_pref_categoria` (`empresa_id`,`usuario_id`,`categoria`),
  KEY `ix_pref_empresa_cat` (`empresa_id`,`categoria`),
  CONSTRAINT `fk_pref_usuario` FOREIGN KEY (`empresa_id`, `usuario_id`) REFERENCES `usuarios` (`empresa_id`, `id`) ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT `ck_pref_bool` CHECK (`email_ativo` IN (0,1))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Tabela: tarefa_lembretes
CREATE TABLE IF NOT EXISTS `tarefa_lembretes` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `empresa_id` BIGINT UNSIGNED NOT NULL,
  `tarefa_id` BIGINT UNSIGNED NOT NULL,
  `antecedencia_minutos` INT UNSIGNED NOT NULL,
  `criado_por` BIGINT UNSIGNED NOT NULL,
  `criado_em` DATETIME NOT NULL,
  `atualizado_em` DATETIME NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_lem_prazo` (`empresa_id`,`tarefa_id`,`antecedencia_minutos`),
  KEY `ix_lem_tarefa` (`empresa_id`,`tarefa_id`),
  CONSTRAINT `fk_lem_tarefa` FOREIGN KEY (`empresa_id`, `tarefa_id`) REFERENCES `tarefas` (`empresa_id`, `id`) ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT `fk_lem_criador` FOREIGN KEY (`empresa_id`, `criado_por`) REFERENCES `usuarios` (`empresa_id`, `id`) ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT `ck_lem_minutos` CHECK (`antecedencia_minutos` IN (60,1440,2880,10080))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Tabela: envios_email
CREATE TABLE IF NOT EXISTS `envios_email` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `empresa_id` BIGINT UNSIGNED NULL,
  `usuario_id` BIGINT UNSIGNED NULL,
  `destinatario_email` VARCHAR(254) NOT NULL,
  `categoria` VARCHAR(60) NOT NULL,
  `assunto` VARCHAR(255) NOT NULL,
  `status` ENUM('pendente','processando','enviado','falhou','cancelado') NOT NULL DEFAULT 'pendente',
  `tentativas` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `proxima_tentativa_em` DATETIME NULL,
  `criado_em` DATETIME NOT NULL,
  `enviado_em` DATETIME NULL,
  `ultimo_erro_codigo` VARCHAR(100) NULL,
  `ultimo_erro_em` DATETIME NULL,
  `identificador_provedor` VARCHAR(191) NULL,
  `chave_idempotencia` VARCHAR(191) NULL,
  `bloqueado_ate` DATETIME NULL,
  `bloqueio_token` CHAR(36) NULL,
  `referencia_tipo` VARCHAR(60) NULL,
  `referencia_id` BIGINT UNSIGNED NULL,
  `expira_em` DATETIME NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_email_idemp` (`chave_idempotencia`),
  KEY `ix_email_pendente` (`status`,`proxima_tentativa_em`),
  KEY `ix_email_lock` (`status`,`bloqueado_ate`),
  KEY `ix_email_empresa` (`empresa_id`,`criado_em`),
  KEY `ix_email_usuario` (`usuario_id`,`criado_em`),
  CONSTRAINT `fk_email_empresa` FOREIGN KEY (`empresa_id`) REFERENCES `empresas` (`id`) ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT `fk_email_usuario` FOREIGN KEY (`empresa_id`, `usuario_id`) REFERENCES `usuarios` (`empresa_id`, `id`) ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT `ck_email_tenant` CHECK (`usuario_id` IS NULL OR `empresa_id` IS NOT NULL)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Tabela: logs_auditoria
CREATE TABLE IF NOT EXISTS `logs_auditoria` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `empresa_id` BIGINT UNSIGNED NULL,
  `usuario_id` BIGINT UNSIGNED NULL,
  `acao` VARCHAR(100) NOT NULL,
  `entidade` VARCHAR(100) NOT NULL,
  `registro_id` BIGINT UNSIGNED NULL,
  `dados_anteriores` JSON NULL,
  `dados_novos` JSON NULL,
  `endereco_ip` VARBINARY(16) NULL,
  `user_agent` VARCHAR(512) NULL,
  `criado_em` DATETIME NOT NULL,
  `origem` ENUM('usuario','sistema','integracao') NOT NULL,
  `resultado` ENUM('sucesso','falha') NOT NULL,
  PRIMARY KEY (`id`),
  KEY `ix_log_empresa` (`empresa_id`,`criado_em`),
  KEY `ix_log_usuario` (`empresa_id`,`usuario_id`,`criado_em`),
  KEY `ix_log_entidade` (`empresa_id`,`entidade`,`registro_id`),
  KEY `ix_log_acao` (`acao`,`criado_em`),
  CONSTRAINT `fk_log_empresa` FOREIGN KEY (`empresa_id`) REFERENCES `empresas` (`id`) ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT `fk_log_usuario` FOREIGN KEY (`empresa_id`, `usuario_id`) REFERENCES `usuarios` (`empresa_id`, `id`) ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT `ck_log_tenant` CHECK (`usuario_id` IS NULL OR `empresa_id` IS NOT NULL)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Tabela: solicitacoes_exclusao_empresa
CREATE TABLE IF NOT EXISTS `solicitacoes_exclusao_empresa` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `empresa_id` BIGINT UNSIGNED NOT NULL,
  `solicitado_por` BIGINT UNSIGNED NOT NULL,
  `status` ENUM('pendente','cancelada','concluida') NOT NULL DEFAULT 'pendente',
  `solicitado_em` DATETIME NOT NULL,
  `exclusao_prevista_em` DATETIME NOT NULL,
  `cancelado_em` DATETIME NULL,
  `cancelado_por` BIGINT UNSIGNED NULL,
  `concluido_em` DATETIME NULL,
  `estados_anteriores` JSON NOT NULL,
  `etapa_processamento` VARCHAR(50) NULL,
  `ultima_tentativa_em` DATETIME NULL,
  `empresa_exclusao_pendente_unica` BIGINT UNSIGNED GENERATED ALWAYS AS (CASE WHEN `status` = 'pendente' THEN `empresa_id` ELSE NULL END) PERSISTENT,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_exc_empresa_id` (`empresa_id`,`id`),
  UNIQUE KEY `uq_exc_pendente` (`empresa_exclusao_pendente_unica`),
  KEY `ix_exc_vencidas` (`status`,`exclusao_prevista_em`),
  KEY `ix_exc_historico` (`empresa_id`,`solicitado_em`),
  CONSTRAINT `fk_exc_solicitante` FOREIGN KEY (`empresa_id`, `solicitado_por`) REFERENCES `usuarios` (`empresa_id`, `id`) ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT `fk_exc_cancelador` FOREIGN KEY (`empresa_id`, `cancelado_por`) REFERENCES `usuarios` (`empresa_id`, `id`) ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT `ck_exc_prazo` CHECK (`exclusao_prevista_em` > `solicitado_em`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Tabela: tokens_cancelamento_exclusao
CREATE TABLE IF NOT EXISTS `tokens_cancelamento_exclusao` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `empresa_id` BIGINT UNSIGNED NOT NULL,
  `solicitacao_id` BIGINT UNSIGNED NOT NULL,
  `token_hash` CHAR(64) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  `criado_em` DATETIME NOT NULL,
  `expira_em` DATETIME NOT NULL,
  `utilizado_em` DATETIME NULL,
  `revogado_em` DATETIME NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_tokexc_hash` (`token_hash`),
  KEY `ix_tokexc_solicitacao` (`empresa_id`,`solicitacao_id`),
  KEY `ix_tokexc_exp` (`expira_em`),
  CONSTRAINT `fk_tokexc_solicitacao` FOREIGN KEY (`empresa_id`, `solicitacao_id`) REFERENCES `solicitacoes_exclusao_empresa` (`empresa_id`, `id`) ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT `ck_tokexc_datas` CHECK (`expira_em` > `criado_em`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Tabela: rascunhos_formularios
CREATE TABLE IF NOT EXISTS `rascunhos_formularios` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `empresa_id` BIGINT UNSIGNED NOT NULL,
  `usuario_id` BIGINT UNSIGNED NOT NULL,
  `tipo_formulario` VARCHAR(50) NOT NULL,
  `registro_id` BIGINT UNSIGNED NULL,
  `dados` JSON NOT NULL,
  `versao_original` BIGINT UNSIGNED NULL,
  `dados_originais` JSON NULL,
  `criado_em` DATETIME NOT NULL,
  `atualizado_em` DATETIME NOT NULL,
  `expira_em` DATETIME NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_rasc_unico` (`empresa_id`,`usuario_id`,`tipo_formulario`),
  KEY `ix_rasc_exp` (`expira_em`),
  KEY `ix_rasc_usuario` (`empresa_id`,`usuario_id`,`atualizado_em`),
  CONSTRAINT `fk_rasc_usuario` FOREIGN KEY (`empresa_id`, `usuario_id`) REFERENCES `usuarios` (`empresa_id`, `id`) ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT `ck_rasc_datas` CHECK (`expira_em` > `criado_em`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


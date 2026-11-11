# TaskCloud — Etapa 1: HTML

Estrutura HTML5 local de um sistema acadêmico de gestão de tarefas. Todos os nomes, empresas, e-mails e registros são fictícios. Esta entrega inclui somente HTML e documentação, sem CSS, JavaScript, PHP ou MySQL.

## Como visualizar no Windows

1. Extraia a pasta taskcloud.
2. Abra index.html no navegador (clique duplo), ou abra a pasta no VS Code e use a extensão Live Server, se já estiver instalada.
3. Clique em “Explorar o painel demonstrativo” e navegue pelo menu.

Opcional com XAMPP: copie a pasta para C:\xampp\htdocs\taskcloud, inicie Apache e acesse http://localhost/taskcloud/. PHP e MySQL não são necessários nesta etapa.

## Arquivos

- index.html: login e acesso ao painel demonstrativo.
- painel.html: indicadores e tarefas recentes.
- perfil.html: perfil, tarefas individuais e histórico.
- funcionarios.html: listagem de usuários.
- funcionario-cadastro.html: formulário de cadastro de funcionário.
- tarefa-cadastro.html: formulário de criação e atribuição.
- tarefas.html: filtros e tabela de tarefas.
- tarefa-detalhes.html: detalhes, histórico, edição, conclusão e atualização de progresso.
- progresso.html: acompanhamento da equipe.

## Estrutura e integração futura

Idioma pt-BR, viewport, landmarks, títulos, labels, tabelas com cabeçalhos e barras nativas progress. O menu usa a classe menu-lateral para estilização futura; neste momento segue o fluxo padrão do navegador. A identidade visual, a onça original, o tema preto/amarelo e a adaptação responsiva completa pertencem à etapa CSS, após autorização.

Campos seguem nomes consistentes: email, senha, nome, cargo, perfil, ativo, titulo, descricao, responsavel_id, prazo_entrega, prioridade, status, porcentagem_conclusao e tarefa_id. Valores de perfis: administrador, gestor, funcionario. Status: pendente, em_andamento, concluida. Prioridade: baixa, media, alta.

Formulários POST estão em fieldsets desativados para evitar o envio de senhas ou dados nesta demonstração estática. Os filtros também são somente estrutura demonstrativa; não processam consultas. Não existe login real, persistência ou edição de registros. Links para detalhes usam âncoras para os três exemplos.

Na etapa PHP, habilitar os formulários com endpoints, CSRF e validação no servidor. Empresa, criador e atribuidor devem ser derivados da sessão e de regras autorizadas no servidor, nunca confiados a campos enviados pelo navegador. Restringir os dados à empresa autenticada e as ações ao perfil do usuário. Validar a coerência entre status e porcentagem (concluída = 100%) e registrar conclusões com usuário e data. Esses controles ainda não foram implementados.

Etapas futuras dependem de autorização: CSS, depois PHP 8+, depois MySQL. Não houve implantação nem testes na AWS.

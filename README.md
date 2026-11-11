# TaskCloud — Etapa 2: CSS

Projeto acadêmico de gestão de tarefas empresariais. A Etapa 1 (HTML) foi aprovada e testada localmente pelo autor no VS Code com Live Server. A Etapa 2 acrescenta a identidade visual em CSS às mesmas nove páginas.

Todos os nomes, empresas, e-mails e registros são fictícios. Os dados e o comportamento demonstrativo foram preservados. Não há JavaScript, PHP, MySQL, login real ou persistência nesta entrega.

## Visualizar no Windows

1. Abra a pasta completa do projeto no VS Code, incluindo a pasta `assets`.
2. Clique com o botão direito em `index.html` e selecione **Open with Live Server**.
3. Clique em **Explorar o painel demonstrativo** para navegar pelo sistema.

Também é possível abrir `index.html` diretamente no navegador. Não é necessário instalar bibliotecas, compilar arquivos nem estar conectado à internet para carregar o tema, a tipografia do sistema e a marca.

Opcional com XAMPP: copie a pasta para `C:\xampp\htdocs\taskcloud`, inicie o Apache e acesse `http://localhost/taskcloud/`. PHP e MySQL não são necessários nesta etapa.

## Atualizar a partir do GitHub

A implementação da Etapa 2 está na branch `etapa-2-css`, preparada para revisão em pull request.

Se a pasta local foi clonada com Git, confira primeiro se há alterações suas e salve-as antes de trocar de branch. No terminal do VS Code, dentro da pasta do projeto:

```bash
git status
git fetch origin
git switch --track origin/etapa-2-css
```

Se a branch já existir localmente, use `git switch etapa-2-css` e depois `git pull --ff-only`.

Após a aprovação e a integração do pull request no GitHub, a versão também estará na `main`: `git switch main` e `git pull --ff-only`.

Se a pasta local veio de um ZIP, abra a branch `etapa-2-css` no GitHub e selecione **Code → Download ZIP**. Extraia em outra pasta para preservar sua cópia anterior e abra a nova pasta no VS Code.

Se o navegador ainda mostrar a versão antiga, recarregue com `Ctrl + F5`.

## Arquivos

- `index.html`: login centralizado e acesso ao painel demonstrativo.
- `painel.html`: indicadores em cards e tarefas recentes.
- `perfil.html`: perfil, tarefas individuais e histórico.
- `funcionarios.html`: listagem de usuários.
- `funcionario-cadastro.html`: formulário de cadastro de funcionário.
- `tarefa-cadastro.html`: formulário de criação e atribuição.
- `tarefas.html`: estrutura de filtros e tabela de tarefas.
- `tarefa-detalhes.html`: detalhes, histórico, edição, conclusão e atualização de progresso.
- `progresso.html`: acompanhamento da equipe.
- `assets/css/style.css`: tema, estrutura, componentes, formulários, login, acessibilidade e regras responsivas.
- `assets/img/onca-taskcloud.svg`: emblema original em vetor da onça TaskCloud, também utilizado como favicon.

## Identidade visual

Tema grafite/preto com amarelo principal. Pendências usam amarelo, tarefas em andamento usam azul e conclusões usam verde, sempre acompanhadas de texto. Prioridades alta, média e baixa têm etiquetas próprias. As barras usam os valores originais de `<progress>` e mantêm as porcentagens em texto.

O menu é lateral no computador. Em telas de até 800px, passa para uma faixa horizontal com rolagem, acessível por toque e teclado, sem menu dependente de JavaScript. As tabelas têm rolagem horizontal independente para preservar todas as colunas. Os formulários passam de duas colunas para uma em telas pequenas. O login tem composição centralizada e navegação secundária própria.

A tipografia usa uma pilha local: Inter (quando instalada), Segoe UI, Roboto, Helvetica e Arial. Não existe download de fontes ou rastreamento externo. As cores e dimensões principais podem ser ajustadas nas variáveis `:root` do CSS.

## O que mudou no HTML

As nove páginas foram mantidas. Foram acrescentados os links de CSS/favicon, a imagem da marca, classes de apresentação, agrupamentos dos indicadores, etiquetas em células e regiões de rolagem ao redor das tabelas. O rodapé identifica a Etapa 2. Conteúdo demonstrativo, IDs existentes, links de navegação, atributos e valores de formulários, status, responsáveis e progresso foram preservados.

Os formulários continuam desativados por `fieldset disabled`, inclusive o botão Entrar e os filtros. O acesso demonstrativo continua disponível pelo link **Explorar o painel demonstrativo**. A estilização não habilita cadastro, pesquisa ou atualização.

## Roteiro de teste visual no Live Server

1. Abra as nove páginas pelo menu e confirme a marca e o tema em todas elas.
2. No painel, confira os quatro indicadores: total 3, pendentes 1, em andamento 1 e concluídas 1.
3. Nas tarefas, confira status/etiquetas e progresso de 60%, 0% e 100%. Os links devem abrir a tarefa correspondente e destacá-la pelo contorno.
4. Em progresso, confira a média de 53,3% e os valores individuais de 80% e 0%.
5. Redimensione a janela ou use o modo de dispositivo do navegador em 1440, 1024, 768, 390 e 320px. Confira a faixa de navegação, os formulários em uma coluna e a rolagem horizontal somente na faixa do menu e nas tabelas.
6. Navegue com Tab e Shift+Tab. Confira o link de pular ao conteúdo, o contorno de foco e o acesso à região de rolagem das tabelas com as setas do teclado.
7. Confirme que os campos e botões de envio permanecem desativados.
8. Teste zoom de 200% e, se possível, Chrome/Edge e Firefox atualizados.

### Verificação desta entrega

Foram verificados os arquivos e referências locais, links e âncoras, IDs únicos, rótulos, preservação do conteúdo e dos formulários, sintaxe CSS e SVG e ausência de erros de whitespace no diff Git. A inspeção visual em navegador deste ambiente não foi realizada: a ferramenta de navegador exigida pela infraestrutura de prévia não está disponível. O roteiro acima deve ser executado localmente para validar a aparência e a responsividade renderizada.

## Integração futura

Campos mantêm os nomes da Etapa 1: `email`, `senha`, `nome`, `cargo`, `perfil`, `ativo`, `titulo`, `descricao`, `responsavel_id`, `prazo_entrega`, `prioridade`, `status`, `porcentagem_conclusao` e `tarefa_id`.

Perfis: `administrador`, `gestor`, `funcionario`. Status: `pendente`, `em_andamento`, `concluida`. Prioridades: `baixa`, `media`, `alta`.

A Etapa 3, somente após autorização, deverá implementar PHP 8+, sessão, permissões, proteção CSRF, validação no servidor e senhas com hash. Empresa, criador e atribuidor devem ser derivados da sessão e das regras do servidor. O servidor deverá restringir dados por empresa e perfil, validar a coerência entre status e porcentagem (concluída = 100%) e registrar as conclusões com usuário e data.

A Etapa 4 será a integração com MySQL, também mediante autorização. Não houve implantação nem testes na AWS.

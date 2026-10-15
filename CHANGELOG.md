## [2.11.0] - 2026-10-15

### Estrutura
- O `trove.ahk` continua sendo o único arquivo que o usuário precisa executar.
- O script foi dividido em módulos menores, carregados automaticamente pelo arquivo principal.
- A numeração foi removida dos nomes dos arquivos da pasta `modulos`.
- A declaração `global VERSAO := "2.11.0"` permanece no `trove.ahk`, mantendo a detecção de novas versões pelos clientes instalados.

### Atualização e compatibilidade
- O atualizador agora baixa, valida, salva em backup e substitui o arquivo principal e todos os módulos da aplicação.
- Clientes da versão 2.10 que receberem apenas o novo `trove.ahk` baixam automaticamente os módulos ausentes antes de iniciar.
- A janela de patch notes, a consulta automática de versão e o atalho F2 foram preservados na estrutura modular.
- O arquivo `amigos.txt` continua fora da atualização e é criado automaticamente quando ainda não existe.

## [2.10.0] - 2026-10-15

### Novidades
- Janela de patch notes com tema escuro e histórico completo em uma área com rolagem.
- Acesso pelo menu do ícone do USFT ou pelo atalho F2.
- Consulta automática de versão na branch main de leosmsilvx/USFT ao iniciar.
- Verificação automática ao abrir o F2 e botão Atualizar habilitado quando houver uma versão mais recente.
- Versão consultada diretamente no trove.ahk publicado, sem manifesto separado.
- Instalação com confirmação, conferência do script consultado, backup e reinicio do USFT.
- Downloads em segundo plano, com limite de tempo e mensagens de erro.

### Proteções
- Instalação bloqueada enquanto o farm estiver ativo.
- amigos.txt preservado; arquivos anteriores salvos na pasta backups.
- Restauração dos arquivos anteriores em caso de falha na substituição.

## [2.9.4] - 2026-10-14

### Correções e melhorias
- Recuperação automática da janela Trove - Error Handler.
- Fechamento direcionado do jogo travado, preservando o Glyph e o AutoHotkey.
- Retomada do fluxo de abertura, carregamento e busca por ship após um crash.
- Verificação de morte durante os três minutos de validação do cronômetro.
- Alternância entre OCR de morte e cronômetro para evitar leituras simultâneas.
- Intervalo entre convites aumentado de 1,5 para 2 segundos.
- Contagem regressiva para a próxima mensagem durante a busca por ship.
- Atalhos para farm, convites e exibição do painel.

As notas da versão 2.9.4 foram extraídas do README existente. Versões anteriores
não possuem histórico detalhado neste repositorio.

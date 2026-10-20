## [1.0.5] - 2026-10-20

### Morte e safety-respawn
- A tela de morte é monitorada durante todo o farm, com leitura independente do cronômetro, inclusive quando ele continua ativo dentro de uma ship.
- Ao confirmar o renascimento, o safety-respawn envia `Ctrl+A`, aguarda 0,5 segundo e pressiona `E` para voltar ao HUB.
- A busca por ships e os convites só são retomados após detectar a transição e estabilização do mundo. Se o carregamento não for detectado em 15 segundos, o comando é tentado novamente.
- Removida a espera fixa de cinco segundos após o renascimento para iniciar o retorno ao HUB imediatamente após a confirmação de vida.

### Mensagens do chat
- Adicionadas `x ship invite me`, `x shipp`, `x shiip`, `x ship please :)`, `invite for ship pls :D` e `x need shiippp`.
- Mantida a mensagem `ship plss`, que já fazia parte da lista.

## [1.0.4] - 2026-10-15

### Recuperação de crash
- Ao concluir a reabertura do Trove, o script pressiona `Esc` para fechar a tela de Welcome.
- A primeira carga de mundo após a recuperação não envia convites aos amigos.
- Depois dessa carga, a máquina de estados retoma a busca por ship e a validação normal do mundo.

### Atualizador
- A atualização não cria mais a pasta backups ao lado do programa.
- As cópias de recuperação são temporárias e removidas após a instalação ou restauração bem-sucedida. Se a restauração falhar, o caminho da cópia temporária é informado para recuperação manual.
- O arquivo amigos.txt continua preservado.

## [1.0.3] - 2026-10-15

### Validação do cronômetro
- Cronômetro ausente retorna à busca por ship imediatamente, inclusive durante os convites e a validação inicial.
- Cronômetro visível em 00:00 aguarda até três minutos pelo início da dungeon, mantendo a validação a cada segundo.
- Se o cronômetro ficar ativo nesse período, a dungeon é confirmada; se desaparecer, a busca é retomada imediatamente.
- Ao terminar os três minutos sem um cronômetro ativo, a busca por ship é retomada também na conferência anterior ao chat.
- Um cronômetro anteriormente ativo que volta a 00:00 inicia uma nova espera de três minutos, substituindo a antiga saída após duas leituras zeradas.

## [1.0.2] - 2026-10-15

### Interface
- O aviso de atualização agora exibe `Nova versão (vX.X.X) - Aperte F2 para atualizar`.
- O aviso foi movido para a área imediatamente acima das teclas de atalho.

## [1.0.1] - 2026-10-15

### Interface
- Busca renomeada para Farm Ship e Convite renomeado para Convidar amigos.
- Atalhos exibidos como F11: Alternar Farm Ship e F10: Alternar convidar amigos.
- Indicadores reposicionados e painel ajustado para acomodar os novos textos.

### Abertura do jogo
- A confirmação do Controle de Conta de Usuário do Windows (UAC) precisa ser aceita manualmente; o script não automatiza cliques na área de trabalho protegida.

## [1.0.0] - 2026-10-15

### GRANDE NOTÍCIA!
O USFT chegou à sua primeira versão oficial: **v1.0.0**.

### Primeira versão estável
- Removida da interface in-game a contagem regressiva da pausa de 30 minutos e da validação inicial.
- Durante dungeon, convites e conferência antes do chat, o painel passa a exibir somente o resultado mais recente das validações de cronômetro feitas a cada segundo.
- Adicionado `.gitignore` para impedir o versionamento da pasta `backups` criada pelo atualizador.
- As versões experimentais anteriores foram reclassificadas como `b1.x.x`, e o comparador passou a tratá-las como anteriores à versão estável.

## [b1.12.3] - 2026-10-15

### Correções
- Corrigido o bloqueio de atualização causado pelo marcador UTF-8 invisível no início do arquivo, mesmo quando o código consultado e baixado era idêntico.
- A comparação continua recusando alterações reais no script, mas tolera diferenças de marcador UTF-8 e quebras de linha.
- Corrigida a exibição da primeira linha do changelog quando o arquivo publicado contém esse marcador.
- Arquivo principal publicado sem marcador UTF-8 para compatibilidade com o atualizador das versões beta anteriores.
- A verificação da versão no GitHub começa imediatamente ao iniciar o trove.ahk, antes do carregamento do painel.
- A consulta ao abrir o F2 continua disponível, assim como o aviso quando há uma versão mais recente.
- O painel mostra um aviso em destaque quando o GitHub tem uma versão mais nova, indicando o F2 para atualizar.

## [b1.11.0] - 2026-10-15

### Estrutura
- O `trove.ahk` continua sendo o único arquivo que o usuário precisa executar.
- O script foi dividido em módulos menores, carregados automaticamente pelo arquivo principal.
- A numeração foi removida dos nomes dos arquivos da pasta `modulos`.
- A declaração de versão permanece no `trove.ahk`, mantendo a detecção de novas versões pelos clientes instalados.

### Atualização e compatibilidade
- O atualizador agora baixa, valida, salva em backup e substitui o arquivo principal e todos os módulos da aplicação.
- Clientes da versão beta anterior que receberem apenas o novo `trove.ahk` baixam automaticamente os módulos ausentes antes de iniciar.
- A janela de patch notes, a consulta automática de versão e o atalho F2 foram preservados na estrutura modular.
- O arquivo `amigos.txt` continua fora da atualização; se já existir, é preservado sem alterações, e só é criado vazio quando estiver ausente.
- Corrigido o carregamento dos módulos no AutoHotkey v2, removendo aspas inválidas dos caminhos das diretivas `#Include`.
- Corrigidas as chamadas de inicialização que causavam os erros `Invalid base` e `global variable has not been assigned`.

## [b1.10.0] - 2026-10-15

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

## [b1.9.4] - 2026-10-14

### Correções e melhorias
- Recuperação automática da janela Trove - Error Handler.
- Fechamento direcionado do jogo travado, preservando o Glyph e o AutoHotkey.
- Retomada do fluxo de abertura, carregamento e busca por ship após um crash.
- Verificação de morte durante os três minutos de validação do cronômetro.
- Alternância entre OCR de morte e cronômetro para evitar leituras simultâneas.
- Intervalo entre convites aumentado de 1,5 para 2 segundos.
- Contagem regressiva para a próxima mensagem durante a busca por ship.
- Atalhos para farm, convites e exibição do painel.

As notas da versão b1.9.4 foram extraídas do README existente. Versões anteriores
não possuem histórico detalhado neste repositorio.

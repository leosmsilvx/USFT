# Trove AFK 1.0.5

Versão atual: **v1.0.5**. Requer Windows e AutoHotkey v2.

Execute somente **trove.ahk**.

A pasta `modulos` precisa permanecer ao lado do arquivo principal. Não mova, renomeie ou execute os módulos individualmente.

Preencha `amigos.txt` com um nome por linha. Ao atualizar uma instalação existente, preserve o seu arquivo atual de amigos.

## Morte e retorno seguro ao HUB

A tela de morte é verificada durante todo o farm, mesmo com o cronômetro da ship ativo. Ao confirmar o renascimento, o safety-respawn envia **Ctrl+A**, aguarda **0,5 segundo** e pressiona **E** para voltar ao HUB. A busca por ships só recomeça após detectar o carregamento e a estabilização do mundo. Se a transição não for detectada em 15 segundos, o comando é repetido. Mantenha os atalhos do jogo configurados para essa sequência.

## Atalhos

- **F11:** Alternar Farm Ship.
- **F10:** Alternar convidar amigos.
- **F9:** fechar o aplicativo.
- **F2:** abrir as notas da versão e verificar atualizações.
- **Ctrl + Alt + B:** exibir novamente o painel.
- **B:** ocultar o painel enquanto o Trove estiver ativo.

## Abertura do jogo e UAC

Se o Windows solicitar permissão para o Wellbia.com Security Loader ao clicar em Jogar, confirme manualmente em Sim. O AutoHotkey comum não consegue interagir com o UAC na área de trabalho protegida. Depois da confirmação e do carregamento, o fluxo de recuperação continua monitorando o Trove.

## Arquivos temporários da atualização

Na versão 1.0.4, o atualizador não cria uma pasta backups junto ao programa. As cópias necessárias para reverter uma falha ficam somente na pasta temporária da atualização e são removidas ao concluir a instalação ou a restauração. Se não for possível restaurar algum arquivo, a cópia temporária é preservada e o programa informa o caminho para recuperação manual. O arquivo amigos.txt é preservado.

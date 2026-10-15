# USFT - Trove AFK

Versao atual: **2.10.0**. Requer Windows e AutoHotkey v2.

Baixe o projeto completo e execute `trove.ahk`. O histórico é consultado no GitHub. Edite `amigos.txt` para configurar os convites; se o arquivo não existir, o programa cria um arquivo vazio sem sobrescrever uma lista existente.

| Atalho | Acao |
|---|---|
| F11 | Iniciar ou pausar o farm |
| F9 | Fechar o USFT |
| F10 | Alternar convites de amigos |
| Ctrl+Alt+B | Mostrar o painel |
| B, dentro do Trove | Ocultar o painel |
| F2 | Abrir patch notes |

## Patch notes e atualizacoes

O histórico completo é lido do CHANGELOG.md publicado na branch main do GitHub e pode ser
consultado na janela **Patch notes**, pelo atalho ou menu do icone
na bandeja do Windows. A janela segue o tema escuro do painel e mostra o historico completo em uma unica area com rolagem.

Ao abrir, o USFT le a declaracao `global VERSAO` do proprio `trove.ahk` na branch `main` de
[leosmsilvx/USFT](https://github.com/leosmsilvx/USFT). A comparacao e numerica
(major.minor.patch), sem fazer downgrade. Ao abrir o F2, consulta a versão e o histórico no GitHub. Sem internet, a automação continua funcionando;
a janela informa o erro e permite tentar novamente. Nao requer token.

Quando houver uma versao nova, o aplicativo avisa e habilita **Atualizar**.
Pause o farm e confirme a instalacao. Os dois arquivos do aplicativo sao
baixados em segundo plano. O script baixado precisa corresponder ao consultado
e o historico precisa conter as notas da versao oferecida. Se o script mudar
entre a consulta e o download, faca uma nova verificacao antes de instalar.
A consulta apenas le o arquivo remoto; nao executa seu codigo.

Antes da substituicao, os arquivos anteriores sao copiados para
`backups/<versao>-<data>-<contador>`. Depois, o aplicativo reinicia com o farm
parado. `amigos.txt` e preservado. Alteracoes manuais feitas nos arquivos
`.ahk` sao substituidas e continuam acessiveis no backup. Se a copia falhar,
o atualizador tenta restaurar os arquivos e informa qualquer falha de restauracao.
Para voltar manualmente, feche o USFT e copie os arquivos do backup para a pasta
principal. Binarios compilados nao oferecem instalacao automatica.

O histórico exibido vem do GitHub, e não do arquivo local. Para publicar novas notas, envie o CHANGELOG.md para a branch main. Reabra o F2 para recarregar. O botão Atualizar instala a versão oferecida; a consulta acontece automaticamente ao abrir a janela.

## Publicar uma versao

1. Atualize `VERSAO` em `trove.ahk` (formato `2.10.1`, por exemplo).
2. Adicione `## [2.10.1] - AAAA-MM-DD` no inicio do historico em `CHANGELOG.md`.
3. Teste as alteracoes.
4. Publique `trove.ahk` e `CHANGELOG.md`
   juntos no mesmo commit na branch `main`.

A fonte de versao e a branch main; tags e GitHub Releases nao sao consultados.
Nao e necessario gerar manifesto nem executar script de publicacao.

## Recursos do farm

- Recuperacao automatica de crashes do Trove, incluindo Error Handler.
- Reabertura pelo Glyph e retomada da busca por ship.
- Deteccao de morte durante a validacao do cronometro, com OCR alternado.
- Convites de amigos a cada 2 segundos.
- Contagem regressiva para a proxima mensagem no chat.

A recuperacao de crash e os eventos do jogo precisam ser validados em uma sessao
real do Trove.

# Trove AFK — Versão 2.9.4 by bannnnn | minusclin

## 🛡️ Recuperação automática de crashes

- Detecta a janela **`Trove - Error Handler`**, mesmo quando o processo `Trove_x64.exe` permanece aberto.
- Tenta primeiro o fechamento normal e direcionado do jogo.
- Caso o Trove continue travado por mais de cinco segundos, encerra somente o processo do jogo.
- Fecha as diferentes etapas do Error Handler sem depender de botões ou coordenadas.
- Protege o Glyph e o próprio AutoHotkey contra encerramento acidental.
- Após o fechamento, reutiliza automaticamente o fluxo de recuperação já existente:
  1. Restaura o Glyph.
  2. Inicia o Trove.
  3. Aguarda o carregamento.
  4. Confirma que o jogo está estável.
  5. Retoma a busca por ship.

## 💀 Detecção de morte durante a validação

- A morte agora também é verificada durante os três minutos de validação do cronômetro.
- Isso evita que o farm permaneça parado até o fim da validação caso o personagem morra nesse período.
- Os OCRs de morte e cronômetro são alternados, impedindo duas leituras simultâneas.

## 👥 Convites de amigos

- O intervalo entre convites foi aumentado de **1,5 para 2 segundos**.
- A alteração evita o bloqueio temporário do jogo causado por convites enviados muito rapidamente.
- Os nomes continuam sendo carregados do arquivo `amigos.txt`.
- O <kbd>F10</kbd> alterna os convites entre ligados e desligados.

## ⌨️ Novos atalhos

| Tecla | Ação |
|---|---|
| <kbd>F11</kbd> | Iniciar o farm |
| <kbd>F9</kbd> | Parar o farm |
| <kbd>F10</kbd> | Ativar ou desativar os convites de amigos |
| <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>B</kbd> | Exibir novamente o painel |
| <kbd>B</kbd> | Ocultar o painel enquanto o Trove estiver ativo |

## ⏱️ Próxima mensagem

Enquanto o estado estiver em **“Procurando ship”**, o painel passa a exibir uma contagem regressiva:

```text
Próxima msg: MM:SS
```

O contador indica quanto tempo falta para o próximo envio no chat.

## ✅ Validação

- Desenvolvida diretamente sobre a versão **2.9.3**.
- Validada com o interpretador **AutoHotkey v2**.
- Sintaxe e inicialização verificadas sem erros.
- O arquivo original utilizado como base não foi sobrescrito.

> [!IMPORTANT]
> A recuperação de um crash real deve ser validada em jogo antes da publicação definitiva, pois o teste automatizado não força o encerramento de uma sessão ativa do Trove.
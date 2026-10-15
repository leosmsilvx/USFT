; ===== CRONOMETRO: VALIDACOES A CADA 1s =====

CancelarLeituraCronometro() {
    global processoOCR, resultadoOCR

    if (processoOCR && ProcessExist(processoOCR)) {
        try ProcessClose(processoOCR)
    }
    if (resultadoOCR != "" && FileExist(resultadoOCR)) {
        try FileDelete(resultadoOCR)
    }
    processoOCR := 0
    resultadoOCR := ""
}

SuspenderCronometro() {
    global inicioSemFocoCronometro

    if (inicioSemFocoCronometro = 0) {
        inicioSemFocoCronometro := A_TickCount
        ; Descarta apenas a leitura em andamento, que poderia capturar outra janela.
        CancelarLeituraCronometro()
    }
}

RetomarCronometro() {
    global inicioSemFocoCronometro, ultimaLeituraCronometro
    global inicioValidacaoCronometro

    if (inicioSemFocoCronometro != 0) {
        ; O tempo fora do jogo nao avanca o intervalo entre as verificacoes.
        ultimaLeituraCronometro += A_TickCount - inicioSemFocoCronometro
        inicioValidacaoCronometro += A_TickCount - inicioSemFocoCronometro
        inicioSemFocoCronometro := 0
    }
}

ReiniciarCronometro() {
    global ultimaLeituraCronometro, leiturasInvalidas, cronometroConfirmado
    global ultimaLeituraPainel, inicioSemFocoCronometro
    global inicioValidacaoCronometro

    CancelarLeituraCronometro()
    inicioSemFocoCronometro := 0
    ultimaLeituraCronometro := A_TickCount
    inicioValidacaoCronometro := A_TickCount
    leiturasInvalidas := 0
    cronometroConfirmado := false
    ultimaLeituraPainel := "Aguardando primeira verificacao"
}

VerificarCronometro() {
    global ultimaLeituraCronometro, leiturasInvalidas, cronometroConfirmado
    global processoOCR, resultadoOCR, INTERVALO_CRONOMETRO
    global CRONOMETRO_X, CRONOMETRO_Y, CRONOMETRO_W, CRONOMETRO_H
    global processoMorte
    global estado, INTERVALO_CRONOMETRO_ATIVO, motivoRetornoCronometro, LIMITE_CONFIRMACOES_ZERO
    global fimPausa, PAUSA_DUNGEON, ultimoPulo
    global inicioValidacaoCronometro, TEMPO_VALIDACAO_CRONOMETRO, validacaoAntesChat

    if (cronometroConfirmado && estado != "DUNGEON")
        return false

    if (processoOCR) {
        ; Leitura em processo separado: nao bloqueia a tecla de pausar.
        if ProcessExist(processoOCR) {
            if (A_TickCount - ultimaLeituraCronometro > 10000) {
                CancelarLeituraCronometro()
                ultimaLeituraCronometro := A_TickCount
                RegistrarErro("OCR", "Leitura demorou mais de 10 segundos. Tentando novamente.")
            }
            return false
        }

        leitura := "ERRO"
        try {
            leitura := Trim(FileRead(resultadoOCR, "UTF-8"))
            FileDelete(resultadoOCR)
        }
        processoOCR := 0
        resultadoOCR := ""

        ; Uma troca rapida de janela pode ser detectada pelo leitor antes do monitor.
        if (leitura = "SEM_FOCO")
            return false

        if (leitura = "ATIVO") {
            LimparErro("OCR")
            RegistrarLeitura("Cronometro ativo confirmado")
            cronometroConfirmado := true
            leiturasInvalidas := 0
            if (estado = "VERIFICANDO_DUNGEON") {
                estado := "DUNGEON"
                ultimoPulo := A_TickCount
            }
            if (fimPausa = 0)
                fimPausa := A_TickCount + PAUSA_DUNGEON
            validacaoAntesChat := 0
            AtualizarPainel()
            return false
        }
        if (leitura = "ZERO" || leitura = "AUSENTE") {
            LimparErro("OCR")
            RegistrarLeitura(leitura = "ZERO" ? "Cronometro zerado" : "Cronometro ausente")
            if (estado = "VERIFICANDO_DUNGEON") {
                RetomarBuscaShip("SEM DUNGEON 5-STAR ATIVA - PROCURANDO SHIP")
                validacaoAntesChat := A_TickCount
                return false
            }
            if (cronometroConfirmado) {
                if (leitura = "AUSENTE") {
                    motivoRetornoCronometro := "CRONOMETRO AUSENTE - PROCURANDO SHIP"
                    return true
                }
                ; Somente 00:00 exige duas confirmacoes consecutivas.
                leiturasInvalidas += 1
                if (leiturasInvalidas >= LIMITE_CONFIRMACOES_ZERO) {
                    motivoRetornoCronometro := "CRONOMETRO ZERADO CONFIRMADO 2X - PROCURANDO SHIP"
                    return true
                }
                return false
            }
            leiturasInvalidas += 1
        } else {
            leiturasInvalidas := 0
            RegistrarErro("OCR", leitura = "ILEGIVEL"
                ? "Cronometro visivel, mas o tempo esta ilegivel. Aguardando nova leitura."
                : "Falha ao ler o cronometro. Contagem reiniciada.")
        }
    }

    if (!cronometroConfirmado && (estado = "DUNGEON" || estado = "CONVIDANDO")
        && A_TickCount - inicioValidacaoCronometro >= TEMPO_VALIDACAO_CRONOMETRO) {
        motivoRetornoCronometro := "3 MIN SEM CRONOMETRO ATIVO - PROCURANDO SHIP"
        return true
    }

    intervalo := cronometroConfirmado ? INTERVALO_CRONOMETRO_ATIVO : INTERVALO_CRONOMETRO
    if (processoMorte || A_TickCount - ultimaLeituraCronometro < intervalo)
        return false

    ultimaLeituraCronometro := A_TickCount
    etapaOCR := "localizar a janela do Trove"
    try {
        WinGetClientPos(&x, &y, &w, &h, "ahk_exe Trove_x64.exe")
        resultadoOCR := A_Temp "\trove-cronometro-" ProcessExist() "-" A_TickCount ".txt"
        etapaOCR := "montar o leitor OCR"
        modoOCR := estado = "VERIFICANDO_DUNGEON" ? "ENTRADA" : "TIMER"
        codigo := "$Mode='" modoOCR "';$X=" Round(x + w * CRONOMETRO_X) ";$Y=" Round(y + h * CRONOMETRO_Y)
            . ";$Width=" Round(w * CRONOMETRO_W) ";$Height=" Round(h * CRONOMETRO_H)
            . ";$OutputPath='" StrReplace(resultadoOCR, "'", "''") "';`n" CodigoOCR()
        aspas := Chr(34)
        etapaOCR := "codificar o leitor OCR"
        codigoCodificado := CodificarPowerShell(codigo)
        comando := aspas A_WinDir "\System32\WindowsPowerShell\v1.0\powershell.exe" aspas
            . " -NoProfile -NonInteractive -EncodedCommand " codigoCodificado
        etapaOCR := "iniciar o PowerShell"
        Run(comando, A_ScriptDir, "Hide", &processoOCR)
    } catch Error as erro {
        processoOCR := 0
        leiturasInvalidas := 0
        diagnostico := "Etapa: " etapaOCR "`nErro: " erro.Message "`nOrigem: " erro.What
            . "`nLinha: " erro.Line "`nDetalhe: " erro.Extra
        try FileAppend(FormatTime(, "yyyy-MM-dd HH:mm:ss") "`n" diagnostico "`n`n",
            A_Temp "\trove-ocr-erros.log", "UTF-8")
        RegistrarErro("OCR", "Falha ao " etapaOCR ": " SubStr(erro.Message, 1, 180))
    }
    return false
}

; O leitor fica neste AHK: nenhum arquivo .ps1 e criado ou carregado.
CodificarPowerShell(codigo) {
    ; StrPut ja retorna BYTES, incluindo o terminador de dois bytes.
    dados := Buffer(StrPut(codigo, "UTF-16"), 0)
    bytesEscritos := StrPut(codigo, dados, "UTF-16")
    caracteres := 0
    if !DllCall("Crypt32\CryptBinaryToStringW", "Ptr", dados, "UInt", bytesEscritos - 2,
        "UInt", 0x40000001, "Ptr", 0, "UInt*", &caracteres)
        throw Error("Falha ao preparar OCR")
    saida := Buffer(caracteres * 2, 0)
    if !DllCall("Crypt32\CryptBinaryToStringW", "Ptr", dados, "UInt", bytesEscritos - 2,
        "UInt", 0x40000001, "Ptr", saida, "UInt*", &caracteres)
        throw Error("Falha ao preparar OCR")
    return StrGet(saida, "UTF-16")
}


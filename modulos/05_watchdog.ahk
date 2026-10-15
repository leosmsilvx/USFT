; ===== WATCHDOG DE CRASH =====

ReiniciarWatchdog() {
    global inicioAusenciaTrove, aguardandoBootTrove, inicioBootTrove
    global inicioFocoTrove, ultimaTentativaGlyph, watchdogExecutando, geracaoWatchdog
    global inicioErrorHandler, recuperandoErrorHandler, inicioFechamentoTrove

    ; A geracao invalida uma tentativa interrompida pela alternancia do farm.
    geracaoWatchdog += 1
    inicioAusenciaTrove := 0
    aguardandoBootTrove := false
    inicioBootTrove := 0
    inicioFocoTrove := 0
    ultimaTentativaGlyph := 0
    watchdogExecutando := false
    inicioErrorHandler := 0
    recuperandoErrorHandler := false
    inicioFechamentoTrove := 0
    LimparErro("WATCHDOG")
}

VerificarCrashTrove() {
    global ativo, inicioAusenciaTrove, aguardandoBootTrove, inicioBootTrove
    global inicioFocoTrove, ultimaTentativaGlyph, watchdogExecutando, geracaoWatchdog
    global CONFIRMACAO_CRASH, ESPERA_BOOT_TROVE, CONFIRMACAO_BOOT_TROVE
    global INTERVALO_RETENTATIVA_GLYPH

    agora := A_TickCount
    geracaoAtual := geracaoWatchdog

    ; O processo do jogo pode continuar vivo depois do crash.
    if VerificarErrorHandler(agora)
        return true

    if ProcessExist("Trove_x64.exe") {
        inicioAusenciaTrove := 0
        if (!aguardandoBootTrove)
            return false

        ; O processo pode existir antes de sua janela estar pronta.
        if WinExist("ahk_exe Trove_x64.exe") {
            try {
                WinRestore("ahk_exe Trove_x64.exe")
                WinActivate("ahk_exe Trove_x64.exe")
            }

            if WinActive("ahk_exe Trove_x64.exe") {
                if (inicioFocoTrove = 0)
                    inicioFocoTrove := agora
                if (agora - inicioFocoTrove >= CONFIRMACAO_BOOT_TROVE) {
                    Critical("On")
                    if (!ativo || geracaoAtual != geracaoWatchdog) {
                        Critical("Off")
                        return true
                    }
                    aguardandoBootTrove := false
                    inicioBootTrove := 0
                    inicioFocoTrove := 0
                    ultimaTentativaGlyph := 0
                    LimparErro("WATCHDOG")
                    ReiniciarMorte()
                    RetomarBuscaShip("TROVE REABERTO - PROCURANDO SHIP")
                    Critical("Off")
                    return false
                }
            } else {
                inicioFocoTrove := 0
            }
        }

        if (inicioBootTrove != 0 && agora - inicioBootTrove >= ESPERA_BOOT_TROVE)
            RegistrarErro("WATCHDOG", "Trove abriu, mas nao ficou pronto em 120 segundos.")
        return true
    }

    inicioFocoTrove := 0
    SuspenderCronometro()
    CancelarLeituraMorte()

    if (aguardandoBootTrove) {
        if (agora - inicioBootTrove < ESPERA_BOOT_TROVE)
            return true
        aguardandoBootTrove := false
        inicioBootTrove := 0
        inicioAusenciaTrove := agora
        RegistrarErro("WATCHDOG", "Trove nao iniciou em 120 segundos. Nova tentativa sera feita.")
        return true
    }

    if (inicioAusenciaTrove = 0) {
        inicioAusenciaTrove := agora
        return true
    }
    if (agora - inicioAusenciaTrove < CONFIRMACAO_CRASH)
        return true
    if (watchdogExecutando)
        return true
    if (ultimaTentativaGlyph != 0
        && agora - ultimaTentativaGlyph < INTERVALO_RETENTATIVA_GLYPH)
        return true

    watchdogExecutando := true
    geracaoTentativa := geracaoWatchdog
    sucesso := false
    try {
        sucesso := AbrirTrovePeloGlyph()
    } finally {
        watchdogExecutando := false
    }

    ; Se F11 mudou o ciclo durante a tentativa, descarta o resultado antigo.
    Critical("On")
    if (!ativo || geracaoTentativa != geracaoWatchdog) {
        Critical("Off")
        return true
    }

    ultimaTentativaGlyph := A_TickCount
    if (sucesso) {
        aguardandoBootTrove := true
        inicioBootTrove := A_TickCount
        inicioAusenciaTrove := 0
        LimparErro("WATCHDOG")
    }
    Critical("Off")
    return true
}

VerificarErrorHandler(agora) {
    global ativo, inicioErrorHandler, recuperandoErrorHandler, inicioFechamentoTrove
    global aguardandoBootTrove, inicioBootTrove, inicioFocoTrove
    global inicioAusenciaTrove, watchdogExecutando
    global CONFIRMACAO_ERROR_HANDLER, ESPERA_FECHAR_TROVE, CONFIRMACAO_CRASH

    janelasErro := ListarJanelasErrorHandler()

    if (!recuperandoErrorHandler && janelasErro.Length = 0) {
        inicioErrorHandler := 0
        return false
    }

    SuspenderCronometro()
    CancelarLeituraMorte()

    if (!recuperandoErrorHandler) {
        if (inicioErrorHandler = 0) {
            inicioErrorHandler := agora
            return true
        }
        if (agora - inicioErrorHandler < CONFIRMACAO_ERROR_HANDLER)
            return true

        recuperandoErrorHandler := true
        inicioFechamentoTrove := agora
        watchdogExecutando := true
        aguardandoBootTrove := false
        inicioBootTrove := 0
        inicioFocoTrove := 0
        RegistrarErro("WATCHDOG", "Crash confirmado. Encerrando Trove e Error Handler.")
    }

    if (!ativo)
        return true

    ; Fecha qualquer etapa do relatorio sem depender de botoes ou coordenadas.
    for hwnd in janelasErro {
        try WinClose("ahk_id " hwnd)
    }

    pidTrove := ProcessExist("Trove_x64.exe")
    if (pidTrove) {
        ; WinClose envia um fechamento direcionado, equivalente ao Alt+F4 no Trove.
        try WinClose("ahk_exe Trove_x64.exe")
        if (agora - inicioFechamentoTrove >= ESPERA_FECHAR_TROVE) {
            ; Processo travado: ultimo recurso para garantir que o farm possa voltar.
            try ProcessClose(pidTrove)
        }
        return true
    }

    if (janelasErro.Length > 0) {
        if (agora - inicioFechamentoTrove >= ESPERA_FECHAR_TROVE) {
            for hwnd in janelasErro {
                try {
                    pidErro := WinGetPID("ahk_id " hwnd)
                    nomeErro := pidErro ? ProcessGetName(pidErro) : ""
                    ; Nunca derruba o launcher nem o proprio script por causa do titulo.
                    if (pidErro && nomeErro != "GlyphClientApp.exe"
                        && nomeErro != "AutoHotkey64.exe" && nomeErro != "AutoHotkey32.exe")
                        ProcessClose(pidErro)
                }
            }
        }
        return true
    }

    recuperandoErrorHandler := false
    inicioErrorHandler := 0
    inicioFechamentoTrove := 0
    watchdogExecutando := false
    ; Reaproveita imediatamente o fluxo ja validado de abertura pelo Glyph.
    inicioAusenciaTrove := A_TickCount - CONFIRMACAO_CRASH
    LimparErro("WATCHDOG")
    return true
}

ListarJanelasErrorHandler() {
    janelas := []
    try {
        for hwnd in WinGetList("Trove - Error Handler") {
            try {
                if (WinGetTitle("ahk_id " hwnd) = "Trove - Error Handler")
                    janelas.Push(hwnd)
            }
        }
    }
    return janelas
}

AbrirTrovePeloGlyph() {
    global ativo
    glyph := "ahk_exe GlyphClientApp.exe"

    if !WinExist(glyph) {
        RegistrarErro("WATCHDOG", "GlyphClientApp.exe nao foi encontrado.")
        return false
    }

    try {
        WinRestore(glyph)
        WinActivate(glyph)
        if !WinWaitActive(glyph, , 5) {
            RegistrarErro("WATCHDOG", "Nao foi possivel ativar o Glyph.")
            return false
        }
        if (!ativo || ProcessExist("Trove_x64.exe"))
            return false

        WinGetPos(&x, &y, &w, &h, glyph)
        if (w <= 0 || h <= 0)
            throw Error("Janela do Glyph sem dimensoes validas")

        modoMouseAnterior := A_CoordModeMouse
        try {
            CoordMode("Mouse", "Screen")
            Click(x + Round(w * 0.738), y + Round(h * 0.135))
        } finally {
            CoordMode("Mouse", modoMouseAnterior)
        }
        return true
    } catch Error as erro {
        RegistrarErro("WATCHDOG", "Falha ao iniciar pelo Glyph: " SubStr(erro.Message, 1, 150))
        return false
    }
}

RetomarBuscaShip(mensagem) {
    global estado, fimPausa, ultimoChat, inicioPreto, pretoBloqueado, amigosPendentes
    global ultimaLeituraMorte
    global ressurreicaoConfirmada, inicioMundoRessurreicao
    global validacaoAntesChat

    CancelarLeituraMorte()
    ReiniciarCronometro()
    estado := "PROCURANDO"
    fimPausa := 0
    ultimoChat := 0
    validacaoAntesChat := 0
    inicioPreto := 0
    pretoBloqueado := false
    amigosPendentes := []
    ressurreicaoConfirmada := false
    inicioMundoRessurreicao := 0
    ultimaLeituraMorte := "Aguardando proxima verificacao"
    Avisar(mensagem)
}



#Requires AutoHotkey v2.0
#SingleInstance Force

SendMode("Input")
CoordMode("Pixel", "Client")

; ===== CONFIGURACOES =====

; Historico: CHANGELOG.md. Versao publicada lida diretamente do trove.ahk no GitHub.
global VERSAO := "2.10.0"
; ===== ESTADO DAS ATUALIZACOES =====
; Interface e atualizador do USFT (AutoHotkey v2).
global URL_ATUALIZACOES := "https://raw.githubusercontent.com/leosmsilvx/USFT/main/"
global janelaVersoes := 0, camposVersoes := Map()
global versaoDisponivel := "", codigoDisponivel := ""
global requisicaoAtualizacao := 0, etapaAtualizacao := "", inicioAtualizacao := 0
global statusAtualizacao := "Aguardando consulta ao GitHub."
global instalandoAtualizacao := false, pastaAtualizacao := "", indiceAtualizacao := 0
global arquivosAtualizacao := ["trove.ahk", "CHANGELOG.md"]
global PAINEL_LARGURA := 300 ; px
global PAINEL_ALTURA := 180 ; px
global COR_BARRA_LATERAL := "353A3A"
global FONTE_PAINEL := "" ; preenchida com Roboto somente apos carregar do Google.
global arquivoFonteGoogle := ""
global FUNDO_TRANSPARENTE := true ; false para manter o painel totalmente opaco.
global OPACIDADE_FUNDO := 205 ; 0=invisivel, 255=opaco; textos sempre opacos.
global INTERVALO_CHAT := 120000
global MENSAGENS_SHIP := ["x ship pls", "x ship", "x", "x ship xD", "ship plss"]
global INTERVALO_PULO := 240000
global PAUSA_DUNGEON := 30 * 60 * 1000
global INTERVALO_MONITOR := 500
global CONFIRMACAO_PRETO := 1500
global LIMITE_PRETO := 30
global ARQUIVO_AMIGOS := A_ScriptDir "\amigos.txt"
global CONFIRMACAO_MUNDO := 3000
global INTERVALO_CONVITES := 2000
global INTERVALO_CRONOMETRO := 1000
global INTERVALO_CRONOMETRO_ATIVO := 1000
global TEMPO_VALIDACAO_CRONOMETRO := 3 * 60 * 1000
global LIMITE_CONFIRMACOES_ZERO := 2
global INTERVALO_MORTE := 1000
global INTERVALO_RESSUSCITAR := 15000
global INTERVALO_CONFIRMAR_RESSURREICAO := 1000
global ESPERA_APOS_RESSURREICAO := 5000
global CONFIRMACAO_CRASH := 5000
global ESPERA_BOOT_TROVE := 120000
global CONFIRMACAO_BOOT_TROVE := 5000
global INTERVALO_RETENTATIVA_GLYPH := 15000
global CONFIRMACAO_ERROR_HANDLER := 1000
global ESPERA_FECHAR_TROVE := 5000
; Regiao do titulo e tempo da dungeon em 1920x1080, proporcional ao cliente.
global CRONOMETRO_X := 0.455
global CRONOMETRO_Y := 0.105
global CRONOMETRO_W := 0.090
global CRONOMETRO_H := 0.095


; ===== ESTADO =====

global ativo := false
global convidarAmigos := true
global estado := "PARADO"
global ultimoChat := 0
global validacaoAntesChat := 0
global ultimoPulo := 0
global fimPausa := 0
global inicioPreto := 0
global pretoBloqueado := false
global verificando := false
global inicioMundo := 0
global amigosPendentes := []
global proximoAmigo := 1
global ultimoConvite := 0
global ultimaLeituraCronometro := 0
global inicioValidacaoCronometro := 0
global leiturasInvalidas := 0
global cronometroConfirmado := false
global motivoRetornoCronometro := ""
global processoOCR := 0
global resultadoOCR := ""
global inicioSemFocoCronometro := 0
global errosPainel := Map()
global painel := 0
global fundoPainel := 0
global avisoPainel := 0
global fundoAvisoPainel := 0
global larguraAvisoPainel := 0
global alturaAvisoPainel := 0
global painelVisivel := true
global camposPainel := Map()
global ultimaLeituraPainel := "Aguardando entrada no mundo"
global processoMorte := 0
global resultadoMorte := ""
global ultimaVerificacaoMorte := 0
global ultimaRessurreicao := 0
global ultimaLeituraMorte := "Aguardando ativacao"
global ressurreicaoConfirmada := false
global inicioMundoRessurreicao := 0
global inicioAusenciaTrove := 0
global aguardandoBootTrove := false
global inicioBootTrove := 0
global inicioFocoTrove := 0
global ultimaTentativaGlyph := 0
global watchdogExecutando := false
global geracaoWatchdog := 0
global inicioErrorHandler := 0
global recuperandoErrorHandler := false
global inicioFechamentoTrove := 0

try GarantirArquivoAmigos()
catch Error as erro
    errosPainel["AMIGOS"] := "Não foi possível criar amigos.txt: " erro.Message
IniciarPainel()
IniciarAtualizacoes()
SetTimer(AtualizarPainel, 500)

; F11 ALTERNA O FARM, F9 ENCERRA E F10 ALTERNA OS CONVITES.

F11:: {
    global ativo
    if (ativo)
        PararFarm()
    else
        IniciarFarm()
}

F9::ExitApp()

F10:: {
    global convidarAmigos

    convidarAmigos := !convidarAmigos
    Avisar(convidarAmigos ? "CONVITES DE AMIGOS ATIVADOS" : "CONVITES DE AMIGOS DESATIVADOS")
    SoundBeep(convidarAmigos ? 1100 : 600, 100)
}

IniciarFarm() {
    global instalandoAtualizacao
    if (instalandoAtualizacao)
        return
    global ativo, estado, ultimoChat, ultimoPulo
    global inicioPreto, pretoBloqueado
    global inicioMundo, amigosPendentes, proximoAmigo, ultimoConvite
    global validacaoAntesChat

    if (ativo)
        return

    ativo := true
    validacaoAntesChat := 0
    ReiniciarCronometro()
    ReiniciarMorte()
    ReiniciarWatchdog()

    estado := "VERIFICANDO_DUNGEON"
    ultimoChat := 0
    ultimoPulo := A_TickCount
    inicioPreto := 0
    pretoBloqueado := false
    inicioMundo := 0
    amigosPendentes := []
    proximoAmigo := 1
    ultimoConvite := 0

    SoundBeep(1000, 200)
    SetTimer(Monitorar, INTERVALO_MONITOR)
    Monitorar()
}

PararFarm() {
    global ativo, estado, validacaoAntesChat

    if (!ativo)
        return

    ativo := false
    validacaoAntesChat := 0
    ReiniciarCronometro()
    ReiniciarMorte()
    ReiniciarWatchdog()
    estado := "PARADO"
    SetTimer(Monitorar, 0)

    SoundBeep(600, 200)
    Avisar("AUTO SHIP PAUSADO")
}

; B OCULTA O PAINEL SEM BLOQUEAR A TECLA DO JOGO.
#HotIf WinActive("ahk_exe Trove_x64.exe")
~$b:: {
    global painel, fundoPainel, painelVisivel
    painelVisivel := false
    painel.Hide()
    fundoPainel.Hide()
    AtualizarPainel()
}
#HotIf

; CTRL + ALT + B MOSTRA NOVAMENTE, SEM ALTERAR A AUTOMACAO.
^!b:: {
    global painelVisivel, avisoPainel, fundoAvisoPainel
    painelVisivel := true
    avisoPainel.Hide()
    fundoAvisoPainel.Hide()
    AtualizarPainel()
}

; ===== MONITOR PRINCIPAL =====

Monitorar() {
    global ativo, estado, ultimoChat, ultimoPulo
    global fimPausa, inicioPreto, pretoBloqueado
    global verificando
    global INTERVALO_CHAT, INTERVALO_PULO
    global PAUSA_DUNGEON, CONFIRMACAO_PRETO
    global inicioMundo, amigosPendentes, proximoAmigo, ultimoConvite
    global CONFIRMACAO_MUNDO, INTERVALO_CONVITES
    global convidarAmigos
    global processoMorte
    global motivoRetornoCronometro
    global inicioMundoRessurreicao
    global validacaoAntesChat, cronometroConfirmado

    if (!ativo || verificando)
        return

    verificando := true

    try {
        ; O watchdog usa o mesmo timer e a mesma trava do farm, evitando reentrancia.
        if VerificarCrashTrove()
            return

        if !WinActive("ahk_exe Trove_x64.exe") {
            inicioMundo := 0
            inicioMundoRessurreicao := 0
            inicioPreto := 0
            ; Suspende a leitura, preservando contagem e confirmacao anteriores.
            SuspenderCronometro()
            CancelarLeituraMorte()
            return
        }

        RetomarCronometro()
        agora := A_TickCount

        ; Teleporte tem prioridade sobre OCR, busca, convites e pausa.
        if DetectarMudancaMundo(agora)
            return

        ; Morte tem prioridade inclusive durante os 3 min de validacao do cronometro.
        ; As travas processoOCR/processoMorte alternam os leitores sem sobreposicao.
        if VerificarMorte()
            return

        ; Identifica a dungeon antes de cada envio no chat.
        if (estado = "VERIFICANDO_DUNGEON") {
            if (!TelaPreta())
                VerificarCronometro()
            return
        }

        if (estado = "RESSUSCITANDO") {
            AguardarRessurreicao()
            return
        }

        ; Aguarda o fim do carregamento e a imagem estabilizar.
        if (estado = "CARREGANDO") {
            if (TelaPreta()) {
                inicioMundo := 0
                return
            }

            if (inicioMundo = 0) {
                inicioMundo := agora
                return
            }

            if (agora - inicioMundo < CONFIRMACAO_MUNDO)
                return

            amigosPendentes := convidarAmigos ? LerAmigos() : []
            proximoAmigo := 1
            ultimoConvite := 0
            fimPausa := 0 ; os 30 min comecam apenas apos confirmar o cronometro.
            ultimoPulo := A_TickCount
            ReiniciarCronometro()
            if (!convidarAmigos) {
                estado := "DUNGEON"
                Avisar("MUNDO CARREGADO - CONVITES DESATIVADOS - PAUSA DE 30 MIN")
                return
            }
            estado := "CONVIDANDO"
        }

        if ((estado = "DUNGEON" || estado = "CONVIDANDO") && VerificarCronometro()) {
            RetomarBuscaShip(motivoRetornoCronometro)
            ; Segue ate o envio de x ship pls nesta mesma verificacao.
        }

        ; Um convite por vez, sem repetir os nomes ja enviados.
        if (estado = "CONVIDANDO") {
            if (!convidarAmigos) {
                amigosPendentes := []
                estado := "DUNGEON"
                Avisar("CONVITES INTERROMPIDOS - PAUSA DE 30 MIN")
                return
            }

            if (TelaPreta())
                return
            if (processoMorte)
                return

            if (proximoAmigo > amigosPendentes.Length) {
                estado := "DUNGEON"
                Avisar("MUNDO CARREGADO - " amigosPendentes.Length " CONVITE(S) - PAUSA DE 30 MIN")
                return
            }

            if (ultimoConvite = 0 || agora - ultimoConvite >= INTERVALO_CONVITES) {
                if EnviarConvite(amigosPendentes[proximoAmigo]) {
                    proximoAmigo += 1
                    ultimoConvite := A_TickCount
                }
            }
            return
        }

        ; 1. ANTI-AFK: PULAR A CADA 4 MIN
        if (!processoMorte && agora - ultimoPulo >= INTERVALO_PULO) {
            ; Evita pular durante carregamento
            if (!TelaPreta()) {
                SendInput("{Space}")
                ultimoPulo := A_TickCount
                SoundBeep(850, 80)
            }
        }

        ; 2. PAUSA DE 30 MINUTOS
        if (estado = "DUNGEON") {
            if (!cronometroConfirmado || fimPausa = 0)
                return
            if (agora < fimPausa)
                return

            SoundBeep(1200, 150)
            SoundBeep(1500, 150)
            RetomarBuscaShip("30 MIN FINALIZADOS - PROCURANDO SHIP")
        }

        ; 4. ENVIO DO CHAT
        if (estado = "PROCURANDO" && !processoMorte) {
            if (ultimoChat = 0
                || agora - ultimoChat >= INTERVALO_CHAT) {
                if (validacaoAntesChat = 0 || A_TickCount - validacaoAntesChat > 5000) {
                    estado := "VERIFICANDO_DUNGEON"
                    ReiniciarCronometro()
                    return
                }
                enviado := EnviarMensagem()
                validacaoAntesChat := 0
                if (enviado)
                    ultimoChat := A_TickCount
            }
        }

    } finally {
        verificando := false
    }
}

; ===== MUDANCA DE MUNDO: EXECUTADA ANTES DOS RETORNOS DOS ESTADOS =====

DetectarMudancaMundo(agora) {
    global estado, inicioPreto, pretoBloqueado, CONFIRMACAO_PRETO
    global inicioMundo, fimPausa, validacaoAntesChat, amigosPendentes

    ; Estes dois estados ja aguardam o proprio carregamento.
    if (estado = "CARREGANDO" || estado = "RESSUSCITANDO")
        return false

    if !TelaPreta() {
        inicioPreto := 0
        pretoBloqueado := false
        return false
    }

    ; Uma leitura iniciada no mundo anterior nao pode autorizar chat nem farm.
    CancelarLeituraCronometro()
    CancelarLeituraMorte()
    validacaoAntesChat := 0

    if (inicioPreto = 0) {
        inicioPreto := agora
        return true
    }

    if (!pretoBloqueado && agora - inicioPreto >= CONFIRMACAO_PRETO) {
        estado := "CARREGANDO"
        inicioMundo := 0
        inicioPreto := 0
        pretoBloqueado := true
        fimPausa := 0
        amigosPendentes := []
        ReiniciarCronometro()
        SoundBeep(700, 250)
        SoundBeep(500, 250)
        AtualizarPainel()
    }
    return true
}

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

; ===== CRONOMETRO: INICIAL 30s; CONFIRMADO 60s DURANTE A PAUSA =====

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

; ===== DETECTAR TELA PRETA =====

TelaPreta() {
    global LIMITE_PRETO, painel

    try {
        if !WinActive("ahk_exe Trove_x64.exe")
            return false

        WinGetClientPos(&clienteX, &clienteY, &w, &h, "ahk_exe Trove_x64.exe")

        if (w < 100 || h < 100)
            return false

        pontos := [
            [0.15, 0.15],
            [0.50, 0.15],
            [0.85, 0.15],
            [0.15, 0.85],
            [0.85, 0.85]
        ]

        ; PixelGetColor tambem enxerga nosso painel sobre o jogo.
        ; Ignora sua area, em vez de confundir o painel com o mundo carregado.
        temPainel := IsObject(painel) && WinExist("ahk_id " painel.Hwnd)
        if (temPainel)
            WinGetPos(&painelX, &painelY, &painelW, &painelH, "ahk_id " painel.Hwnd)

        pontosLidos := 0
        for ponto in pontos {
            x := Round(w * ponto[1])
            y := Round(h * ponto[2])

            telaX := clienteX + x
            telaY := clienteY + y
            if (temPainel && telaX >= painelX && telaX < painelX + painelW
                && telaY >= painelY && telaY < painelY + painelH)
                continue

            cor := PixelGetColor(x, y, "RGB")
            pontosLidos += 1

            r := (cor >> 16) & 255
            g := (cor >> 8) & 255
            b := cor & 255

            if (r > LIMITE_PRETO
                || g > LIMITE_PRETO
                || b > LIMITE_PRETO)
                return false
        }

        ; Exige amostras suficientes do jogo, sem usar pixels do painel.
        return pontosLidos >= 3 && WinActive("ahk_exe Trove_x64.exe")

    } catch {
        return false
    }
}

; ===== ENVIAR MENSAGEM =====

EnviarMensagem() {
    global estado, validacaoAntesChat
    if (estado != "PROCURANDO" || validacaoAntesChat = 0 || A_TickCount - validacaoAntesChat > 5000)
        return false
    global MENSAGENS_SHIP

    if !EnviarTextoChat("/join ship")
        return false
    Sleep(700)
    mensagem := MENSAGENS_SHIP[Random(1, MENSAGENS_SHIP.Length)]
    if !EnviarTextoChat(mensagem)
        return false

    SoundBeep(1500, 150)
    return true
}

EnviarTextoChat(texto) {
    global ativo
    if (!ativo || !WinActive("ahk_exe Trove_x64.exe"))
        return false

    SendInput("{Enter}")
    Sleep(400)

    if (!ativo || !WinActive("ahk_exe Trove_x64.exe")) {
        if WinActive("ahk_exe Trove_x64.exe")
            SendInput("{Esc}")
        return false
    }

    SendInput("^a")
    SendText(texto)
    Sleep(400)

    if (!ativo || !WinActive("ahk_exe Trove_x64.exe")) {
        if WinActive("ahk_exe Trove_x64.exe")
            SendInput("{Esc}")
        return false
    }
    SendInput("{Enter}")
    return true
}

; ===== LISTA DE AMIGOS E CONVITES =====

GarantirArquivoAmigos() {
    global ARQUIVO_AMIGOS
    if !FileExist(ARQUIVO_AMIGOS)
        FileAppend("", ARQUIVO_AMIGOS, "UTF-8-RAW")
}

LerAmigos() {
    global ARQUIVO_AMIGOS

    amigos := []
    nomesLidos := Map()
    nomesLidos.CaseSense := false

    try {
        GarantirArquivoAmigos()
        conteudo := FileRead(ARQUIVO_AMIGOS, "UTF-8")
    } catch {
        RegistrarErro("AMIGOS", "Nao foi possivel ler amigos.txt. Nenhum convite enviado.")
        return amigos
    }

    LimparErro("AMIGOS")

    for linha in StrSplit(conteudo, "`n", "`r") {
        nome := Trim(linha, " `t`r" Chr(0xFEFF))
        if (nome = "" || SubStr(nome, 1, 1) = ";" || SubStr(nome, 1, 1) = "#")
            continue

        ; X seguido de espaco desativa o convite desta linha.
        if RegExMatch(nome, "i)^x\s+")
            continue

        if !nomesLidos.Has(nome) {
            nomesLidos[nome] := true
            amigos.Push(nome)
        }
    }
    return amigos
}

EnviarConvite(nome) {
    global ativo, convidarAmigos

    if (!ativo || !convidarAmigos || !WinActive("ahk_exe Trove_x64.exe"))
        return false

    SendInput("{Enter}")
    Sleep(400)
    if (!ativo || !convidarAmigos || !WinActive("ahk_exe Trove_x64.exe")) {
        if WinActive("ahk_exe Trove_x64.exe")
            SendInput("{Esc}")
        return false
    }

    ; Limpa qualquer texto antigo que tenha ficado no chat.
    SendInput("^a")
    SendText("/joinme " nome)
    Sleep(400)
    if (!ativo || !convidarAmigos || !WinActive("ahk_exe Trove_x64.exe")) {
        if WinActive("ahk_exe Trove_x64.exe")
            SendInput("{Esc}")
        return false
    }

    SendInput("{Enter}")
    return true
}

; ===== DETECTAR MORTE E RESSUSCITAR =====

CancelarLeituraMorte() {
    global processoMorte, resultadoMorte
    if (processoMorte && ProcessExist(processoMorte)) {
        try ProcessClose(processoMorte)
    }
    if (resultadoMorte != "" && FileExist(resultadoMorte)) {
        try FileDelete(resultadoMorte)
    }
    processoMorte := 0
    resultadoMorte := ""
}

ReiniciarMorte() {
    global ultimaVerificacaoMorte, ultimaLeituraMorte, INTERVALO_MORTE
    global ressurreicaoConfirmada, inicioMundoRessurreicao
    CancelarLeituraMorte()
    ultimaVerificacaoMorte := A_TickCount - INTERVALO_MORTE
    ultimaLeituraMorte := "Verificacao a cada 60 segundos"
    ressurreicaoConfirmada := false
    inicioMundoRessurreicao := 0
}

AguardarRessurreicao() {
    global ressurreicaoConfirmada, inicioMundoRessurreicao, ESPERA_APOS_RESSURREICAO
    global processoMorte

    if (TelaPreta()) {
        inicioMundoRessurreicao := 0
        ressurreicaoConfirmada := false
        return
    }
    if (!ressurreicaoConfirmada) {
        inicioMundoRessurreicao := 0
        return
    }
    if (processoMorte)
        return
    if (inicioMundoRessurreicao = 0)
        inicioMundoRessurreicao := A_TickCount
    if (A_TickCount - inicioMundoRessurreicao >= ESPERA_APOS_RESSURREICAO)
        RetomarBuscaShip("RESSURREICAO CONCLUIDA - PROCURANDO SHIP")
}

VerificarMorte() {
    global ativo, processoMorte, resultadoMorte, ultimaVerificacaoMorte
    global ultimaRessurreicao, ultimaLeituraMorte, INTERVALO_MORTE, INTERVALO_RESSUSCITAR
    global processoOCR
    global estado, fimPausa, ressurreicaoConfirmada, inicioMundoRessurreicao
    global INTERVALO_CONFIRMAR_RESSURREICAO

    if (!ativo || !WinActive("ahk_exe Trove_x64.exe")) {
        CancelarLeituraMorte()
        return false
    }
    if (ultimaRessurreicao != 0 && A_TickCount - ultimaRessurreicao < 2500)
        return true

    if (processoMorte) {
        if (A_TickCount - ultimaVerificacaoMorte > 10000) {
            ressurreicaoConfirmada := false
            CancelarLeituraMorte()
            ultimaLeituraMorte := "Falha na leitura"
            RegistrarErro("MORTE", "Leitura de morte expirou. Tentando novamente.")
            return false
        }
        if ProcessExist(processoMorte)
            return false

        leitura := "ERRO"
        try leitura := Trim(FileRead(resultadoMorte, "UTF-8"))
        CancelarLeituraMorte()

        if (leitura = "SEM_FOCO")
            return false
        if (leitura = "MORTO") {
            ressurreicaoConfirmada := false
            inicioMundoRessurreicao := 0
            LimparErro("MORTE")
            ; Confirma a imagem atual, pois o OCR pode levar alguns instantes.
            if (TelaAcinzentada() && !TelaPreta() && ativo && WinActive("ahk_exe Trove_x64.exe")) {
                if (ultimaRessurreicao = 0 || A_TickCount - ultimaRessurreicao >= INTERVALO_RESSUSCITAR) {
                    ; Mantem a tecla brevemente pressionada para o jogo registrar.
                    SendEvent("{e down}")
                    try Sleep(100)
                    finally SendEvent("{e up}")
                    ultimaRessurreicao := A_TickCount
                    ReiniciarCronometro()
                    estado := "RESSUSCITANDO"
                    fimPausa := 0
                    ressurreicaoConfirmada := false
                    inicioMundoRessurreicao := 0
                    ultimaLeituraMorte := "Morte confirmada - E enviado"
                } else {
                    ultimaLeituraMorte := "Aguardando ressuscitar"
                }
                return true
            }
            ultimaLeituraMorte := "Sem confirmacao visual de morte"
            return false
        }
        if (leitura = "VIVO") {
            LimparErro("MORTE")
            ultimaLeituraMorte := "Sem morte detectada"
            if (estado = "RESSUSCITANDO")
                ressurreicaoConfirmada := true
        } else {
            ultimaLeituraMorte := "Falha na leitura"
            ressurreicaoConfirmada := false
            RegistrarErro("MORTE", "Nao foi possivel reconhecer a mensagem de morte.")
        }
        return false
    }

    intervalo := estado = "RESSUSCITANDO" ? INTERVALO_CONFIRMAR_RESSURREICAO : INTERVALO_MORTE
    if (A_TickCount - ultimaVerificacaoMorte < intervalo || processoOCR || TelaPreta())
        return false

    ultimaVerificacaoMorte := A_TickCount
    try {
        WinGetClientPos(&x, &y, &w, &h, "ahk_exe Trove_x64.exe")
        resultadoMorte := A_Temp "\trove-morte-" ProcessExist() "-" A_TickCount ".txt"
        ; Faixa central do aviso: referencia 1920x1080, texto em x758..1160/y400..500.
        codigo := "$Mode='MORTE';$X=" Round(x + w * 0.32) ";$Y=" Round(y + h * 0.35)
            . ";$Width=" Round(w * 0.36) ";$Height=" Round(h * 0.15)
            . ";$OutputPath='" StrReplace(resultadoMorte, "'", "''") "';`n" CodigoOCR()
        aspas := Chr(34)
        comando := aspas A_WinDir "\System32\WindowsPowerShell\v1.0\powershell.exe" aspas
            . " -NoProfile -NonInteractive -EncodedCommand " CodificarPowerShell(codigo)
        ; OCR restrito a faixa central; o painel permanece visivel a direita.
        Run(comando, A_ScriptDir, "Hide", &processoMorte)
        ultimaLeituraMorte := "Lendo mensagem de morte..."
        return false
    } catch Error as erro {
        CancelarLeituraMorte()
        ultimaLeituraMorte := "Falha ao iniciar leitura"
        RegistrarErro("MORTE", SubStr(erro.Message, 1, 180))
        return false
    }
}

TelaAcinzentada() {
    global painel
    try {
        if !WinActive("ahk_exe Trove_x64.exe")
            return false
        WinGetClientPos(&cx, &cy, &w, &h, "ahk_exe Trove_x64.exe")
        pontos := [[0.25, 0.30], [0.50, 0.30], [0.25, 0.45], [0.70, 0.45], [0.25, 0.70], [0.70, 0.70]]
        temPainel := IsObject(painel) && WinExist("ahk_id " painel.Hwnd)
        if (temPainel)
            WinGetPos(&px, &py, &pw, &ph, "ahk_id " painel.Hwnd)
        lidos := 0
        cinzas := 0
        for ponto in pontos {
            x := Round(w * ponto[1])
            y := Round(h * ponto[2])
            if (temPainel && cx + x >= px && cx + x < px + pw && cy + y >= py && cy + y < py + ph)
                continue
            cor := PixelGetColor(x, y, "RGB")
            r := (cor >> 16) & 255
            g := (cor >> 8) & 255
            b := cor & 255
            lidos += 1
            if (Max(r, g, b) - Min(r, g, b) <= 45 && Max(r, g, b) >= 40)
                cinzas += 1
        }
        return lidos >= 3 && cinzas >= Ceil(lidos * 0.6)
    } catch {
        return false
    }
}

; ===== PAINEL FIXO DE STATUS =====

CarregarFontePainel() {
    global FONTE_PAINEL, arquivoFonteGoogle
    FONTE_PAINEL := ""
    try {
        requisicao := ComObject("WinHttp.WinHttpRequest.5.1")
        requisicao.SetTimeouts(1000, 1000, 1500, 1500)
        requisicao.Open("GET", "https://raw.githubusercontent.com/google/fonts/main/ofl/roboto/Roboto%5Bwdth%2Cwght%5D.ttf", false)
        requisicao.Send()
        if (requisicao.Status != 200)
            throw Error("Fonte do Google indisponivel")

        arquivoFonteGoogle := A_Temp "\USFT-Roboto-Google-" ProcessExist() ".ttf"
        fluxo := ComObject("ADODB.Stream")
        fluxo.Type := 1
        fluxo.Open()
        try {
            fluxo.Write(requisicao.ResponseBody)
            fluxo.SaveToFile(arquivoFonteGoogle, 2)
        } finally {
            fluxo.Close()
        }

        dados := FileRead(arquivoFonteGoogle, "RAW")
        if (dados.Size < 12 || (NumGet(dados, 0, "UInt") != 0x00000100
            && NumGet(dados, 0, "UInt") != 0x4F54544F))
            throw Error("Resposta nao contem uma fonte TTF valida")

        ; FR_PRIVATE: prioriza a fonte baixada somente neste processo.
        if !DllCall("gdi32\AddFontResourceExW", "Str", arquivoFonteGoogle, "UInt", 0x10, "Ptr", 0)
            throw Error("Nao foi possivel carregar a Roboto")
        FONTE_PAINEL := "Roboto"
        OnExit(LiberarFonteGoogle)
    } catch {
        LiberarFonteGoogle()
        ; Nome vazio deixa o Windows escolher a fonte padrao da GUI.
        FONTE_PAINEL := ""
    }
}

LiberarFonteGoogle(*) {
    global arquivoFonteGoogle
    if (arquivoFonteGoogle != "") {
        try DllCall("gdi32\RemoveFontResourceExW", "Str", arquivoFonteGoogle, "UInt", 0x10, "Ptr", 0)
        if FileExist(arquivoFonteGoogle) {
            try FileDelete(arquivoFonteGoogle)
        }
        arquivoFonteGoogle := ""
    }
}

IniciarPainel() {
    global painel, fundoPainel, avisoPainel, fundoAvisoPainel, camposPainel, VERSAO
    global larguraAvisoPainel, alturaAvisoPainel
    global PAINEL_LARGURA, PAINEL_ALTURA
    global COR_BARRA_LATERAL, FONTE_PAINEL

    CarregarFontePainel()

    ; Nao recebe foco e deixa os cliques passarem para o jogo.
    fundoPainel := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20 +E0x08000000", "USFT - Fundo")
    fundoPainel.BackColor := "000000"
    painel := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20 +E0x08000000 +Owner" fundoPainel.Hwnd, "USFT v" VERSAO " - Status")
    painel.BackColor := "000000"
    painel.AddText("x0 y0 w3 h" PAINEL_ALTURA " Background" COR_BARRA_LATERAL, "")
    painel.SetFont("s10 cE7EDF5", FONTE_PAINEL)
    painel.SetFont("s12 bold cFFFFFF")
    painel.AddText("x12 y8 w" (PAINEL_LARGURA - 24) " h24", "USFT")
    painel.SetFont("s10 norm cE7EDF5")
    ; Rotulos, colchetes e indicadores separados: apenas os simbolos mudam de cor.
    ; Coordenadas e larguras fixas mantem Busca e Convite sempre alinhados.
    painel.AddText("x12 y34 w46 h20 +0x200", "Busca:")
    painel.AddText("x154 y34 w54 h20 +0x200", "Convite:")
    ; Colchetes proximos dos simbolos, com centro vertical alinhado.
    painel.SetFont("s10 norm cE7EDF5", FONTE_PAINEL)
    painel.AddText("x58 y34 w6 h20 +0x200", "[")
    painel.AddText("x84 y34 w6 h20 +0x200", "]")
    painel.AddText("x210 y34 w6 h20 +0x200", "[")
    painel.AddText("x236 y34 w6 h20 +0x200", "]")
    painel.SetFont("s14 bold cE7EDF5", FONTE_PAINEL)
    camposPainel["auto"] := painel.AddText("x64 y32 w20 h24 Center +0x200")
    camposPainel["amigos"] := painel.AddText("x216 y32 w20 h24 Center +0x200")
    painel.SetFont("s10 norm cE7EDF5", FONTE_PAINEL)
    camposPainel["estado"] := painel.AddText("x12 y56 w" (PAINEL_LARGURA - 24) " h20")
    camposPainel["tempo"] := painel.AddText("x12 y76 w" (PAINEL_LARGURA - 24) " h20")
    camposPainel["erroTitulo"] := painel.AddText("x12 y96 w" (PAINEL_LARGURA - 24) " h18 cFF7272")
    painel.SetFont("s8")
    camposPainel["erro"] := painel.AddText("x12 y114 w" (PAINEL_LARGURA - 24) " h" Max(0, PAINEL_ALTURA - 152) " cFF9292")
    painel.SetFont("s8 norm cA9B7C9")
    painel.AddText("x12 y" (PAINEL_ALTURA - 34) " w" (PAINEL_LARGURA - 76) " h30 Left",
        "F11: Iniciar/Parar | F10: Convites`nF9: Fechar | F2: Patch notes")
    painel.SetFont("s7 norm cA9B7C9")
    painel.AddText("x" (PAINEL_LARGURA - 58) " y" (PAINEL_ALTURA - 18) " w46 h14 Right", "v" VERSAO)
    fundoAvisoPainel := Gui("+AlwaysOnTop -Caption +ToolWindow -DPIScale +E0x20 +E0x08000000", "USFT - Fundo do aviso")
    fundoAvisoPainel.BackColor := "000000"
    avisoPainel := Gui("+AlwaysOnTop -Caption +ToolWindow -DPIScale +E0x20 +E0x08000000 +Owner" fundoAvisoPainel.Hwnd, "USFT - Abrir")
    avisoPainel.BackColor := "000000"
    avisoPainel.SetFont("s8 cE7EDF5", FONTE_PAINEL)
    textoAviso := avisoPainel.AddText("x6 y4", "Ctrl Alt B para abrir USFT")
    textoAviso.GetPos(, , &larguraTexto, &alturaTexto)
    larguraAvisoPainel := larguraTexto + 12
    alturaAvisoPainel := alturaTexto + 8
    PrepararTransparenciaPainel()
    AtualizarPainel()
}

PrepararTransparenciaPainel() {
    global painel, fundoPainel, avisoPainel, fundoAvisoPainel, FUNDO_TRANSPARENTE, OPACIDADE_FUNDO, errosPainel
    anterior := A_DetectHiddenWindows
    DetectHiddenWindows(true)
    try {
        ; Duas camadas: alpha apenas no fundo, chave de cor apenas na camada de texto.
        WinSetTransparent(FUNDO_TRANSPARENTE ? Max(0, Min(255, OPACIDADE_FUNDO)) : 255,
            "ahk_id " fundoPainel.Hwnd)
        WinSetTransparent(FUNDO_TRANSPARENTE ? Max(0, Min(255, OPACIDADE_FUNDO)) : 255,
            "ahk_id " fundoAvisoPainel.Hwnd)
        WinSetTransColor("000000", "ahk_id " painel.Hwnd)
        WinSetTransColor("000000", "ahk_id " avisoPainel.Hwnd)
    } catch Error as erro {
        errosPainel["TRANSPARENCIA"] := SubStr(erro.Message, 1, 180)
    } finally {
        DetectHiddenWindows(anterior)
    }
}

AtualizarAvisoPainel() {
    global avisoPainel, fundoAvisoPainel
    global larguraAvisoPainel, alturaAvisoPainel
    static ultimoX := "", ultimoY := ""
    MonitorGetWorkArea(MonitorGetPrimary(), &esquerda, &topo, &direita, &base)
    x := Max(esquerda, direita - larguraAvisoPainel - 10)
    y := topo + 10
    try {
        if (WinExist("ahk_exe Trove_x64.exe") && WinGetMinMax("ahk_exe Trove_x64.exe") != -1) {
            WinGetClientPos(&gx, &gy, &gw, &gh, "ahk_exe Trove_x64.exe")
            x := gx + Max(0, gw - larguraAvisoPainel - 10)
            y := gy + 10
        }
    }
    if (x != ultimoX || y != ultimoY || !DllCall("IsWindowVisible", "Ptr", avisoPainel.Hwnd)) {
        fundoAvisoPainel.Show("NA x" x " y" y " w" larguraAvisoPainel " h" alturaAvisoPainel)
        avisoPainel.Show("NA x" x " y" y " w" larguraAvisoPainel " h" alturaAvisoPainel)
        ultimoX := x
        ultimoY := y
    }
}

AtualizarPainel() {
    global painel, fundoPainel, camposPainel, ativo, convidarAmigos, estado, fimPausa
    global errosPainel
    global painelVisivel
    global cronometroConfirmado
    global inicioValidacaoCronometro, TEMPO_VALIDACAO_CRONOMETRO, inicioSemFocoCronometro
    global ultimoChat, INTERVALO_CHAT, recuperandoErrorHandler
    global PAINEL_LARGURA, PAINEL_ALTURA
    static ultimoX := "", ultimoY := ""

    if (!painelVisivel) {
        AtualizarAvisoPainel()
        return
    }

    AtualizarCampoPainel("auto", ativo ? "✓" : "✕", ativo ? "72E6A0" : "FF7272")
    AtualizarCampoPainel("amigos", convidarAmigos ? "✓" : "✕", convidarAmigos ? "72E6A0" : "FF7272")

    nomesEstados := Map("PARADO", "", "PROCURANDO", "Procurando ship",
        "CARREGANDO", "Aguardando o mundo carregar", "CONVIDANDO", "Convidando amigos", "DUNGEON", "Farmando na dungeon",
        "RESSUSCITANDO", "Aguardando ressurgir", "VERIFICANDO_DUNGEON", "Verificando dungeon atual")
    descricao := nomesEstados.Has(estado) ? nomesEstados[estado] : estado
    if (estado = "DUNGEON" && !cronometroConfirmado)
        descricao := "Validando cronometro"
    if (recuperandoErrorHandler)
        descricao := "Recuperando crash"
    else if (ativo && !WinActive("ahk_exe Trove_x64.exe"))
        descricao := "Trove está sem foco"
    AtualizarCampoPainel("estado", descricao = "" ? "" : "Estado: " descricao)

    tempo := ""
    if (ativo && !cronometroConfirmado && (estado = "DUNGEON" || estado = "CONVIDANDO")) {
        ; A exibicao tambem congela durante a perda de foco, como a validacao.
        agoraValidacao := inicioSemFocoCronometro != 0 ? inicioSemFocoCronometro : A_TickCount
        segundos := Max(0, Ceil((TEMPO_VALIDACAO_CRONOMETRO - (agoraValidacao - inicioValidacaoCronometro)) / 1000))
        tempo := "Timer: " Format("{:02}:{:02}", Floor(segundos / 60), Mod(segundos, 60))
    } else if (ativo && fimPausa > 0 && (estado = "DUNGEON" || estado = "CONVIDANDO")) {
        segundos := Max(0, Ceil((fimPausa - A_TickCount) / 1000))
        tempo := "Timer: " Format("{:02}:{:02}", Floor(segundos / 60), Mod(segundos, 60))
    } else if (ativo && estado = "PROCURANDO") {
        segundos := ultimoChat = 0 ? 0 : Max(0, Ceil((INTERVALO_CHAT - (A_TickCount - ultimoChat)) / 1000))
        tempo := "Proxima msg: " Format("{:02}:{:02}", Floor(segundos / 60), Mod(segundos, 60))
    }
    AtualizarCampoPainel("tempo", tempo)

    if (errosPainel.Count) {
        AtualizarCampoPainel("erroTitulo", "ERRO - " errosPainel.Count " pendente(s)")
        detalhe := ""
        for origem, mensagem in errosPainel
            detalhe .= (detalhe = "" ? "" : "`n") origem ": " mensagem
        AtualizarCampoPainel("erro", SubStr(detalhe, 1, 260))
    } else {
        AtualizarCampoPainel("erroTitulo", "")
        AtualizarCampoPainel("erro", "")
    }

    MonitorGetWorkArea(MonitorGetPrimary(), &esquerda, &topo, &direita, &base)
    px := Max(esquerda, direita - PAINEL_LARGURA - 10)
    py := topo + Max(0, Round((base - topo - PAINEL_ALTURA) / 2))
    try {
        if (WinExist("ahk_exe Trove_x64.exe") && WinGetMinMax("ahk_exe Trove_x64.exe") != -1) {
            WinGetClientPos(&gx, &gy, &gw, &gh, "ahk_exe Trove_x64.exe")
            px := gx + Max(0, gw - PAINEL_LARGURA - 10)
            py := gy + Max(0, Round((gh - PAINEL_ALTURA) / 2))
        }
    }
    if (px != ultimoX || py != ultimoY || !DllCall("IsWindowVisible", "Ptr", painel.Hwnd)) {
        opcoesPainel := "NA x" px " y" py " w" PAINEL_LARGURA " h" PAINEL_ALTURA
        fundoPainel.Show(opcoesPainel)
        painel.Show(opcoesPainel)
        ultimoX := px
        ultimoY := py
    }
}

AtualizarCampoPainel(chave, texto, cor := "") {
    global camposPainel
    static textos := Map(), cores := Map()

    ; Evita redesenhar campos identicos a cada disparo do timer de 500 ms.
    if (cor != "" && (!cores.Has(chave) || cores[chave] != cor)) {
        camposPainel[chave].Opt("c" cor)
        cores[chave] := cor
    }
    if (!textos.Has(chave) || textos[chave] != texto) {
        camposPainel[chave].Text := texto
        textos[chave] := texto
    }
}

RegistrarErro(origem, mensagem) {
    global errosPainel
    errosPainel[origem] := mensagem
    AtualizarPainel()
}

LimparErro(origem) {
    global errosPainel
    if errosPainel.Has(origem)
        errosPainel.Delete(origem)
}

RegistrarLeitura(mensagem) {
    global ultimaLeituraPainel
    ultimaLeituraPainel := mensagem
}

; ===== ATUALIZACAO DOS AVISOS NO PAINEL =====

Avisar(*) {
    ; Estados, indicadores e erros do painel substituem os avisos flutuantes.
    AtualizarPainel()
}

; ===== OCR DO WINDOWS INCORPORADO =====
CodigoOCR() {
    codigo := ""
    codigo .= "$ErrorActionPreference = 'Stop'" . "`n"
    codigo .= "$result = 'ERRO'" . "`n"
    codigo .= "try {" . "`n"
    codigo .= "    Add-Type -AssemblyName System.Drawing" . "`n"
    codigo .= "    Add-Type -AssemblyName System.Runtime.WindowsRuntime" . "`n"
    codigo .= "    [Windows.Media.Ocr.OcrEngine,Windows.Foundation,ContentType=WindowsRuntime] | Out-Null" . "`n"
    codigo .= "    [Windows.Graphics.Imaging.BitmapDecoder,Windows.Foundation,ContentType=WindowsRuntime] | Out-Null" . "`n"
    codigo .= "    [Windows.Storage.Streams.InMemoryRandomAccessStream,Windows.Foundation,ContentType=WindowsRuntime] | Out-Null" . "`n"
    codigo .= "    $awaitMethod = [System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object {" . "`n"
    codigo .= "        $_.Name -eq 'AsTask' -and $_.IsGenericMethod -and $_.GetParameters().Count -eq 1 -and" . "`n"
    codigo .= "        $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation``1'" . "`n"
    codigo .= "    } | Select-Object -First 1" . "`n"
    codigo .= "    function Await($operation, [Type]$returnType) {" . "`n"
    codigo .= "        $task = $awaitMethod.MakeGenericMethod($returnType).Invoke($null, @($operation))" . "`n"
    codigo .= "        $task.GetAwaiter().GetResult()" . "`n"
    codigo .= "    }" . "`n"
    codigo .= "    $engine = [Windows.Media.Ocr.OcrEngine]::TryCreateFromUserProfileLanguages()" . "`n"
    codigo .= "    if ($null -eq $engine) { throw 'OCR indisponivel no Windows' }" . "`n"
    codigo .= "    $bitmap = New-Object System.Drawing.Bitmap($Width, $Height)" . "`n"
    codigo .= "    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)" . "`n"
    codigo .= "    try {" . "`n"
    codigo .= "        if ($ImagePath) {" . "`n"
    codigo .= "            $source = [System.Drawing.Image]::FromFile($ImagePath)" . "`n"
    codigo .= "            try {" . "`n"
    codigo .= "                $graphics.DrawImage($source, [System.Drawing.Rectangle]::new(0,0,$Width,$Height)," . "`n"
    codigo .= "                    [System.Drawing.Rectangle]::new($X,$Y,$Width,$Height), [System.Drawing.GraphicsUnit]::Pixel)" . "`n"
    codigo .= "            } finally { $source.Dispose() }" . "`n"
    codigo .= "        } else {" . "`n"
    codigo .= "            Add-Type @'" . "`n"
    codigo .= "using System;" . "`n"
    codigo .= "using System.Runtime.InteropServices;" . "`n"
    codigo .= "public static class TroveForeground {" . "`n"
    codigo .= "    [DllImport(`"user32.dll`")] public static extern IntPtr GetForegroundWindow();" . "`n"
    codigo .= "    [DllImport(`"user32.dll`")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint p);" . "`n"
    codigo .= "}" . "`n"
    codigo .= "'@" . "`n"
    codigo .= "            [uint32]$foregroundId = 0" . "`n"
    codigo .= "            [TroveForeground]::GetWindowThreadProcessId([TroveForeground]::GetForegroundWindow(), [ref]$foregroundId) | Out-Null" . "`n"
    codigo .= "            if ((Get-Process -Id $foregroundId).ProcessName -ne 'Trove_x64') { throw 'Jogo sem foco' }" . "`n"
    codigo .= "            $graphics.CopyFromScreen($X,$Y,0,0,$bitmap.Size)" . "`n"
    codigo .= "        }" . "`n"
    codigo .= "        $scale = [Math]::Min(3.0, [Windows.Media.Ocr.OcrEngine]::MaxImageDimension / [double][Math]::Max($Width, $Height))" . "`n"
    codigo .= "        $scaled = New-Object System.Drawing.Bitmap(([int][Math]::Floor($Width*$scale)), ([int][Math]::Floor($Height*$scale)))" . "`n"
    codigo .= "        $scaleGraphics = [System.Drawing.Graphics]::FromImage($scaled)" . "`n"
    codigo .= "        $memory = New-Object System.IO.MemoryStream" . "`n"
    codigo .= "        $stream = New-Object Windows.Storage.Streams.InMemoryRandomAccessStream" . "`n"
    codigo .= "        try {" . "`n"
    codigo .= "            $scaleGraphics.DrawImage($bitmap,0,0,$scaled.Width,$scaled.Height)" . "`n"
    codigo .= "            $scaled.Save($memory,[System.Drawing.Imaging.ImageFormat]::Png)" . "`n"
    codigo .= "            $writer = New-Object Windows.Storage.Streams.DataWriter($stream)" . "`n"
    codigo .= "            try {" . "`n"
    codigo .= "                $writer.WriteBytes($memory.ToArray())" . "`n"
    codigo .= "                Await ($writer.StoreAsync()) ([uint32]) | Out-Null" . "`n"
    codigo .= "                $writer.DetachStream() | Out-Null" . "`n"
    codigo .= "            } finally { $writer.Dispose() }" . "`n"
    codigo .= "            $stream.Seek(0)" . "`n"
    codigo .= "            $decoder = Await ([Windows.Graphics.Imaging.BitmapDecoder]::CreateAsync($stream)) ([Windows.Graphics.Imaging.BitmapDecoder])" . "`n"
    codigo .= "            $softwareBitmap = Await ($decoder.GetSoftwareBitmapAsync()) ([Windows.Graphics.Imaging.SoftwareBitmap])" . "`n"
    codigo .= "            try {" . "`n"
    codigo .= "                $recognized = Await ($engine.RecognizeAsync($softwareBitmap)) ([Windows.Media.Ocr.OcrResult])" . "`n"
    codigo .= "                if ($Diagnostico) { Write-Output $recognized.Text }" . "`n"
    codigo .= "                if ($Mode -eq 'MORTE') {" . "`n"
    codigo .= "                    $plain = $recognized.Text -replace '\s+', ' '" . "`n"
    codigo .= "                    $compact = $plain -replace '[^\p{L}\p{Nd}]', ''" . "`n"
    codigo .= "                    $title = $compact -match '(?i)(aguardandoressur|awaitingresur|waiting(?:for)?resur|waitingtorespawn)'" . "`n"
    codigo .= "                    $prompt = $plain -match '(?i)(?:press(?:ione)?|pressione).*?(?:\[|\b)e(?:\]|\b).*?(?:liberar|release|respawn|reviv|ressus)'" . "`n"
    codigo .= "                    $result = if ($title -or $prompt) { 'MORTO' } else { 'VIVO' }" . "`n"
    codigo .= "                } else {" . "`n"
    codigo .= "                $text = $recognized.Text -replace '\s','' -replace '[Oo]','0'" . "`n"
    codigo .= "                # A fonte do jogo pode ser reconhecida como oo seguido de pontos." . "`n"
    codigo .= "                $text = $text -replace '[.:\u2022\u00B7]+', ':'" . "`n"
    codigo .= "                if ($text -match '(?<!\d)(\d{1,2})[:.](\d{2})(?!\d)' -and [int]$Matches[2] -lt 60) {" . "`n"
    codigo .= "                    $result = if ([int]$Matches[1] -eq 0 -and [int]$Matches[2] -eq 0) { 'ZERO' } else { 'ATIVO' }" . "`n"
    codigo .= "                } elseif ($recognized.Text -match '(?i)(star\s*dungeon|estrela|masmorra)' -or $text -match '\d{1,2}:\d*') {" . "`n"
    codigo .= "                    $result = 'ILEGIVEL'" . "`n"
    codigo .= "                } else { $result = 'AUSENTE' }" . "`n"
    codigo .= "                if ($Mode -eq 'ENTRADA') {" . "`n"
    codigo .= "                    $title = $recognized.Text -replace '[^\p{L}\p{Nd}]', ''" . "`n"
    codigo .= "                    $fiveStar = $title -match '(?i)(5stardungeon|5estrelas|masmorra5)'" . "`n"
    codigo .= "                    $otherDungeon = $title -match '(?i)(\d+stardungeon|\d+estrelas|masmorra\d+)'" . "`n"
    codigo .= "                    if (!$fiveStar -and ($otherDungeon -or $result -eq 'ATIVO')) { $result = 'AUSENTE' }" . "`n"
    codigo .= "                }" . "`n"
    codigo .= "                }" . "`n"
    codigo .= "            } finally { $softwareBitmap.Dispose() }" . "`n"
    codigo .= "        } finally {" . "`n"
    codigo .= "            $stream.Dispose(); $memory.Dispose(); $scaleGraphics.Dispose(); $scaled.Dispose()" . "`n"
    codigo .= "        }" . "`n"
    codigo .= "    } finally { $graphics.Dispose(); $bitmap.Dispose() }" . "`n"
    codigo .= "} catch { $result = if ($_.Exception.Message -eq 'Jogo sem foco') { 'SEM_FOCO' } else { 'ERRO' }; if ($Diagnostico) { Write-Output $_.Exception.Message } }" . "`n"
    codigo .= "[System.IO.File]::WriteAllText($OutputPath, $result, [System.Text.Encoding]::ASCII)" . "`n"
    return codigo
}

; ===== VERSOES, PATCH NOTES E ATUALIZADOR =====

F2::MostrarVersoes()

IniciarAtualizacoes() {
    A_TrayMenu.Add("Patch notes", MostrarVersoes)
    A_TrayMenu.Add("Verificar atualizações", (*) => VerificarAtualizacoes())
    A_TrayMenu.OnClick := 1
    OnExit(LimparAtualizacao)
    SetTimer(VerificarAtualizacoes, -1500)
}

MostrarVersoes(*) {
    global janelaVersoes, camposVersoes, VERSAO, statusAtualizacao, FONTE_PAINEL, COR_BARRA_LATERAL
    if !IsObject(janelaVersoes) {
        janelaVersoes := Gui("+Resize +MinSize660x460", "USFT - Patch notes")
        janelaVersoes.BackColor := "101416"
        janelaVersoes.SetFont("s10 cE7EDF5", FONTE_PAINEL)
        camposVersoes["barra"] := janelaVersoes.AddText("x0 y0 w4 h700 Background" COR_BARRA_LATERAL)
        janelaVersoes.SetFont("s20 bold cFFFFFF")
        janelaVersoes.AddText("x24 y20 w130 h34", "USFT")
        janelaVersoes.SetFont("s10 norm cA9B7C9")
        janelaVersoes.AddText("x154 y30 w460 h24", "Patch notes")
        janelaVersoes.SetFont("s10 cE7EDF5")
        camposVersoes["versao"] := janelaVersoes.AddText("x24 y70 w672 h22", "Versão instalada  /  " VERSAO)
        camposVersoes["status"] := janelaVersoes.AddText("x24 y100 w672 h44 cA9B7C9", statusAtualizacao)
        janelaVersoes.SetFont("s10 bold cE7EDF5")
        camposVersoes["instalar"] := janelaVersoes.AddButton("x24 y154 w330 h36 +0xB", "Atualizar")
        camposVersoes["instalar"].OnEvent("Click", InstalarAtualizacao)
        repositorio := janelaVersoes.AddButton("x366 y154 w330 h36 +0xB", "Abrir repositório")
        repositorio.OnEvent("Click", (*) => Run("https://github.com/leosmsilvx/USFT"))
        camposVersoes["repositorio"] := repositorio
        OnMessage(0x2B, DesenharBotaoPatchNotes) ; WM_DRAWITEM: botoes nativos com tema escuro.
        janelaVersoes.SetFont("s11 bold cFFFFFF")
        janelaVersoes.AddText("x24 y214 w600 h24", "Histórico de atualizações")
        janelaVersoes.SetFont("s10 norm cE7EDF5")
        camposVersoes["notas"] := janelaVersoes.AddEdit("x24 y248 w672 h390 ReadOnly Multi +VScroll -HScroll -E0x200 Background191F23")
        ; Tema da barra de rolagem consistente com o fundo escuro em Windows compativeis.
        DllCall("UxTheme\SetWindowTheme", "Ptr", camposVersoes["notas"].Hwnd, "Str", "DarkMode_Explorer", "Ptr", 0)
        janelaVersoes.OnEvent("Size", RedimensionarPatchNotes)
        janelaVersoes.OnEvent("Close", (*) => janelaVersoes.Hide())
        janelaVersoes.OnEvent("Escape", (*) => janelaVersoes.Hide())
        modoEscuro := Buffer(4, 0)
        NumPut("Int", 1, modoEscuro)
        DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", janelaVersoes.Hwnd, "UInt", 20, "Ptr", modoEscuro, "UInt", 4)
    }
    VerificarAtualizacoes()
    altura := Min(700, Floor(A_ScreenHeight * 96 / A_ScreenDPI) - 100)
    janelaVersoes.Show("w720 h" Max(460, altura))
    ; O AutoHotkey redefine estilos de botao ao mostrar a janela; aplica o desenho depois.
    for chave in ["instalar", "repositorio"] {
        DllCall("UxTheme\SetWindowTheme", "Ptr", camposVersoes[chave].Hwnd, "Str", "", "Str", "")
        SendMessage(0xF4, 0xB, 1, camposVersoes[chave].Hwnd) ; BM_SETSTYLE / BS_OWNERDRAW
    }
}

RedimensionarPatchNotes(janela, estado, largura, altura) {
    global camposVersoes
    if (estado = -1)
        return
    camposVersoes["barra"].Move(, , , altura)
    for chave in ["versao", "status", "notas"]
        camposVersoes[chave].Move(, , largura - 48)
    camposVersoes["notas"].Move(, , , Max(100, altura - 272))
    larguraBotao := Floor((largura - 60) / 2)
    for indice, chave in ["instalar", "repositorio"]
        camposVersoes[chave].Move(24 + (indice - 1) * (larguraBotao + 12), , larguraBotao)
}

DesenharBotaoPatchNotes(wParam, lParam, msg, hwnd) {
    global janelaVersoes, camposVersoes
    if !IsObject(janelaVersoes) || hwnd != janelaVersoes.Hwnd
        return
    controle := NumGet(lParam, A_PtrSize = 8 ? 24 : 20, "Ptr")
    for chave in ["instalar", "repositorio"] {
        if camposVersoes.Has(chave) && camposVersoes[chave].Hwnd = controle {
            dc := NumGet(lParam, A_PtrSize = 8 ? 32 : 24, "Ptr")
            retangulo := lParam + (A_PtrSize = 8 ? 40 : 28)
            estado := NumGet(lParam, 16, "UInt")
            desabilitado := estado & 4
            fundo := desabilitado ? 0x201C19 : estado & 1 ? 0x504334 : 0x3A3026
            pincel := DllCall("gdi32\CreateSolidBrush", "UInt", fundo, "Ptr")
            DllCall("user32\FillRect", "Ptr", dc, "Ptr", retangulo, "Ptr", pincel)
            DllCall("gdi32\DeleteObject", "Ptr", pincel)
            pincel := DllCall("gdi32\CreateSolidBrush", "UInt", desabilitado ? 0x302A25 : 0x655342, "Ptr")
            DllCall("user32\FrameRect", "Ptr", dc, "Ptr", retangulo, "Ptr", pincel)
            DllCall("gdi32\DeleteObject", "Ptr", pincel)
            DllCall("gdi32\SetBkMode", "Ptr", dc, "Int", 1)
            DllCall("gdi32\SetTextColor", "Ptr", dc, "UInt", desabilitado ? 0x80756A : 0xF5EDE7)
            fonte := SendMessage(0x31, 0, 0, controle) ; WM_GETFONT
            anterior := DllCall("gdi32\SelectObject", "Ptr", dc, "Ptr", fonte, "Ptr")
            DllCall("user32\DrawTextW", "Ptr", dc, "Str", camposVersoes[chave].Text, "Int", -1, "Ptr", retangulo, "UInt", 0x825)
            if (estado & 16)
                DllCall("user32\DrawFocusRect", "Ptr", dc, "Ptr", retangulo)
            DllCall("gdi32\SelectObject", "Ptr", dc, "Ptr", anterior)
            return true
        }
    }
}

CarregarNotas(texto) {
    global camposVersoes
    ; Exibe todo o arquivo, mantendo a ordem das versoes e todas as notas.
    texto := RegExReplace(StrReplace(texto, "`r"), "m)^#{1,6}\h+", "")
    texto := RegExReplace(texto, "m)^-\h+", "• ")
    if camposVersoes.Has("notas")
        camposVersoes["notas"].Value := StrReplace(texto, "`n", "`r`n")
    return texto
}

AtualizarStatusVersoes(texto) {
    global statusAtualizacao, camposVersoes, versaoDisponivel, VERSAO, requisicaoAtualizacao
    statusAtualizacao := texto
    if camposVersoes.Has("status") {
        camposVersoes["status"].Text := texto
        camposVersoes["instalar"].Enabled := !IsObject(requisicaoAtualizacao)
            && versaoDisponivel != "" && CompararVersoes(versaoDisponivel, VERSAO) > 0 && !A_IsCompiled
    }
}

CompararVersoes(a, b) {
    if !RegExMatch(a, "^\d+\.\d+\.\d+$") || !RegExMatch(b, "^\d+\.\d+\.\d+$")
        throw Error("Versão inválida; esperado major.minor.patch.")
    partesA := StrSplit(a, "."), partesB := StrSplit(b, ".")
    Loop 3 {
        if (Integer(partesA[A_Index]) != Integer(partesB[A_Index]))
            return Integer(partesA[A_Index]) > Integer(partesB[A_Index]) ? 1 : -1
    }
    return 0
}

VerificarAtualizacoes(*) {
    global requisicaoAtualizacao, versaoDisponivel, codigoDisponivel, camposVersoes
    if IsObject(requisicaoAtualizacao)
        return
    versaoDisponivel := "", codigoDisponivel := ""
    if camposVersoes.Has("notas")
        camposVersoes["notas"].Value := "Carregando histórico do GitHub..."
    SolicitarArquivoAtualizacao("trove.ahk", "consulta")
}

SolicitarArquivoAtualizacao(arquivo, etapa) {
    global URL_ATUALIZACOES, requisicaoAtualizacao, etapaAtualizacao, inicioAtualizacao
    try {
        requisicaoAtualizacao := ComObject("WinHttp.WinHttpRequest.5.1")
        requisicaoAtualizacao.SetTimeouts(5000, 5000, 10000, 10000)
        requisicaoAtualizacao.Open("GET", URL_ATUALIZACOES arquivo "?t=" A_NowUTC, true)
        requisicaoAtualizacao.SetRequestHeader("Cache-Control", "no-cache")
        requisicaoAtualizacao.Send()
        etapaAtualizacao := etapa
        inicioAtualizacao := A_TickCount
        AtualizarStatusVersoes(etapa = "consulta" ? "Consultando a última versão no GitHub..." : "Baixando " arquivo "...")
        SetTimer(AcompanharAtualizacao, 100)
    } catch Error as erro {
        FalharAtualizacao(erro.Message)
    }
}

AcompanharAtualizacao() {
    global requisicaoAtualizacao, inicioAtualizacao, etapaAtualizacao
    global versaoDisponivel, codigoDisponivel, VERSAO, arquivosAtualizacao
    global indiceAtualizacao, pastaAtualizacao
    try {
        if !requisicaoAtualizacao.WaitForResponse(0) {
            if (A_TickCount - inicioAtualizacao > 30000)
                throw Error("Tempo limite ao consultar o GitHub.")
            return
        }
        SetTimer(AcompanharAtualizacao, 0)
        resposta := requisicaoAtualizacao
        requisicaoAtualizacao := 0
        if (resposta.Status != 200)
            throw Error("GitHub retornou HTTP " resposta.Status ". Tente novamente mais tarde.")
        if (etapaAtualizacao = "consulta") {
            codigoDisponivel := resposta.ResponseText
            versaoDisponivel := LerVersaoScript(codigoDisponivel)
            diferenca := CompararVersoes(versaoDisponivel, VERSAO)
            if (diferenca > 0)
                TrayTip("Versão " versaoDisponivel " disponível. Abra Patch notes pelo menu do USFT ou F2.", "USFT - Atualização")
            SolicitarArquivoAtualizacao("CHANGELOG.md", "notas")
            return
        }
        if (etapaAtualizacao = "notas") {
            CarregarNotas(resposta.ResponseText)
            diferenca := CompararVersoes(versaoDisponivel, VERSAO)
            AtualizarStatusVersoes(diferenca > 0 ? "Nova versão disponível: " versaoDisponivel ". Clique em Atualizar."
                : diferenca = 0 ? "Você está na última versão: " VERSAO "." : "Sua versão está à frente da publicada no GitHub.")
            return
        }
        arquivo := arquivosAtualizacao[indiceAtualizacao]
        destino := pastaAtualizacao "\" arquivo
        fluxo := ComObject("ADODB.Stream")
        fluxo.Type := 1
        fluxo.Open()
        try {
            fluxo.Write(resposta.ResponseBody)
            fluxo.SaveToFile(destino, 2)
        } finally {
            fluxo.Close()
        }
        ValidarArquivoAtualizacao(arquivo, FileRead(destino, "UTF-8"))
        indiceAtualizacao += 1
        if (indiceAtualizacao <= arquivosAtualizacao.Length)
            SolicitarArquivoAtualizacao(arquivosAtualizacao[indiceAtualizacao], "arquivo")
        else
            AplicarAtualizacao()
    } catch Error as erro {
        FalharAtualizacao(erro.Message)
    }
}

LerVersaoScript(texto) {
    ; Le apenas a declaracao de versao; nunca executa codigo remoto na consulta.
    if !RegExMatch(texto, 'm)^global VERSAO := "(\d+\.\d+\.\d+)"\r?$', &versao)
        throw Error("O trove.ahk publicado não contém uma VERSAO válida.")
    return versao[1]
}

ValidarArquivoAtualizacao(arquivo, texto) {
    global versaoDisponivel, codigoDisponivel
    if (arquivo = "trove.ahk") {
        if LerVersaoScript(texto) != versaoDisponivel
            || !(StrReplace(texto, "`r`n", "`n") == StrReplace(codigoDisponivel, "`r`n", "`n"))
            throw Error("O script publicado mudou desde a consulta. Verifique as atualizações novamente.")
    } else if (arquivo = "CHANGELOG.md") {
        if !InStr("`n" StrReplace(texto, "`r"), "`n## [" versaoDisponivel "]")
            throw Error("O CHANGELOG.md publicado não contém as notas da versão " versaoDisponivel ".")
    }
}

InstalarAtualizacao(*) {
    global ativo, instalandoAtualizacao, requisicaoAtualizacao, versaoDisponivel, VERSAO
    global pastaAtualizacao, indiceAtualizacao, arquivosAtualizacao
    if IsObject(requisicaoAtualizacao) || versaoDisponivel = "" || CompararVersoes(versaoDisponivel, VERSAO) <= 0
        return
    if A_IsCompiled {
        MsgBox("Execute trove.ahk com AutoHotkey v2 para usar a atualização automática.", "USFT")
        return
    }
    if ativo {
        MsgBox("Pause o farm com F11 antes de instalar a atualização.", "USFT")
        return
    }
    if MsgBox("Instalar a versão " versaoDisponivel " e reiniciar o USFT?`nUma cópia da versão atual será salva em backups. Seus amigos serão preservados.", "USFT", "YesNo Icon?") != "Yes"
        return
    ; Revalida: F11 pode ter sido acionado enquanto a confirmacao estava aberta.
    if ativo
        return
    instalandoAtualizacao := true
    pastaAtualizacao := A_Temp "\USFT-update-" ProcessExist() "-" A_TickCount
    try {
        DirCreate(pastaAtualizacao)
        indiceAtualizacao := 1
        SolicitarArquivoAtualizacao(arquivosAtualizacao[1], "arquivo")
    } catch Error as erro {
        FalharAtualizacao(erro.Message)
    }
}

AplicarAtualizacao() {
    global arquivosAtualizacao, pastaAtualizacao, versaoDisponivel, VERSAO
    global instalandoAtualizacao
    for arquivo in arquivosAtualizacao
        ValidarArquivoAtualizacao(arquivo, FileRead(pastaAtualizacao "\" arquivo, "UTF-8"))
    backup := A_ScriptDir "\backups\" VERSAO "-" A_Now "-" A_TickCount
    DirCreate(backup)
    existentes := Map(), alterados := []
    ; Faz todos os backups antes de substituir qualquer arquivo.
    for arquivo in arquivosAtualizacao {
        existentes[arquivo] := !!FileExist(A_ScriptDir "\" arquivo)
        if existentes[arquivo]
            FileCopy(A_ScriptDir "\" arquivo, backup "\" arquivo)
    }
    try {
        for arquivo in arquivosAtualizacao {
            alterados.Push(arquivo)
            FileCopy(pastaAtualizacao "\" arquivo, A_ScriptDir "\" arquivo, true)
        }
    } catch Error as erro {
        falhas := ""
        for arquivo in alterados {
            try {
                if existentes[arquivo]
                    FileCopy(backup "\" arquivo, A_ScriptDir "\" arquivo, true)
                else if FileExist(A_ScriptDir "\" arquivo)
                    FileDelete(A_ScriptDir "\" arquivo)
            } catch {
                falhas .= "`nRestaure manualmente: " arquivo
            }
        }
        throw Error(erro.Message "`nBackup: " backup falhas)
    }
    LimparAtualizacao()
    AtualizarStatusVersoes("Versão " versaoDisponivel " instalada. Reiniciando...")
    ; amigos.txt e configuracoes externas nunca entram na lista de substituicao.
    Reload()
}

FalharAtualizacao(mensagem) {
    global requisicaoAtualizacao, instalandoAtualizacao, etapaAtualizacao, camposVersoes
    SetTimer(AcompanharAtualizacao, 0)
    if IsObject(requisicaoAtualizacao) {
        try requisicaoAtualizacao.Abort()
    }
    requisicaoAtualizacao := 0
    if (etapaAtualizacao = "consulta" || etapaAtualizacao = "notas") && camposVersoes.Has("notas")
        camposVersoes["notas"].Value := "Não foi possível carregar o histórico do GitHub.`r`n" mensagem "`r`nAbra o F2 novamente para tentar outra vez."
    instalandoAtualizacao := false
    LimparAtualizacao()
    AtualizarStatusVersoes("Nao foi possível concluir: " mensagem)
}

LimparAtualizacao(*) {
    global pastaAtualizacao
    ; Remove somente a pasta temporaria criada por esta execucao.
    if pastaAtualizacao != "" && DirExist(pastaAtualizacao) {
        try DirDelete(pastaAtualizacao, true)
    }
    pastaAtualizacao := ""
}

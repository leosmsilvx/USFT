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


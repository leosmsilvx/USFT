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
    global inicioSafetyRespawn, carregamentoHubDetectado
    CancelarLeituraMorte()
    ultimaVerificacaoMorte := A_TickCount - INTERVALO_MORTE
    ultimaLeituraMorte := "Verificacao a cada 1 segundo"
    ressurreicaoConfirmada := false
    inicioMundoRessurreicao := 0
    inicioSafetyRespawn := 0
    carregamentoHubDetectado := false
    LimparErro("SAFETY")
}

AguardarRessurreicao() {
    global ressurreicaoConfirmada

    if (TelaPreta()) {
        ressurreicaoConfirmada := false
        return
    }
    if (!ressurreicaoConfirmada)
        return

    IniciarSafetyRespawn()
}

IniciarSafetyRespawn() {
    global ativo, estado, inicioSafetyRespawn, carregamentoHubDetectado
    global inicioMundoRessurreicao, ressurreicaoConfirmada

    if (!ativo || !WinActive("ahk_exe Trove_x64.exe") || TelaPreta())
        return

    CancelarLeituraMorte()
    ReiniciarCronometro()
    estado := "SAFETY_RESPAWN"
    ressurreicaoConfirmada := false
    carregamentoHubDetectado := false
    inicioMundoRessurreicao := 0
    SendEvent("^a")
    inicioSafetyRespawn := A_TickCount
    Avisar("SAFETY-RESPAWN - VOLTANDO AO HUB")
}

AguardarSafetyRespawn() {
    global ativo, estado, inicioSafetyRespawn, carregamentoHubDetectado
    global inicioMundoRessurreicao, DELAY_SAFETY_RESPAWN, LIMITE_SAFETY_RESPAWN
    global CONFIRMACAO_MUNDO

    if (!ativo || !WinActive("ahk_exe Trove_x64.exe"))
        return

    if (estado = "SAFETY_RESPAWN") {
        ; Se houve perda de foco, reabre o comando antes de confirmar.
        if (inicioSafetyRespawn = 0) {
            IniciarSafetyRespawn()
            return
        }
        if (A_TickCount - inicioSafetyRespawn < DELAY_SAFETY_RESPAWN || TelaPreta())
            return
        SendEvent("{e down}")
        try Sleep(100)
        finally SendEvent("{e up}")
        if (!ativo || estado != "SAFETY_RESPAWN")
            return
        estado := "AGUARDANDO_HUB"
        inicioSafetyRespawn := A_TickCount
        return
    }

    if (TelaPreta()) {
        carregamentoHubDetectado := true
        inicioMundoRessurreicao := 0
        return
    }
    if (carregamentoHubDetectado) {
        if (inicioMundoRessurreicao = 0)
            inicioMundoRessurreicao := A_TickCount
        if (A_TickCount - inicioMundoRessurreicao >= CONFIRMACAO_MUNDO) {
            LimparErro("SAFETY")
            RetomarBuscaShip("HUB CARREGADO - PROCURANDO SHIP")
        }
        return
    }

    ; Nunca libera chat ou convites sem observar a transicao para o HUB.
    if (A_TickCount - inicioSafetyRespawn >= LIMITE_SAFETY_RESPAWN) {
        RegistrarErro("SAFETY", "Carregamento do HUB nao detectado. Repetindo safety-respawn.")
        IniciarSafetyRespawn()
    }
}

VerificarMorte() {
    global ativo, processoMorte, resultadoMorte, ultimaVerificacaoMorte
    global ultimaRessurreicao, ultimaLeituraMorte, INTERVALO_MORTE, INTERVALO_RESSUSCITAR
    global estado, fimPausa, ressurreicaoConfirmada, inicioMundoRessurreicao
    global INTERVALO_CONFIRMAR_RESSURREICAO

    if (!ativo || !WinActive("ahk_exe Trove_x64.exe")) {
        CancelarLeituraMorte()
        return false
    }
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
    if (A_TickCount - ultimaVerificacaoMorte < intervalo || TelaPreta())
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


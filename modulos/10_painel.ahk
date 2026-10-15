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
        "F11: Iniciar/Parar | F9: Fechar`nF10: Alternar convites")
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


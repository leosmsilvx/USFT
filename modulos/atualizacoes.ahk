; ===== VERSOES, PATCH NOTES E ATUALIZADOR =====

global URL_ATUALIZACOES := URL_ARQUIVOS_USFT
global janelaVersoes := 0, camposVersoes := Map()
global versaoDisponivel := "", codigoDisponivel := ""
global requisicaoAtualizacao := 0, etapaAtualizacao := "", inicioAtualizacao := 0
global statusAtualizacao := "Aguardando consulta ao GitHub."
global instalandoAtualizacao := false, pastaAtualizacao := "", indiceAtualizacao := 0
global arquivosAtualizacao := ARQUIVOS_USFT.Clone()

IniciarAtualizacoes() {
    A_TrayMenu.Add("Patch notes", MostrarVersoes)
    A_TrayMenu.Add("Verificar atualizações", (*) => VerificarAtualizacoes())
    A_TrayMenu.OnClick := 1
    OnExit(LimparAtualizacao)
    ; Consulta assim que o programa inicia, sem depender do painel ou do F2.
    VerificarAtualizacoes()
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
        janelaVersoes.SetFont("s16 bold cFFD54A")
        camposVersoes["destaque"] := janelaVersoes.AddText("x24 y210 w672 h32 Center +0x200",
            "GRANDE NOTÍCIA! A VERSÃO OFICIAL 1.0.0 CHEGOU!")
        janelaVersoes.SetFont("s11 bold cFFFFFF")
        camposVersoes["historico"] := janelaVersoes.AddText("x24 y250 w672 h24", "Histórico de atualizações")
        janelaVersoes.SetFont("s10 norm cE7EDF5")
        camposVersoes["notas"] := janelaVersoes.AddEdit("x24 y282 w672 h354 ReadOnly Multi +VScroll -HScroll -E0x200 Background191F23")
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
    for chave in ["versao", "status", "destaque", "historico", "notas"]
        camposVersoes[chave].Move(, , largura - 48)
    camposVersoes["notas"].Move(, , , Max(100, altura - 306))
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
    texto := RegExReplace(NormalizarTextoAtualizacao(texto), "m)^#{1,6}\h+", "")
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
    ; As versoes 2.x publicadas durante os testes agora pertencem a serie beta b1.x.x.
    betasLegadas := Map("2.9.4", "b1.9.4", "2.10.0", "b1.10.0",
        "2.11.0", "b1.11.0", "2.11.1", "b1.12.1",
        "2.11.2", "b1.12.3", "2.11.3", "b1.12.3")
    if betasLegadas.Has(a)
        a := betasLegadas[a]
    if betasLegadas.Has(b)
        b := betasLegadas[b]

    betaA := RegExMatch(a, "^b(\d+\.\d+\.\d+)$", &partesBetaA)
    betaB := RegExMatch(b, "^b(\d+\.\d+\.\d+)$", &partesBetaB)
    if (betaA != betaB)
        return betaA ? -1 : 1

    versaoA := betaA ? partesBetaA[1] : a
    versaoB := betaB ? partesBetaB[1] : b
    if !RegExMatch(versaoA, "^\d+\.\d+\.\d+$") || !RegExMatch(versaoB, "^\d+\.\d+\.\d+$")
        throw Error("Versão inválida; esperado major.minor.patch ou bmajor.minor.patch.")
    partesA := StrSplit(versaoA, "."), partesB := StrSplit(versaoB, ".")
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
        requisicaoAtualizacao.Open("GET", URL_ATUALIZACOES StrReplace(arquivo, "\", "/") "?t=" A_NowUTC, true)
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
            codigoDisponivel := NormalizarTextoAtualizacao(resposta.ResponseText)
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
        SplitPath(destino, , &diretorioDestino)
        DirCreate(diretorioDestino)
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

NormalizarTextoAtualizacao(texto) {
    ; ResponseText preserva o BOM UTF-8, mas FileRead UTF-8 o remove.
    return StrReplace(LTrim(texto, Chr(0xFEFF)), "`r`n", "`n")
}

LerVersaoScript(texto) {
    ; Le apenas a declaracao de versao; nunca executa codigo remoto na consulta.
    if !RegExMatch(NormalizarTextoAtualizacao(texto), 'm)^global VERSAO := "(\d+\.\d+\.\d+)"$', &versao)
        throw Error("O trove.ahk publicado não contém uma VERSAO válida.")
    return versao[1]
}

ValidarArquivoAtualizacao(arquivo, texto) {
    global versaoDisponivel, codigoDisponivel
    if (arquivo = "trove.ahk") {
        if LerVersaoScript(texto) != versaoDisponivel
            || !(NormalizarTextoAtualizacao(texto) == NormalizarTextoAtualizacao(codigoDisponivel))
            throw Error("O script publicado mudou desde a consulta. Verifique as atualizações novamente.")
    } else if (arquivo = "CHANGELOG.md") {
        if !InStr("`n" NormalizarTextoAtualizacao(texto), "`n## [" versaoDisponivel "]")
            throw Error("O CHANGELOG.md publicado não contém as notas da versão " versaoDisponivel ".")
    } else if (InStr(arquivo, "modulos\") = 1) {
        if (StrLen(Trim(texto)) < 20 || !InStr(codigoDisponivel, arquivo))
            throw Error("Módulo inválido ou não referenciado pelo trove.ahk: " arquivo ".")
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
    if MsgBox("Instalar a versão " versaoDisponivel " e reiniciar o USFT?`nSeus amigos serão preservados.", "USFT", "YesNo Icon?") != "Yes"
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
    backup := pastaAtualizacao "\recuperacao"
    DirCreate(backup)
    existentes := Map(), alterados := []
    ; Copias somente na pasta temporaria, removidas apos a atualizacao.
    for arquivo in arquivosAtualizacao {
        existentes[arquivo] := !!FileExist(A_ScriptDir "\" arquivo)
        if existentes[arquivo] {
            destinoBackup := backup "\" arquivo
            SplitPath(destinoBackup, , &diretorioBackup)
            DirCreate(diretorioBackup)
            FileCopy(A_ScriptDir "\" arquivo, destinoBackup)
        }
    }
    try {
        for arquivo in arquivosAtualizacao {
            alterados.Push(arquivo)
            destinoFinal := A_ScriptDir "\" arquivo
            SplitPath(destinoFinal, , &diretorioFinal)
            DirCreate(diretorioFinal)
            FileCopy(pastaAtualizacao "\" arquivo, destinoFinal, true)
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
        if (falhas != "") {
            ; Preserva a recuperacao temporaria se algum arquivo nao puder ser restaurado.
            pastaAtualizacao := ""
            throw Error(erro.Message "`nCópia de recuperação: " backup falhas)
        }
        throw Error(erro.Message "`nOs arquivos anteriores foram restaurados.")
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

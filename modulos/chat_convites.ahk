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
    if FileExist(ARQUIVO_AMIGOS)
        return
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


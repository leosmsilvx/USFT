; ===== ATALHOS =====

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

; CTRL + ALT + O - ENCERRAR

^!o::ExitApp()

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

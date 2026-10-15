; ===== CONTROLE DO FARM =====

IniciarFarm() {
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

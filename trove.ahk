#Requires AutoHotkey v2.0
#SingleInstance Force

SendMode("Input")
CoordMode("Pixel", "Client")

; Configuracoes e estado precisam ser carregados antes da inicializacao.
#Include "%A_ScriptDir%\modulos\01_configuracao.ahk"
#Include "%A_ScriptDir%\modulos\02_estado.ahk"

; Este e o unico arquivo que o usuario precisa executar.
IniciarPainel()
SetTimer(AtualizarPainel, 500)

; Modulos internos da aplicacao.
#Include "%A_ScriptDir%\modulos\03_farm.ahk"
#Include "%A_ScriptDir%\modulos\04_monitor.ahk"
#Include "%A_ScriptDir%\modulos\05_watchdog.ahk"
#Include "%A_ScriptDir%\modulos\06_cronometro.ahk"
#Include "%A_ScriptDir%\modulos\07_tela.ahk"
#Include "%A_ScriptDir%\modulos\08_chat_convites.ahk"
#Include "%A_ScriptDir%\modulos\09_morte.ahk"
#Include "%A_ScriptDir%\modulos\10_painel.ahk"
#Include "%A_ScriptDir%\modulos\11_ocr.ahk"

; Hotkeys ficam por ultimo para encerrar corretamente a secao de inicializacao.
#Include "%A_ScriptDir%\modulos\12_atalhos.ahk"

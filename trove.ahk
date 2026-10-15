#Requires AutoHotkey v2.0
#SingleInstance Force

; Mantida no arquivo principal: clientes instalados consultam esta linha no GitHub.
global VERSAO := "2.11.0"
global URL_ARQUIVOS_USFT := "https://raw.githubusercontent.com/leosmsilvx/USFT/main/"
global ARQUIVOS_USFT := [
    "trove.ahk",
    "CHANGELOG.md",
    "README.MD",
    "modulos\configuracao.ahk",
    "modulos\estado.ahk",
    "modulos\farm.ahk",
    "modulos\monitor.ahk",
    "modulos\watchdog.ahk",
    "modulos\cronometro.ahk",
    "modulos\tela.ahk",
    "modulos\chat_convites.ahk",
    "modulos\morte.ahk",
    "modulos\painel.ahk",
    "modulos\ocr.ahk",
    "modulos\atualizacoes.ahk",
    "modulos\atalhos.ahk"
]

SendMode("Input")
CoordMode("Pixel", "Client")

; Includes opcionais permitem que clientes 2.10 baixem primeiro este bootstrap.
#Include *i "%A_ScriptDir%\modulos\configuracao.ahk"
#Include *i "%A_ScriptDir%\modulos\estado.ahk"
#Include *i "%A_ScriptDir%\modulos\farm.ahk"
#Include *i "%A_ScriptDir%\modulos\monitor.ahk"
#Include *i "%A_ScriptDir%\modulos\watchdog.ahk"
#Include *i "%A_ScriptDir%\modulos\cronometro.ahk"
#Include *i "%A_ScriptDir%\modulos\tela.ahk"
#Include *i "%A_ScriptDir%\modulos\chat_convites.ahk"
#Include *i "%A_ScriptDir%\modulos\morte.ahk"
#Include *i "%A_ScriptDir%\modulos\painel.ahk"
#Include *i "%A_ScriptDir%\modulos\ocr.ahk"
#Include *i "%A_ScriptDir%\modulos\atualizacoes.ahk"

if !ModulosUSFTDisponiveis() {
    try {
        InstalarModulosUSFT()
        Reload()
    } catch Error as erro {
        MsgBox("Não foi possível instalar os módulos da versão " VERSAO ".`n`n" erro.Message
            . "`n`nBaixe o pacote completo no repositório.", "USFT - Atualização")
    }
    ExitApp()
}

try Func("GarantirArquivoAmigos").Call()
catch Error as erro
    errosPainel["AMIGOS"] := "Não foi possível criar amigos.txt: " erro.Message
Func("IniciarPainel").Call()
Func("IniciarAtualizacoes").Call()
SetTimer(Func("AtualizarPainel"), 500)

; Hotkeys ficam por ultimo para encerrar corretamente a secao de inicializacao.
#Include *i "%A_ScriptDir%\modulos\atalhos.ahk"

ModulosUSFTDisponiveis() {
    global ARQUIVOS_USFT
    for arquivo in ARQUIVOS_USFT {
        if (InStr(arquivo, "modulos\") = 1 && !FileExist(A_ScriptDir "\" arquivo))
            return false
    }
    return true
}

InstalarModulosUSFT() {
    global ARQUIVOS_USFT, URL_ARQUIVOS_USFT
    pastaTemporaria := A_Temp "\USFT-bootstrap-" ProcessExist() "-" A_TickCount
    DirCreate(pastaTemporaria)
    try {
        for arquivo in ARQUIVOS_USFT {
            if (InStr(arquivo, "modulos\") != 1)
                continue
            requisicao := ComObject("WinHttp.WinHttpRequest.5.1")
            requisicao.SetTimeouts(5000, 5000, 15000, 15000)
            requisicao.Open("GET", URL_ARQUIVOS_USFT StrReplace(arquivo, "\", "/") "?t=" A_NowUTC, false)
            requisicao.SetRequestHeader("Cache-Control", "no-cache")
            requisicao.Send()
            if (requisicao.Status != 200)
                throw Error("GitHub retornou HTTP " requisicao.Status " para " arquivo ".")

            destinoTemporario := pastaTemporaria "\" arquivo
            SplitPath(destinoTemporario, , &diretorioTemporario)
            DirCreate(diretorioTemporario)
            fluxo := ComObject("ADODB.Stream")
            fluxo.Type := 1
            fluxo.Open()
            try {
                fluxo.Write(requisicao.ResponseBody)
                fluxo.SaveToFile(destinoTemporario, 2)
            } finally {
                fluxo.Close()
            }
            if (FileGetSize(destinoTemporario) < 20)
                throw Error("Módulo inválido recebido: " arquivo ".")
        }

        for arquivo in ARQUIVOS_USFT {
            if (InStr(arquivo, "modulos\") != 1)
                continue
            destinoFinal := A_ScriptDir "\" arquivo
            SplitPath(destinoFinal, , &diretorioFinal)
            DirCreate(diretorioFinal)
            FileCopy(pastaTemporaria "\" arquivo, destinoFinal, true)
        }
    } finally {
        if DirExist(pastaTemporaria)
            DirDelete(pastaTemporaria, true)
    }
}

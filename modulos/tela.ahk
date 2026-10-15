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


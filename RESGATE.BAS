REM RESGATE - exemplo de plataformas para FOBOS QB 1.8 / 1.9
REM Original inspirado no genero de H.E.R.O.; graficos proprios.
REM Ecra 640x200. Nao precisa de imagens nem de outros ficheiros.
REM SETAS: andar / voar. ESPACO: laser. BAIXO: bomba. ESC: sair.
REM Objetivo: tocar no mineiro e voltar a porta verde.
REM SUB faz uma tarefa; FUNCTION calcula e devolve um resultado.
REM As variaveis SHARED pertencem ao jogo; as restantes sao locais.

SCREEN 1
CLS
DIM SHARED TITULO, JOGAR, PASSOU, GANHOU, PERDEU, SAIR, Estado
TITULO = 0
JOGAR = 1
PASSOU = 2
GANHOU = 3
PERDEU = 4
SAIR = 9
DIM SHARED Nivel, Vidas, Pontos, Resgatado, Combustivel, Bombas
DIM SHARED Direcao, Tecla, Fogo, FogoAntes, Baixo, BaixoAntes, Voar
DIM SHARED JX AS SINGLE, JY AS SINGLE, VelY AS SINGLE
DIM SHARED Invencivel, Tique, NoChao
DIM SHARED Mapa$(9), Bloco(199)
DIM SHARED InimigoX(2), InimigoY(2), InimigoDir(2), InimigoVivo(2)
DIM SHARED TiroAtivo, TiroX, TiroY, TiroDir, Recarga
DIM SHARED BombaTempo, BombaX, BombaY, ExplosaoTempo
CALL CriarSprites
CALL MostrarTitulo
Estado = TITULO

REM Cada volta e uma imagem. SELECT escolhe a fase do jogo.
DO
  CALL LerComandos
  IF STRIG(6) <> 0 THEN Estado = SAIR
  SELECT CASE Estado
  CASE TITULO, GANHOU, PERDEU
    IF Fogo <> 0 AND FogoAntes = 0 THEN
      Nivel = 1
      Vidas = 3
      Pontos = 0
      CALL PrepararNivel
      Estado = JOGAR
    END IF
  CASE JOGAR
    CALL EsconderSprites
    CALL MoverJogador
    CALL AtualizarLaser
    CALL AtualizarBomba
    CALL MoverInimigos
    CALL VerificarObjetivo
    IF Estado = JOGAR THEN
      CALL DesenharSprites
      Tique = Tique + 1
      IF Tique MOD 8 = 0 THEN CALL DesenharPainel
    ELSE
      CALL MostrarResultado
    END IF
  CASE PASSOU
    IF Fogo <> 0 AND FogoAntes = 0 THEN
      Nivel = Nivel + 1
      CALL PrepararNivel
      Estado = JOGAR
    END IF
  END SELECT
  FogoAntes = Fogo
  BaixoAntes = Baixo
  PAUSE 20
LOOP UNTIL Estado = SAIR
CALL EsconderSprites
CLS
END

REM 1. COMANDOS: STICK inclui as quatro direcoes diagonais.
SUB LerComandos
  Tecla = STICK(0)
  Fogo = STRIG(0)
  Baixo = 0
  Voar = 0
  SELECT CASE Tecla
  CASE 1, 2, 8
    Voar = 1
  CASE 4, 5, 6
    Baixo = 1
  END SELECT
END SUB

REM 2. MAPAS: cada texto tem 20 celulas, cada celula mede 32x16.
REM # pedra, . ar, ~ lava, X parede que a bomba pode destruir.
SUB PrepararNivel
  CALL EsconderSprites
  CLS
  SELECT CASE Nivel
  CASE 1
    Mapa$(0) = "####################"
    Mapa$(1) = "#..................#"
    Mapa$(2) = "#..................#"
    Mapa$(3) = "#####..............#"
    Mapa$(4) = "#..........###.....#"
    Mapa$(5) = "#.....###..........#"
    Mapa$(6) = "#..................#"
    Mapa$(7) = "#..###.......###...#"
    Mapa$(8) = "#..................#"
    Mapa$(9) = "######~~~~~~~#######"
  CASE 2
    Mapa$(0) = "####################"
    Mapa$(1) = "#.........X........#"
    Mapa$(2) = "#.........X........#"
    Mapa$(3) = "#####.....X........#"
    Mapa$(4) = "#.........X...###..#"
    Mapa$(5) = "#......###X........#"
    Mapa$(6) = "#.........X........#"
    Mapa$(7) = "#..###....X..###...#"
    Mapa$(8) = "#.........X........#"
    Mapa$(9) = "#######~~~~~~#######"
  CASE 3
    Mapa$(0) = "####################"
    Mapa$(1) = "#..................#"
    Mapa$(2) = "#..........X.......#"
    Mapa$(3) = "#####......X.......#"
    Mapa$(4) = "#.......####.......#"
    Mapa$(5) = "#..............###.#"
    Mapa$(6) = "#.....###..........#"
    Mapa$(7) = "#............###...#"
    Mapa$(8) = "#..................#"
    Mapa$(9) = "#####~~~~~~~~#######"
  END SELECT
  FOR Linha = 0 TO 9
    FOR Coluna = 0 TO 19
      Tipo = 0
      SELECT CASE MID$(Mapa$(Linha), Coluna + 1, 1)
      CASE "#"
        Tipo = 1
      CASE "~"
        Tipo = 2
      CASE "X"
        Tipo = 3
      END SELECT
      Bloco(Linha * 20 + Coluna) = Tipo
      CALL DesenharCelula(Coluna, Linha)
    NEXT Coluna
  NEXT Linha
  REM Porta e mineiro ficam em zonas protegidas da lava.
  LINE (40, 48)-(65, 71), 10, B
  LINE (44, 50)-(61, 71), 2, BF
  JX = 48
  JY = 54
  VelY = 0
  Direcao = 1
  Resgatado = 0
  Combustivel = 1000
  Bombas = 3
  Invencivel = 60
  TiroAtivo = 0
  Recarga = 0
  BombaTempo = 0
  ExplosaoTempo = 0
  Tique = 0
  FOR I = 0 TO 2
    InimigoX(I) = 260 + I * 130
    InimigoY(I) = 48 + I * 44
    InimigoDir(I) = 1
    InimigoVivo(I) = 1
  NEXT I
  InimigoY(1) = 108
  InimigoY(2) = 152
  IF Nivel = 1 THEN InimigoVivo(2) = 0
  COLOR 7
  LOCATE 24, 2
  PRINT "SETAS: mover/voar  ESPACO: laser  BAIXO: bomba  ESC: sair";
  CALL DesenharPainel
  CALL DesenharSprites
END SUB

SUB DesenharCelula(Coluna, Linha)
  X = Coluna * 32
  Y = 24 + Linha * 16
  Tipo = Bloco(Linha * 20 + Coluna)
  LINE (X, Y)-(X + 31, Y + 15), 0, BF
  SELECT CASE Tipo
  CASE 1
    LINE (X, Y)-(X + 31, Y + 15), 1, BF
    LINE (X, Y)-(X + 31, Y), 9
    LINE (X + 1, Y + 1)-(X + 1, Y + 14), 8
    LINE (X + 16, Y + 8)-(X + 30, Y + 8), 8
  CASE 2
    LINE (X, Y + 2)-(X + 31, Y + 15), 4, BF
    LINE (X, Y + 2)-(X + 31, Y + 4), 12, BF
    LINE (X + 4, Y + 2)-(X + 15, Y + 2), 14
  CASE 3
    LINE (X, Y)-(X + 31, Y + 15), 6, BF
    LINE (X + 3, Y + 2)-(X + 28, Y + 13), 14
    LINE (X + 28, Y + 2)-(X + 3, Y + 13), 14
  END SELECT
END SUB

REM 3. FUNCOES DE COLISAO: nao desenham nem alteram o jogador.
FUNCTION TipoCelula(X, Y)
  TipoCelula = 1
  IF X >= 0 AND X < 640 AND Y >= 24 AND Y < 184 THEN
    Coluna = INT(X / 32)
    Linha = INT((Y - 24) / 16)
    TipoCelula = Bloco(Linha * 20 + Coluna)
  END IF
END FUNCTION

REM Valor absoluto, escrito aqui para nao depender de ABS.
FUNCTION Distancia(Valor)
  Distancia = Valor
  IF Valor < 0 THEN Distancia = -Valor
END FUNCTION

FUNCTION Solido(X, Y)
  T = TipoCelula(X, Y)
  Solido = 0
  IF T = 1 OR T = 3 THEN Solido = 1
END FUNCTION

FUNCTION Obstaculo(X, Y)
  Obstaculo = 0
  IF Solido(X, Y) OR Solido(X + 19, Y) THEN Obstaculo = 1
  IF Solido(X, Y + 13) OR Solido(X + 19, Y + 13) THEN Obstaculo = 1
END FUNCTION

FUNCTION Sobrepoe(X1, Y1, L1, A1, X2, Y2, L2, A2)
  Sobrepoe = 0
  IF X1 < X2 + L2 AND X1 + L1 > X2 THEN
    IF Y1 < Y2 + A2 AND Y1 + A1 > Y2 THEN Sobrepoe = 1
  END IF
END FUNCTION

REM 4. MOVIMENTO: resolver X e Y separadamente permite deslizar.
SUB MoverJogador
  DIM NovoX AS SINGLE, NovoY AS SINGLE
  NovoX = JX
  SELECT CASE Tecla
  CASE 2, 3, 4
    NovoX = JX + 4
    Direcao = 1
  CASE 6, 7, 8
    NovoX = JX - 4
    Direcao = -1
  END SELECT
  IF Obstaculo(NovoX, JY) = 0 THEN JX = NovoX
  NoChao = Obstaculo(JX, JY + 1)
  IF Voar = 1 AND Combustivel > 0 THEN
    VelY = -1.8
    Combustivel = Combustivel - 2
  ELSE
    VelY = VelY + 0.2
    IF VelY > 2 THEN VelY = 2
    IF NoChao = 1 THEN Combustivel = Combustivel + 6
    IF Combustivel > 1000 THEN Combustivel = 1000
  END IF
  NovoY = JY + VelY
  IF Obstaculo(JX, NovoY) = 0 THEN
    JY = NovoY
  ELSE
    VelY = 0
  END IF
  IF Invencivel > 0 THEN Invencivel = Invencivel - 1
  IF TipoCelula(JX, JY + 13) = 2 OR TipoCelula(JX + 19, JY + 13) = 2 THEN
    CALL PerderVida
  END IF
END SUB

REM 5. LASER: um tiro de cada vez; tres pequenos passos evitam saltos.
SUB AtualizarLaser
  IF Recarga > 0 THEN Recarga = Recarga - 1
  IF Fogo <> 0 AND TiroAtivo = 0 AND Recarga = 0 THEN
    TiroAtivo = 1
    TiroDir = Direcao
    TiroX = INT(JX) + 10 + Direcao * 12
    TiroY = INT(JY) + 6
    Recarga = 12
  END IF
  FOR Passo = 1 TO 3
    IF TiroAtivo = 1 THEN
      TiroX = TiroX + TiroDir * 4
      IF Solido(TiroX, TiroY) THEN TiroAtivo = 0
      FOR I = 0 TO 2
        IF InimigoVivo(I) = 1 AND TiroAtivo = 1 THEN
          IF Sobrepoe(TiroX, TiroY, 8, 2, InimigoX(I), InimigoY(I), 24, 10) THEN
            InimigoVivo(I) = 0
            TiroAtivo = 0
            Pontos = Pontos + 50
          END IF
        END IF
      NEXT I
    END IF
  NEXT Passo
END SUB

REM 6. BOMBA: so no chao. A explosao abre X, mas nao destroi pedra.
REM Nesta versao didatica a explosao nao magoa o socorrista.
SUB AtualizarBomba
  IF ExplosaoTempo > 0 THEN ExplosaoTempo = ExplosaoTempo - 1
  IF Baixo = 1 AND BaixoAntes = 0 AND NoChao = 1 THEN
    IF Bombas > 0 AND BombaTempo = 0 AND ExplosaoTempo = 0 THEN
      BombaX = INT(JX) + 8
      BombaY = INT(JY) + 8
      BombaTempo = 35
      Bombas = Bombas - 1
    END IF
  END IF
  IF BombaTempo > 0 THEN
    BombaTempo = BombaTempo - 1
    IF BombaTempo = 0 THEN
      ExplosaoTempo = 12
      FOR Linha = 0 TO 9
        FOR Coluna = 0 TO 19
          IF Bloco(Linha * 20 + Coluna) = 3 THEN
            IF Distancia(Coluna * 32 + 16 - BombaX) < 60 AND Distancia(24 + Linha * 16 + 8 - BombaY) < 36 THEN
              Bloco(Linha * 20 + Coluna) = 0
              CALL DesenharCelula(Coluna, Linha)
            END IF
          END IF
        NEXT Coluna
      NEXT Linha
    END IF
  END IF
END SUB

REM 7. MORCEGOS: patrulham e invertem ao encontrar uma parede.
SUB MoverInimigos
  FOR I = 0 TO 2
    IF InimigoVivo(I) = 1 THEN
      NX = InimigoX(I) + InimigoDir(I) * 2
      IF Solido(NX, InimigoY(I)) OR Solido(NX + 23, InimigoY(I)) THEN
        InimigoDir(I) = -InimigoDir(I)
      ELSE
        InimigoX(I) = NX
      END IF
      IF Invencivel = 0 THEN
        IF Sobrepoe(JX, JY, 20, 14, InimigoX(I), InimigoY(I), 24, 10) THEN CALL PerderVida
      END IF
    END IF
  NEXT I
END SUB

SUB PerderVida
  Vidas = Vidas - 1
  IF Vidas <= 0 THEN
    Estado = PERDEU
  ELSE
    JX = 48
    JY = 54
    VelY = 0
    Combustivel = 1000
    Resgatado = 0
    Invencivel = 80
  END IF
  CALL DesenharPainel
END SUB

SUB VerificarObjetivo
  IF Estado = JOGAR THEN
    IF Resgatado = 0 THEN
      IF Sobrepoe(JX, JY, 20, 14, 560, 154, 20, 14) THEN
        Resgatado = 1
        CALL DesenharPainel
      END IF
    ELSE
      IF Sobrepoe(JX, JY, 20, 14, 40, 48, 26, 24) THEN
        Pontos = Pontos + 500
        Estado = PASSOU
        IF Nivel = 3 THEN Estado = GANHOU
      END IF
    END IF
  END IF
END SUB

REM 8. DESENHO: apagar na ordem inversa preserva fundos sobrepostos.
SUB EsconderSprites
  FOR I = 7 TO 0 STEP -1
    SPRITE OFF I
  NEXT I
END SUB

SUB DesenharSprites
  Modelo = 20
  IF Direcao = -1 THEN Modelo = 21
  IF Voar = 1 AND Combustivel > 0 THEN Modelo = Modelo + 2
  SPRITE COPY 0, Modelo
  IF Invencivel = 0 OR Tique MOD 6 < 3 THEN
    SPRITE MOVE 0, INT(JX), INT(JY)
    SPRITE ON 0
  END IF
  IF Resgatado = 0 THEN
    SPRITE MOVE 1, 560, 154
    SPRITE ON 1
  END IF
  FOR I = 0 TO 2
    IF InimigoVivo(I) = 1 THEN
      SPRITE MOVE I + 2, InimigoX(I), InimigoY(I)
      SPRITE ON I + 2
    END IF
  NEXT I
  IF TiroAtivo = 1 THEN
    SPRITE MOVE 5, TiroX, TiroY
    SPRITE ON 5
  END IF
  IF BombaTempo > 0 THEN
    SPRITE MOVE 6, BombaX, BombaY
    SPRITE ON 6
  END IF
  IF ExplosaoTempo > 0 THEN
    SPRITE MOVE 7, BombaX - 16, BombaY - 8
    SPRITE ON 7
  END IF
END SUB

SUB DesenharPainel
  LINE (0, 0)-(639, 23), 0, BF
  COLOR 15
  LOCATE 1, 2
  PRINT "RESGATE  CAVERNA"; Nivel; " VIDAS"; Vidas; " PONTOS"; Pontos;
  COLOR 11
  LOCATE 2, 2
  PRINT "JETPACK"; INT(Combustivel / 10); "%   BOMBAS"; Bombas;
  LOCATE 2, 37
  COLOR 14
  IF Resgatado = 0 THEN
    PRINT "PROCURA O MINEIRO";
  ELSE
    PRINT "VOLTA A PORTA VERDE";
  END IF
END SUB

SUB MostrarTitulo
  CLS
  COLOR 11
  LOCATE 5, 27
  PRINT "R E S G A T E";
  COLOR 15
  LOCATE 8, 12
  PRINT "Tres cavernas. Um jetpack. Pessoas para salvar.";
  LOCATE 11, 12
  PRINT "ESQUERDA / DIREITA   andar";
  LOCATE 13, 12
  PRINT "CIMA                voar (recarrega no chao)";
  LOCATE 15, 12
  PRINT "ESPACO              disparar o laser";
  LOCATE 17, 12
  PRINT "BAIXO               colocar bomba no chao";
  COLOR 14
  LOCATE 20, 12
  PRINT "Resgata o mineiro e regressa a porta verde.";
  COLOR 10
  LOCATE 23, 22
  PRINT "ESPACO: comecar    ESC: sair";
END SUB

SUB MostrarResultado
  CALL EsconderSprites
  LINE (96, 76)-(543, 123), 0, BF
  LINE (96, 76)-(543, 123), 11, B
  COLOR 14
  LOCATE 11, 20
  SELECT CASE Estado
  CASE PASSOU
    PRINT "MINEIRO SALVO! PROXIMA CAVERNA.";
  CASE GANHOU
    PRINT "PARABENS! SALVASTE OS TRES MINEIROS!";
  CASE PERDEU
    PRINT "FIM DE JOGO. TENTA OUTRA VEZ!";
  END SELECT
  COLOR 15
  LOCATE 14, 22
  PRINT "ESPACO: continuar   ESC: sair";
END SUB

REM 9. SPRITES: cada caracter e um pixel da paleta; 0 transparente.
REM Os modelos 20..23 guardam as poses do jogador (20x14).
SUB CriarSprites
  SPRITE DEF 20, 20, 14, "000000EEEEEE000000000000EEEEEEEEEE0000000000EEBBBBBBEE0000000000EEFFFFFFFF000000008888AAAAAA00000000008888AAAAAAFFFF0000008888AAAAAAAAFFFFFF008888AAAAAA00000000008888AAAAAA00000000000000AAAAAA00000000000000AA00AA00000000000000AA00AA000000000000FFFF00FFFF00000000000000000000000000"
  SPRITE DEF 21, 20, 14, "00000000EEEEEE000000000000EEEEEEEEEE0000000000EEBBBBBBEE0000000000FFFFFFFFEE000000000000AAAAAA8888000000FFFFAAAAAA888800FFFFFFAAAAAAAA88880000000000AAAAAA88880000000000AAAAAA88880000000000AAAAAA00000000000000AA00AA00000000000000AA00AA000000000000FFFF00FFFF000000000000000000000000"
  SPRITE DEF 22, 20, 14, "000000EEEEEE000000000000EEEEEEEEEE0000000000EEBBBBBBEE0000000000EEFFFFFFFF000000008888AAAAAA00000000008888AAAAAAFFFF0000008888AAAAAAAAFFFFFF008888AAAAAA00000000008888AAAAAA00000000000000AAAAAA00000000000000AA00AA00000000000000AA00AA0000000000CCEE0000FFFF00000000EECC00000000000000"
  SPRITE DEF 23, 20, 14, "00000000EEEEEE000000000000EEEEEEEEEE0000000000EEBBBBBBEE0000000000FFFFFFFFEE000000000000AAAAAA8888000000FFFFAAAAAA888800FFFFFFAAAAAAAA88880000000000AAAAAA88880000000000AAAAAA88880000000000AAAAAA00000000000000AA00AA00000000000000AA00AA000000000000FFFF0000EECC0000000000000000CCEE00"
  SPRITE DEF 1, 20, 14, "000000EEEEEE000000000000EEEEEEEEEE000000000000FFFFFF00000000000000FFFFFF00000000000000666666000000000000FF666666FF0000000000FF666666FF00000000000066666600000000000000666666000000000000006600660000000000000066006600000000000000660066000000000000FFFF00FFFF00000000000000000000000000"
  SPRITE DEF 2, 24, 10, "CC00000000000000000000CCCCCC0000000000000000CCCCCCCCCC0000CCCC0000CCCCCCCCCCCCCCCCCCCCCCCCCCCCCC00CCCCCCEECCCCEECCCCCC000000CCCCCCCCCCCCCCCC0000000000CCCCCCCCCCCC00000000000000CCCCCCCC0000000000000000CC0000CC00000000000000000000000000000000"
  SPRITE DEF 3, 24, 10, "CC00000000000000000000CCCCCC0000000000000000CCCCCCCCCC0000CCCC0000CCCCCCCCCCCCCCCCCCCCCCCCCCCCCC00CCCCCCEECCCCEECCCCCC000000CCCCCCCCCCCCCCCC0000000000CCCCCCCCCCCC00000000000000CCCCCCCC0000000000000000CC0000CC00000000000000000000000000000000"
  SPRITE DEF 4, 24, 10, "CC00000000000000000000CCCCCC0000000000000000CCCCCCCCCC0000CCCC0000CCCCCCCCCCCCCCCCCCCCCCCCCCCCCC00CCCCCCEECCCCEECCCCCC000000CCCCCCCCCCCCCCCC0000000000CCCCCCCCCCCC00000000000000CCCCCCCC0000000000000000CC0000CC00000000000000000000000000000000"
  SPRITE DEF 5, 8, 2, "EEEEEEEEFFFFFFFF"
  SPRITE DEF 6, 8, 5, "00EE00006666660066CC66006666660000000000"
  SPRITE DEF 7, 32, 16, "00000000EE000000EE000000000000000000EE00EEEE00EEEE00EE0000000000000000EEEEEEEEEEEEEE00000000000000EEEEEEEEFFFFFFEEEEEEEE000000000000EEEEFFFFFFFFFFEEEE0000000000EEEEEEFFFFFFFFFFFFFFEEEEEE00000000EEEEFFFFFFFFFFFFFFEEEE000000000000EEEEFFFFFFFFFFEEEE000000000000EEEEEEEEFFFFFFEEEEEEEE00000000000000EEEEEEEEEEEEEE0000000000000000EE00EEEE00EEEE00EE000000000000000000EE000000EE0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
  SPRITE COPY 0, 20
END SUB

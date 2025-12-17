Attribute VB_Name = "TileEngine_RenderScreen"
'    Argentum 20 - Game Client Program
'    Copyright (C) 2022 - Noland Studios
'
'    This program is free software: you can redistribute it and/or modify
'    it under the terms of the GNU Affero General Public License as published by
'    the Free Software Foundation, either version 3 of the License, or
'    (at your option) any later version.
'
'    This program is distributed in the hope that it will be useful,
'    but WITHOUT ANY WARRANTY; without even the implied warranty of
'    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
'    GNU Affero General Public License for more details.
'    You should have received a copy of the GNU Affero General Public License
'    along with this program.  If not, see <https://www.gnu.org/licenses/>.
'
'
Option Explicit
'Letter showing on screen
Public letter_text            As String
Public letter_grh             As Grh
Public map_letter_grh         As Grh
Public map_letter_grh_next    As Long
Public map_letter_a           As Single
Public map_letter_fadestatus  As Byte
Public gameplay_render_offset As Vector2

' Toggle flags para ventanas flotantes simples
Public g_ShowInventory As Boolean
Public g_ShowSpells As Boolean

' Posicion de las ventanas flotantes
Public g_InvWinX As Integer
Public g_InvWinY As Integer
Public g_SpellWinX As Integer
Public g_SpellWinY As Integer

' Estado de arrastre
Public g_DraggingWindow As Integer  ' 0=ninguna, 1=inventario, 2=hechizos
Public g_DragOffsetX As Integer
Public g_DragOffsetY As Integer

' Seleccion en ventanas flotantes
Public g_SelectedInvSlot As Integer     ' Slot seleccionado en inventario (1-36)
Public g_SelectedSpellSlot As Integer   ' Slot seleccionado en hechizos (1-MAXHECHI)

' Ultima posicion del mouse (para doble-click)
Public g_LastMouseX As Integer
Public g_LastMouseY As Integer

' Arrastre de items en inventario flotante
Public g_InvDraggingSlot As Integer   ' Slot siendo arrastrado (0 = ninguno)
Public g_InvDragGrh As Long           ' GrhIndex del item arrastrado
Public Const hotkey_render_posX = 200
Public Const hotkey_render_posY = 40
Public Const hotkey_arrow_posx = 200 + 36 * 5 - 5
Public Const hotkey_arrow_posy = 10

Sub RenderScreen(ByVal center_x As Integer, _
                 ByVal center_y As Integer, _
                 ByVal PixelOffsetX As Integer, _
                 ByVal PixelOffsetY As Integer, _
                 ByVal HalfTileWidth As Integer, _
                 ByVal HalfTileHeight As Integer)
    On Error GoTo RenderScreen_Err
    ' Renders everything to the viewport
    Dim y                  As Integer      ' Keeps track of where on map we are
    Dim x                  As Integer      ' Keeps track of where on map we are
    Dim MinX               As Integer
    Dim MaxX               As Integer
    Dim MinY               As Integer
    Dim MaxY               As Integer
    Dim MinBufferedX       As Integer
    Dim MaxBufferedX       As Integer
    Dim MinBufferedY       As Integer
    Dim MaxBufferedY       As Integer
    Dim StartX             As Integer
    Dim StartY             As Integer
    Dim StartBufferedX     As Integer
    Dim StartBufferedY     As Integer
    Dim screenX            As Integer      ' Keeps track of where to place tile on screen
    Dim screenY            As Integer      ' Keeps track of where to place tile on screen
    Dim DeltaTime          As Long
    Dim TempColor(3)       As RGBA
    Dim ColorBarraPesca(3) As RGBA
    ' Tiles that are in range
    MinX = center_x - HalfTileWidth
    MaxX = center_x + HalfTileWidth
    MinY = center_y - HalfTileHeight
    MaxY = center_y + HalfTileHeight
    ' Buffer tiles (for layer 2, chars, big objects, etc.)
    MinBufferedX = MinX - TileBufferSizeX
    MaxBufferedX = MaxX + TileBufferSizeX
    MinBufferedY = MinY - 1
    MaxBufferedY = MaxY + TileBufferSizeY
    ' Screen start (with movement offset)
    StartX = PixelOffsetX - MinX * TilePixelWidth + gameplay_render_offset.x
    StartY = PixelOffsetY - MinY * TilePixelHeight + gameplay_render_offset.y
    ' Screen start with tiles buffered (for layer 2, chars, big objects, etc.)
    StartBufferedX = TileBufferPixelOffsetX + PixelOffsetX + gameplay_render_offset.x
    StartBufferedY = PixelOffsetY - TilePixelHeight + gameplay_render_offset.y
    ' Add 1 tile to the left if going left, else add it to the right
    If PixelOffsetX > 0 Then
        MinX = MinX - 1
    Else
        MaxX = MaxX + 10
    End If
    If PixelOffsetY > 0 Then
        MinY = MinY - 1
    Else
        MaxY = MaxY + 5
    End If
    If MapData(UserPos.x, UserPos.y).charindex = 0 And UserCharIndex > 0 Then
        UserPos.x = charlist(UserCharIndex).Pos.x
        UserPos.y = charlist(UserCharIndex).Pos.y
        MapData(UserPos.x, UserPos.y).charindex = UserCharIndex
    End If
    ' Map border checks
    If MinX < XMinMapSize Then
        StartBufferedX = PixelOffsetX - MinX * TilePixelWidth
        MaxX = MaxX - MinX
        MaxBufferedX = MaxBufferedX - MinX
        MinX = XMinMapSize
        MinBufferedX = XMinMapSize
    ElseIf MinBufferedX < XMinMapSize Then
        StartBufferedX = StartBufferedX - (MinBufferedX - XMinMapSize) * TilePixelWidth
        MinBufferedX = XMinMapSize
    ElseIf MaxX > XMaxMapSize Then
        MaxX = XMaxMapSize
        MaxBufferedX = XMaxMapSize
    ElseIf MaxBufferedX > XMaxMapSize Then
        MaxBufferedX = XMaxMapSize
    End If
    If MinY < YMinMapSize Then
        StartBufferedY = PixelOffsetY - MinY * TilePixelHeight
        MaxY = MaxY - MinY
        MaxBufferedY = MaxBufferedY - MinY
        MinY = YMinMapSize
        MinBufferedY = YMinMapSize
    ElseIf MinBufferedY < YMinMapSize Then
        StartBufferedY = StartBufferedY - (MinBufferedY - 1) * TilePixelHeight
        MinBufferedY = YMinMapSize
    ElseIf MaxY > YMaxMapSize Then
        MaxY = YMaxMapSize
        MaxBufferedY = YMaxMapSize
    ElseIf MaxBufferedY > YMaxMapSize Then
        MaxBufferedY = YMaxMapSize
    End If
    If UpdateLights Then
        Call RestaurarLuz
        Call MapUpdateGlobalLightRender
        UpdateLights = False
    End If
    Call SpriteBatch.BeginPrecalculated(StartX, StartY)
    ' Layer 1 loop
    For y = MinY To MaxY
        For x = MinX To MaxX
            With MapData(x, y)
                ' Layer 1 *********************************
                Call Draw_Grh_Precalculated(.Graphic(1), .light_value, (.Blocked And FLAG_AGUA) <> 0, (.Blocked And FLAG_LAVA) <> 0, x, y, MinX, MaxX, MinY, MaxY)
                '******************************************
            End With
        Next x
    Next y
    Call SpriteBatch.EndPrecalculated
    ' Layer 2 & small objects loop
    Call DirectDevice.SetRenderState(D3DRS_ALPHATESTENABLE, True) ' Para no pisar los reflejos
    screenY = StartBufferedY
    For y = MinBufferedY To MaxBufferedY
        screenX = StartBufferedX
        For x = MinBufferedX To MaxBufferedX
            With MapData(x, y)
                ' Layer 2 *********************************
                If .Graphic(2).GrhIndex <> 0 Then
                    Call Draw_Grh(.Graphic(2), screenX, screenY, 1, 1, .light_value, , x, y)
                End If
            End With
            screenX = screenX + TilePixelWidth
        Next x
        screenY = screenY + TilePixelHeight
    Next y
    Dim grhSpellArea As Grh
    grhSpellArea.GrhIndex = 20058
    Dim temp_color(3) As RGBA
    Call SetRGBA(temp_color(0), 255, 20, 25, 255)
    Call SetRGBA(temp_color(1), 0, 255, 25, 255)
    Call SetRGBA(temp_color(2), 55, 255, 55, 255)
    Call SetRGBA(temp_color(3), 145, 70, 70, 255)
    ' Call SetRGBA(MapData(15, 15).light_value(0), 255, 20, 20)
    'size 96x96 - mitad = 48
    If casteaArea And mouseX > 0 And mouseY > 0 And GetGameplayForm.MousePointer = 2 Then
        Call Draw_Grh(grhSpellArea, mouseX - 48, mouseY - 48, 0, 1, temp_color, True, , , 70)
    End If
    screenY = StartBufferedY
    For y = MinBufferedY To MaxBufferedY
        screenX = StartBufferedX
        For x = MinBufferedX To MaxBufferedX
            With MapData(x, y)
                If .Trap.GrhIndex > 0 Then
                    Call RGBAList(temp_color, 255, 255, 255, 100)
                    Call Draw_Grh(.Trap, screenX, screenY, 1, 1, temp_color, False)
                End If
                ' Objects *********************************
                If .ObjGrh.GrhIndex <> 0 Then
                    Select Case ObjData(.OBJInfo.ObjIndex).ObjType
                        Case eObjType.otArboles, eObjType.otPuertas, eObjType.otTeleport, eObjType.otCarteles, eObjType.otYacimiento, eObjType.OtCorreo, _
                                eObjType.otFragua, eObjType.OtDecoraciones, eObjType.otFishingPool
                            Call Draw_Grh(.ObjGrh, screenX, screenY, 1, 1, .light_value)
                        Case Else
                            ' Objetos en el suelo (items, decorativos, etc)
                            If ((.Blocked And FLAG_AGUA) <> 0) And .Graphic(2).GrhIndex = 0 Then
                                object_angle = (object_angle + (timerElapsedTime * 0.002))
                                .light_value(1).A = 85
                                .light_value(3).A = 85
                                Call Draw_Grh_ItemInWater(.ObjGrh, screenX, screenY, False, False, .light_value, False, , , (object_angle + x * 45 + y * 90))
                                .light_value(1).A = 255
                                .light_value(3).A = 255
                                .light_value(0).A = 255
                                .light_value(2).A = 255
                            Else
                                Call Draw_Grh(.ObjGrh, screenX, screenY, 1, 1, .light_value)
                            End If
                    End Select
                End If
            End With
            screenX = screenX + TilePixelWidth
        Next x
        screenY = screenY + TilePixelHeight
    Next y
    Call DirectDevice.SetRenderState(D3DRS_ALPHATESTENABLE, False)
    '  Layer 3 & chars
    screenY = StartBufferedY
    For y = MinBufferedY To MaxBufferedY
        screenX = StartBufferedX
        For x = MinBufferedX To MaxBufferedX
            With MapData(x, y)
                ' Chars ***********************************
                If .charindex = UserCharIndex Then 'evitamos reenderizar un clon del usuario
                    If x <> UserPos.x Or y <> UserPos.y Then
                        .charindex = 0
                    End If
                End If
                If .CharFantasma.Activo Then
                    If .CharFantasma.AlphaB > 0 Then
                        .CharFantasma.AlphaB = .CharFantasma.AlphaB - (timerTicksPerFrame * 30)
                        'Redondeamos a 0 para prevenir errores
                        If .CharFantasma.AlphaB < 0 Then .CharFantasma.AlphaB = 0
                        Call Copy_RGBAList_WithAlpha(TempColor, .light_value, .CharFantasma.AlphaB)
                        'Seteamos el color
                        If .CharFantasma.Heading = 1 Or .CharFantasma.Heading = 2 Then
                            Call Draw_Grh(.CharFantasma.Escudo, screenX, screenY, 1, 1, TempColor(), False, x, y)
                            Call Draw_Grh(.CharFantasma.Body, screenX, screenY, 1, 1, TempColor(), False, x, y)
                            Call Draw_Grh(.CharFantasma.Head, screenX + .CharFantasma.OffX, screenY + .CharFantasma.Offy, 1, 1, TempColor(), False, x, y)
                            Call Draw_Grh(.CharFantasma.Casco, screenX + .CharFantasma.OffX, screenY + .CharFantasma.Offy, 1, 1, TempColor(), False, x, y)
                            Call Draw_Grh(.CharFantasma.Arma, screenX, screenY, 1, 1, TempColor(), False, x, y)
                        Else
                            Call Draw_Grh(.CharFantasma.Body, screenX, screenY, 1, 1, TempColor(), False, x, y)
                            Call Draw_Grh(.CharFantasma.Head, screenX + .CharFantasma.OffX, screenY + .CharFantasma.Offy, 1, 1, TempColor(), False, x, y)
                            Call Draw_Grh(.CharFantasma.Escudo, screenX, screenY, 1, 1, TempColor(), False, x, y)
                            Call Draw_Grh(.CharFantasma.Casco, screenX + .CharFantasma.OffX, screenY + .CharFantasma.Offy, 1, 1, TempColor(), False, x, y)
                            Call Draw_Grh(.CharFantasma.Arma, screenX, screenY, 1, 1, TempColor(), False, x, y)
                        End If
                    Else
                        .CharFantasma.Activo = False
                    End If
                End If
                If .charindex <> 0 Then
                    If charlist(.charindex).active = 1 Then
                        If mascota.visible And .charindex = UserCharIndex Then
                            '  Call Mascota_Render(.charindex, PixelOffsetX, PixelOffsetY)
                        End If
                        Call Char_Render(.charindex, screenX, screenY, x, y)
                    End If
                End If
            End With
            screenX = screenX + TilePixelWidth
        Next x
        ' Recorremos de nuevo esta fila para dibujar objetos grandes y capa 3 encima de chars
        screenX = StartBufferedX
        For x = MinBufferedX To MaxBufferedX
            With MapData(x, y)
                ' Objects *********************************
                If .ObjGrh.GrhIndex <> 0 Then
                    Select Case ObjData(.OBJInfo.ObjIndex).ObjType
                        Case eObjType.otArboles
                            Call Draw_Sombra(.ObjGrh, screenX, screenY, 1, 1, False, x, y)
                            ' Debajo del arbol
                            If Abs(UserPos.x - x) < 3 And (Abs(UserPos.y - y)) < 8 And (Abs(UserPos.y) < y) Then
                                If .ArbolAlphaTimer <= 0 Then
                                    .ArbolAlphaTimer = lastMove
                                End If
                                DeltaTime = FrameTime - .ArbolAlphaTimer
                                Call Copy_RGBAList_WithAlpha(TempColor, .light_value, IIf(DeltaTime > ARBOL_ALPHA_TIME, ARBOL_MIN_ALPHA, 255 - DeltaTime / ARBOL_ALPHA_TIME * ( _
                                        255 - ARBOL_MIN_ALPHA)))
                                Call Draw_Grh(.ObjGrh, screenX, screenY, 1, 1, TempColor, False, x, y)
                            Else    ' Lejos del arbol
                                If .ArbolAlphaTimer = 0 Then
                                    Call Draw_Grh(.ObjGrh, screenX, screenY, 1, 1, .light_value, False, x, y)
                                Else
                                    If .ArbolAlphaTimer > 0 Then
                                        .ArbolAlphaTimer = -lastMove
                                    End If
                                    DeltaTime = FrameTime + .ArbolAlphaTimer
                                    If DeltaTime > ARBOL_ALPHA_TIME Then
                                        .ArbolAlphaTimer = 0
                                        Call Draw_Grh(.ObjGrh, screenX, screenY, 1, 1, .light_value, False, x, y)
                                    Else
                                        Call Copy_RGBAList_WithAlpha(TempColor, .light_value, ARBOL_MIN_ALPHA + DeltaTime * (255 - ARBOL_MIN_ALPHA) / ARBOL_ALPHA_TIME)
                                        Call Draw_Grh(.ObjGrh, screenX, screenY, 1, 1, TempColor, False, x, y)
                                    End If
                                End If
                            End If
                        Case eObjType.otPuertas, eObjType.otTeleport, eObjType.otCarteles, eObjType.otYacimiento, eObjType.OtCorreo, eObjType.otYunque, _
                                eObjType.otFragua, eObjType.OtDecoraciones
                            ' Objetos grandes (menos árboles)
                            Call Draw_Grh(.ObjGrh, screenX, screenY, 1, 1, .light_value, False, x, y)
                            'Case Else
                            '    Call Draw_Grh(.ObjGrh, ScreenX, ScreenY, 1, 1, .light_value, False, x, y)
                    End Select
                End If
                'Layer 3 **********************************
                If .Graphic(3).GrhIndex <> 0 Then
                    If (.Blocked And FLAG_ARBOL) <> 0 Then
                        ' Call Draw_Sombra(.Graphic(3), ScreenX, ScreenY, 1, 1, False, x, y)
                        ' Debajo del arbol
                        If Abs(UserPos.x - x) <= 3 And (Abs(UserPos.y - y)) < 12 And (Abs(UserPos.y) < y) Then
                            If .ArbolAlphaTimer <= 0 Then
                                .ArbolAlphaTimer = lastMove
                            End If
                            DeltaTime = FrameTime - .ArbolAlphaTimer
                            Call Copy_RGBAList_WithAlpha(TempColor, .light_value, IIf(DeltaTime > ARBOL_ALPHA_TIME, ARBOL_MIN_ALPHA, 255 - DeltaTime / ARBOL_ALPHA_TIME * (255 - _
                                    ARBOL_MIN_ALPHA)))
                            Call Draw_Grh(.Graphic(3), screenX, screenY, 1, 1, TempColor, False, x, y)
                        Else    ' Lejos del arbol
                            If .ArbolAlphaTimer = 0 Then
                                Call Draw_Grh(.Graphic(3), screenX, screenY, 1, 1, .light_value, False, x, y)
                            Else
                                If .ArbolAlphaTimer > 0 Then
                                    .ArbolAlphaTimer = -lastMove
                                End If
                                DeltaTime = FrameTime + .ArbolAlphaTimer
                                If DeltaTime > ARBOL_ALPHA_TIME Then
                                    .ArbolAlphaTimer = 0
                                    Call Draw_Grh(.Graphic(3), screenX, screenY, 1, 1, .light_value, False, x, y)
                                Else
                                    Call Copy_RGBAList_WithAlpha(TempColor, .light_value, ARBOL_MIN_ALPHA + DeltaTime * (255 - ARBOL_MIN_ALPHA) / ARBOL_ALPHA_TIME)
                                    Call Draw_Grh(.Graphic(3), screenX, screenY, 1, 1, TempColor, False, x, y)
                                End If
                            End If
                        End If
                    Else
                        If AgregarSombra(.Graphic(3).GrhIndex) Then
                            Call Draw_Sombra(.Graphic(3), screenX, screenY, 1, 1, False, x, y)
                        End If
                        Call Draw_Grh(.Graphic(3), screenX, screenY, 1, 1, .light_value, False, x, y)
                    End If
                End If
            End With
            screenX = screenX + TilePixelWidth
        Next x
        screenY = screenY + TilePixelHeight
    Next y
    If InfoItemsEnRender And tX And tY Then
        With MapData(tX, tY)
            If .OBJInfo.ObjIndex Then
                If Not ObjData(.OBJInfo.ObjIndex).Agarrable Then
                    Dim text As String, Amount As String
                    If .OBJInfo.Amount > 1000 Then
                        Amount = Round(.OBJInfo.Amount * 0.001, 1) & "K"
                    Else
                        Amount = .OBJInfo.Amount
                    End If
                    text = ObjData(.OBJInfo.ObjIndex).Name & " (" & Amount & ")"
                    Call Engine_Text_Render(text, mouseX + 15 + gameplay_render_offset.x, mouseY + gameplay_render_offset.y, COLOR_WHITE, , , , 160)
                End If
            End If
        End With
    End If
    ' Particles loop
    screenY = StartBufferedY
    For y = MinBufferedY To MaxBufferedY
        screenX = StartBufferedX
        For x = MinBufferedX To MaxBufferedX
            With MapData(x, y)
                ' Particles *******************************
                If .particle_group > 0 Then
                    Call Particle_Group_Render(.particle_group, screenX + 16, screenY + 16)
                End If
                '******************************************
            End With
            screenX = screenX + TilePixelWidth
        Next x
        screenY = screenY + TilePixelHeight
    Next y
    'draw projectiles
    Dim transform As Vector2
    Dim complete  As Boolean
    Dim Index     As Integer
    Index = 1
    Do While Index <= ActiveProjectile.CurrentIndex
        complete = UpdateProjectile(AllProjectile(ActiveProjectile.IndexInfo(Index)))
        Call WorldToScreen(AllProjectile(ActiveProjectile.IndexInfo(Index)).CurrentPos, transform, StartBufferedX, StartBufferedY, MinBufferedX, MinBufferedY)
        Call RenderProjectile(AllProjectile(ActiveProjectile.IndexInfo(Index)), transform, temp_color)
        If complete Then
            ReleaseProjectile (Index)
        Else
            Index = Index + 1
        End If
    Loop
    ' Layer 4 loop
    If HayLayer4 Then
        ' Actualizo techos
        Dim Trigger As eTrigger
        For Trigger = LBound(RoofsLight) To UBound(RoofsLight)
            ' Si estoy bajo este techo
            If Trigger = MapData(UserPos.x, UserPos.y).Trigger Then
                If RoofsLight(Trigger) > 0 Then
                    ' Reduzco el alpha
                    RoofsLight(Trigger) = RoofsLight(Trigger) - timerTicksPerFrame * 48
                    If RoofsLight(Trigger) < 0 Then RoofsLight(Trigger) = 0
                End If
            ElseIf RoofsLight(Trigger) < 255 Then
                ' Aumento el alpha
                RoofsLight(Trigger) = RoofsLight(Trigger) + timerTicksPerFrame * 48
                If RoofsLight(Trigger) > 255 Then RoofsLight(Trigger) = 255
            End If
        Next
        screenY = StartBufferedY
        For y = MinBufferedY To MaxBufferedY
            screenX = StartBufferedX
            For x = MinBufferedX To MaxBufferedX
                With MapData(x, y)
                    ' Layer 4 - roofs *******************************
                    If .Graphic(4).GrhIndex Then
                        Trigger = NearRoof(x, y)
                        If Trigger Then
                            Call Copy_RGBAList_WithAlpha(TempColor, .light_value, RoofsLight(Trigger))
                            Call Draw_Grh(.Graphic(4), screenX, screenY, 1, 1, TempColor, , x, y)
                        Else
                            Call Draw_Grh(.Graphic(4), screenX, screenY, 1, 1, .light_value, , x, y)
                        End If
                    End If
                    '******************************************
                End With
                screenX = screenX + TilePixelWidth
            Next x
            screenY = screenY + TilePixelHeight
        Next y
    End If
    If TieneAntorcha Then
        Dim randX As Double, randY As Double
        If GetTickCount - (10 * Rnd + 50) >= DeltaAntorcha Then
            randX = RandomNumber(-8, 0)
            randY = RandomNumber(-8, 0)
            DeltaAntorcha = GetTickCount
        End If
        Call Draw_GrhIndex(63333, randX, randY)
    End If
    If mascota.dialog <> "" And mascota.visible Then
        Call Engine_Text_Render(mascota.dialog, mascota.PosX + 14 - CInt(Engine_Text_Width(mascota.dialog, True) / 2) + 150, mascota.PosY - Engine_Text_Height(mascota.dialog, _
                True) - 25 + 150, mascota_text_color(), 1, True, , mascota.color(0).A)
    End If
    ' FXs and dialogs loop
    screenY = StartBufferedY
    For y = MinBufferedY To MaxBufferedY
        screenX = StartBufferedX
        For x = MinBufferedX To MaxBufferedX
            With MapData(x, y)
                ' Dialogs *******************************
                If MapData(x, y).charindex <> 0 Then
                    If charlist(.charindex).active = 1 Then
                        Call Char_TextRender(.charindex, screenX, screenY, x, y)
                    End If
                End If
                '******************************************
                ' Render text value *******************************
                Dim i As Long
                If UBound(.DialogEffects) > 0 Then
                    For i = 1 To UBound(.DialogEffects)
                        With .DialogEffects(i)
                            If LenB(.text) <> 0 Then
                                Dim DialogTime As Long
                                DialogTime = FrameTime - .start
                                If DialogTime > .duration Then
                                    .text = vbNullString
                                Else
                                    If DialogTime > 900 Then
                                        Call RGBAList(TempColor, .color.R, .color.G, .color.B, .color.A * (1300 - DialogTime) * 0.0025)
                                    Else
                                        Call RGBAList(TempColor, .color.R, .color.G, .color.B, .color.A)
                                    End If
                                    If .Animated Then
                                        Engine_Text_Render_Efect 0, .text, screenX + 16 - Int(Engine_Text_Width(.text, False) * 0.5) + .offset.x, screenY - Engine_Text_Height( _
                                                .text, False) + .offset.y - DialogTime * 0.025, TempColor, 1, False
                                    Else
                                        Engine_Text_Render_Efect 0, .text, screenX + 16 - Int(Engine_Text_Width(.text, False) * 0.5) + .offset.x, screenY - Engine_Text_Height( _
                                                .text, False) + .offset.y, TempColor, 1, False
                                    End If
                                End If
                            End If
                        End With
                    Next
                End If
                '******************************************
                ' FXs *******************************
                If .FxCount > 0 Then
                    For i = 1 To .FxCount
                        If .FxList(i).FxIndex > 0 And .FxList(i).started <> 0 Then
                            Call RGBAList(TempColor, 255, 255, 255, 220)
                            If FxData(.FxList(i).FxIndex).IsPNG = 1 Then
                                Call Draw_GrhFX(.FxList(i), screenX + FxData(.FxList(i).FxIndex).OffsetX, screenY + FxData(.FxList(i).FxIndex).OffsetY + 20, 1, 1, TempColor(), _
                                        False)
                            Else
                                Call Draw_GrhFX(.FxList(i), screenX + FxData(.FxList(i).FxIndex).OffsetX, screenY + FxData(.FxList(i).FxIndex).OffsetY + 20, 1, 1, TempColor(), _
                                        True)
                            End If
                        End If
                        If .FxList(i).started = 0 Then .FxList(i).FxIndex = 0
                    Next i
                    If .FxList(.FxCount).started = 0 Then .FxCount = .FxCount - 1
                End If
                '******************************************
            End With
            screenX = screenX + TilePixelWidth
        Next x
        screenY = screenY + TilePixelHeight
    Next y
    If MeteoParticle >= LBound(particle_group_list) And MeteoParticle <= UBound(particle_group_list) Then
        If particle_group_list(MeteoParticle).active Then
            If MapDat.LLUVIA Then
                'Screen positions were hardcoded by now
                screenX = 250
                screenY = 0
                Call Particle_Group_Render(MeteoParticle, screenX, screenY)
                LastOffsetX = ParticleOffsetX
                LastOffsetY = ParticleOffsetY
            End If
            If MapDat.NIEVE Then
                If Graficos_Particulas.Engine_MeteoParticle_Get <> 0 Then
                    'Screen positions were hardcoded by now
                    screenX = 250 + gameplay_render_offset.x
                    screenY = 0 + gameplay_render_offset.y
                    Call Particle_Group_Render(MeteoParticle, screenX, screenY)
                End If
            End If
        Else
            MeteoParticle = 0
        End If
    End If
    If AlphaNiebla Then
        If MapDat.niebla Then Call Engine_Weather_UpdateFog
    End If
    Call Effect_Render_All
    If IsSet(FeatureToggles, eEnableHotkeys) And g_game_state.State = e_state_gameplay_screen Then
        Dim color(3) As RGBA
        Call RGBAList(color, 255, 255, 255, 200)
        Dim ArrowPos As Vector2
        ArrowPos.x = hotkey_arrow_posx
        ArrowPos.y = frmMain.renderer.Height - hotkey_arrow_posy
        If HideHotkeys Then
            Call DrawSingleGrh(HideArrowGrh, ArrowPos, 1, 270, color)
        Else
            For i = 0 To 9
                Call DrawHotkey(i, i * 36 + hotkey_render_posX, frmMain.renderer.Height - hotkey_render_posY)
            Next
            Call DrawSingleGrh(HideArrowGrh, ArrowPos, 1, 90, color)
            If gDragState.active Then
                Call Draw_GrhColor(gDragState.Grh, gDragState.PosX - 16 - frmMain.renderer.Left, gDragState.PosY - frmMain.renderer.Top - 16, color)
            End If
        End If
    End If
    Call renderCooldowns(710 + gameplay_render_offset.x, 25 + gameplay_render_offset.y)
    
    ' ==========================================
    ' Botones de Menu (solo mostrar si esta logueado)
    ' ==========================================
    If isLogged Then
        Dim menuBtnX As Integer
        Dim menuBtnY As Integer
        Dim menuBtnW As Integer
        Dim menuBtnH As Integer
        Dim menuBtnColor As RGBA
        
        menuBtnX = 900
        menuBtnW = 70
        menuBtnH = 18
        menuBtnColor = RGBA_From_Comp(180, 40, 40, 120)
        
        ' Boton 1: Ajustes (Y=50)
        menuBtnY = 50
        Call Engine_Draw_Box(menuBtnX, menuBtnY, menuBtnW, menuBtnH, menuBtnColor)
        Call RenderText("Ajustes", menuBtnX + 12, menuBtnY + 3, COLOR_WHITE, 4, False)
        
        ' Boton 2: Stats (Y=72)
        menuBtnY = 72
        Call Engine_Draw_Box(menuBtnX, menuBtnY, menuBtnW, menuBtnH, menuBtnColor)
        Call RenderText("Stats", menuBtnX + 20, menuBtnY + 3, COLOR_WHITE, 4, False)
        
        ' Boton 3: Inventario (Y=94)
        menuBtnY = 94
        Call Engine_Draw_Box(menuBtnX, menuBtnY, menuBtnW, menuBtnH, menuBtnColor)
        Call RenderText("Inventario", menuBtnX + 5, menuBtnY + 3, COLOR_WHITE, 4, False)
        
        ' Boton 4: Hechizos (Y=116)
        menuBtnY = 116
        Call Engine_Draw_Box(menuBtnX, menuBtnY, menuBtnW, menuBtnH, menuBtnColor)
        Call RenderText("Hechizos", menuBtnX + 10, menuBtnY + 3, COLOR_WHITE, 4, False)
        
        ' Boton 5: Llavero (Y=138)
        menuBtnY = 138
        Call Engine_Draw_Box(menuBtnX, menuBtnY, menuBtnW, menuBtnH, menuBtnColor)
        Call RenderText("Llavero", menuBtnX + 12, menuBtnY + 3, COLOR_WHITE, 4, False)
        
        ' Boton 6: Grupo (Y=160)
        menuBtnY = 160
        Call Engine_Draw_Box(menuBtnX, menuBtnY, menuBtnW, menuBtnH, menuBtnColor)
        Call RenderText("Grupo", menuBtnX + 16, menuBtnY + 3, COLOR_WHITE, 4, False)
        
        ' Boton 7: Quests (Y=182)
        menuBtnY = 182
        Call Engine_Draw_Box(menuBtnX, menuBtnY, menuBtnW, menuBtnH, menuBtnColor)
        Call RenderText("Quests", menuBtnX + 14, menuBtnY + 3, COLOR_WHITE, 4, False)
        
        ' Boton 8: Clanes (Y=204)
        menuBtnY = 204
        Call Engine_Draw_Box(menuBtnX, menuBtnY, menuBtnW, menuBtnH, menuBtnColor)
        Call RenderText("Clanes", menuBtnX + 14, menuBtnY + 3, COLOR_WHITE, 4, False)
        
        ' Boton 9: Retos (Y=226)
        menuBtnY = 226
        Call Engine_Draw_Box(menuBtnX, menuBtnY, menuBtnW, menuBtnH, menuBtnColor)
        Call RenderText("Retos", menuBtnX + 18, menuBtnY + 3, COLOR_WHITE, 4, False)
    End If
    
    ' ==========================================
    ' Ventana de Inventario Flotante
    ' ==========================================
    If g_ShowInventory Then
        Call RenderFloatingInventory
    End If
    
    ' ==========================================
    ' Ventana de Hechizos Flotante
    ' ==========================================
    If g_ShowSpells Then
        Call RenderFloatingSpells
    End If
    If InvasionActual Then
        Call Engine_Draw_Box(190 + gameplay_render_offset.x, 550 + gameplay_render_offset.y, 356, 36, RGBA_From_Comp(0, 0, 0, 200))
        Call Engine_Draw_Box(193 + gameplay_render_offset.x, 553 + gameplay_render_offset.y, 3.5 * InvasionPorcentajeVida, 30, RGBA_From_Comp(20, 196, 255, 200))
        Call Engine_Draw_Box(340 + gameplay_render_offset.x, 586 + gameplay_render_offset.y, 54, 9, RGBA_From_Comp(0, 0, 0, 200))
        Call Engine_Draw_Box(342 + gameplay_render_offset.x, 588 + gameplay_render_offset.y, 0.5 * InvasionPorcentajeTiempo, 5, RGBA_From_Comp(220, 200, 0, 200))
    End If
    If Pregunta Then
        Call Engine_Draw_Box(283 + gameplay_render_offset.x, 170 + gameplay_render_offset.y, 190, 100, RGBA_From_Comp(150, 20, 3, 200))
        Call Engine_Draw_Box(288 + gameplay_render_offset.x, 175 + gameplay_render_offset.y, 180, 90, RGBA_From_Comp(25, 25, 23, 200))
        Dim preguntaGrh As Grh
        Call InitGrh(preguntaGrh, 32120)
        Call Engine_Text_Render(PreguntaScreen, 290 + gameplay_render_offset.x, 180 + gameplay_render_offset.y, COLOR_WHITE, 1, True)
        Call Draw_Grh(preguntaGrh, 416 + gameplay_render_offset.x, 233 + gameplay_render_offset.y, 1, 0, COLOR_WHITE, False, 0, 0, 0)
    End If
    If cartel Then
        Call RGBAList(TempColor, 255, 255, 255, 220)
        Dim TempGrh As Grh
        Call InitGrh(TempGrh, GrhCartel)
        Call Draw_Grh(TempGrh, CInt(clicX), CInt(clicY), 1, 0, TempColor(), False, 0, 0, 0)
        Call Engine_Text_Render(Leyenda, CInt(clicX - 100), CInt(clicY - 130), TempColor(), 1, False)
    End If
    Call RenderScreen_NombreMapa
    If PescandoEspecial Then
        Call RGBAList(ColorBarraPesca, 255, 255, 255)
        Dim Grh As Grh
        Grh.GrhIndex = GRH_BARRA_PESCA
        Call Draw_Grh(Grh, 239 + gameplay_render_offset.x, 550 + gameplay_render_offset.y, 0, 0, ColorBarraPesca())
        Grh.GrhIndex = GRH_CURSOR_PESCA
        Call Draw_Grh(Grh, 271 + PosicionBarra + gameplay_render_offset.x, 558 + gameplay_render_offset.y, 0, 0, ColorBarraPesca())
        frmDebug.add_text_tracebox PescandoEspecial
        For i = 1 To MAX_INTENTOS
            If intentosPesca(i) = 1 Then
                Grh.GrhIndex = GRH_CIRCULO_VERDE
                Call Draw_Grh(Grh, 394 + (i * 10) + gameplay_render_offset.x, 573 + gameplay_render_offset.y, 0, 0, ColorBarraPesca())
            ElseIf intentosPesca(i) = 2 Then
                Grh.GrhIndex = GRH_CIRCULO_ROJO
                Call Draw_Grh(Grh, 394 + (i * 10) + gameplay_render_offset.x, 573 + gameplay_render_offset.y, 0, 0, ColorBarraPesca())
            End If
        Next i
        If PosicionBarra <= 0 Then
            DireccionBarra = 1
            PuedeIntentar = True
        ElseIf PosicionBarra > 199 Then
            DireccionBarra = -1
            PuedeIntentar = True
        End If
        If PosicionBarra < 0 Then
            PosicionBarra = 0
        ElseIf PosicionBarra > 199 Then
            PosicionBarra = 199
        End If
        '90 - 111 es incluido (saca el pecesito)
        PosicionBarra = PosicionBarra + (DireccionBarra * VelocidadBarra * timerElapsedTime * 0.2)
        If (GetTickCount() - startTimePezEspecial) >= 20000 Then
            PescandoEspecial = False
            Call AddtoRichTextBox(frmMain.RecTxt, JsonLanguage.Item("MENSAJE_PEZ_ROMPIO_LINEA_PESCA"), 255, 0, 0, 1, 0)
            Call WriteRomperCania
        End If
    End If
    If cartel_visible Then Call RenderScreen_Cartel
    Exit Sub
RenderScreen_Err:
    Call RegistrarError(Err.Number, Err.Description, "TileEngine_RenderScreen.RenderScreen", Erl)
    Resume Next
End Sub

Private Sub WorldToScreen(ByRef world As Vector2, _
                          ByRef screen As Vector2, _
                          ByVal screenX As Integer, _
                          ByVal screenY As Integer, _
                          ByVal tilesOffsetX As Integer, _
                          ByVal tilesOffsetY As Integer)
    screen.y = world.y - tilesOffsetY * TilePixelHeight + screenY
    screen.x = world.x - tilesOffsetX * TilePixelWidth + screenX
End Sub

Private Sub RenderProjectile(ByRef projetileInstance As Projectile, ByRef screenPos As Vector2, ByRef rgba_list() As RGBA)
    On Error GoTo RenderProjectile_Err
    Call RGBAList(rgba_list, 255, 255, 255, 255)
    Call DrawSingleGrh(projetileInstance.GrhIndex, screenPos, 0, projetileInstance.Rotation, rgba_list)
    Exit Sub
RenderProjectile_Err:
    Call RegistrarError(Err.Number, Err.Description, "TileEngine_RenderScreen.RenderProjectile_Err", Erl)
End Sub

Function UpdateProjectile(ByRef Projectile As Projectile) As Boolean
    On Error GoTo UpdateProjectile_Err
    Dim direction As Vector2
    direction = VSubs(Projectile.TargetPos, Projectile.CurrentPos)
    If VecLength(direction) < Projectile.speed * timerElapsedTime Then
        UpdateProjectile = True
        Exit Function
    End If
    Call Normalize(direction)
    direction = VMul(direction, Projectile.speed * timerElapsedTime)
    Projectile.CurrentPos = VAdd(Projectile.CurrentPos, direction)
    Projectile.Rotation = FixAngle(Projectile.Rotation + Projectile.RotationSpeed * timerElapsedTime)
    UpdateProjectile = False
    Exit Function
UpdateProjectile_Err:
    Call RegistrarError(Err.Number, Err.Description, "TileEngine_RenderScreen.UpdateProjectile_Err", Erl)
End Function

Public Sub InitializeProjectile(ByRef Projectile As Projectile, ByVal StartX As Byte, ByVal StartY As Byte, ByVal endX As Byte, ByVal endY As Byte, ByVal projectileType As Integer)
    On Error GoTo InitializeProjectile_Err
    With ProjectileData(projectileType)
        Dim Index As Integer
        If AvailableProjectile.CurrentIndex > 0 Then
            Index = AvailableProjectile.IndexInfo(AvailableProjectile.CurrentIndex)
            AvailableProjectile.CurrentIndex = AvailableProjectile.CurrentIndex - 1
        Else
            'increase projectile active/ inactive/ instance arrays size
        End If
        AllProjectile(Index).CurrentPos.x = StartX * TilePixelWidth
        AllProjectile(Index).CurrentPos.y = StartY * TilePixelHeight
        AllProjectile(Index).TargetPos.x = endX * TilePixelWidth
        AllProjectile(Index).TargetPos.y = endY * TilePixelHeight
        AllProjectile(Index).speed = .speed
        AllProjectile(Index).RotationSpeed = .RotationSpeed
        AllProjectile(Index).GrhIndex = .Grh
        If endX > StartX And .RigthGrh > 0 Then
            AllProjectile(Index).GrhIndex = .RigthGrh
            AllProjectile(Index).RotationSpeed = .RotationSpeed * -1
        End If
        AllProjectile(Index).Rotation = RadToDeg(GetAngle(StartX, endY, endX, StartY))
        AllProjectile(Index).Rotation = FixAngle(AllProjectile(Index).Rotation + .OffsetRotation)
        ActiveProjectile.CurrentIndex = ActiveProjectile.CurrentIndex + 1
        ActiveProjectile.IndexInfo(ActiveProjectile.CurrentIndex) = Index
    End With
    Exit Sub
InitializeProjectile_Err:
    Call RegistrarError(Err.Number, Err.Description, "TileEngine_RenderScreen.InitializeProjectile_Err", Erl)
End Sub

Private Sub RenderScreen_NombreMapa()
    On Error GoTo RenderScreen_NombreMapa_Err
    If map_letter_fadestatus > 0 Then
        If map_letter_fadestatus = 1 Then
            map_letter_a = map_letter_a + (timerTicksPerFrame * 3.5)
            If map_letter_a >= 255 Then
                map_letter_a = 255
                map_letter_fadestatus = 2
            End If
        Else
            map_letter_a = map_letter_a - (timerTicksPerFrame * 3.5)
            If map_letter_a <= 0 Then
                map_letter_fadestatus = 0
                map_letter_a = 0
                If map_letter_grh_next > 0 Then
                    map_letter_grh.GrhIndex = map_letter_grh_next
                    map_letter_fadestatus = 1
                    map_letter_grh_next = 0
                End If
            End If
        End If
    End If
    If Len(letter_text) Then
        Dim color(3) As RGBA
        Call RGBAList(color(), 179, 95, 0, map_letter_a)
        Call Grh_Render(letter_grh, 250 + gameplay_render_offset.x, 300 + gameplay_render_offset.y, color())
        Call Engine_Text_RenderGrande(letter_text, 360 - Engine_Text_Width(letter_text, False, 8) / 2 + gameplay_render_offset.x, 1 + gameplay_render_offset.y, color(), 8, _
                False, , CInt(map_letter_a))
    End If
    Exit Sub
RenderScreen_NombreMapa_Err:
    Call RegistrarError(Err.Number, Err.Description, "TileEngine_RenderScreen.RenderScreen_NombreMapa", Erl)
    Resume Next
End Sub

Private Sub DrawHotkey(ByVal HkIndex As Integer, ByVal PosX As Integer, ByVal PosY As Integer)
    Call Draw_GrhIndex(GRH_INVENTORYSLOT, PosX, PosY)
    If HotkeyList(HkIndex).Index > 0 Then
        If HotkeyList(HkIndex).Type = e_HotkeyType.Item Then
            Call Draw_GrhIndex(ObjData(HotkeyList(HkIndex).Index).GrhIndex, PosX, PosY)
        ElseIf HotkeyList(HkIndex).Type = e_HotkeyType.Spell Then
            Call Draw_GrhIndex(HechizoData(HotkeyList(HkIndex).Index).IconoIndex, PosX, PosY)
        End If
    End If
    Call Engine_Text_Render(HkIndex + 1, PosX + 12, PosY, COLOR_WHITE, 1, True)
End Sub

' ============================================================================
' RenderFloatingInventory - Dibuja la ventana de inventario flotante
' ============================================================================
Public Sub RenderFloatingInventory()
    On Error Resume Next
    
    Dim winX As Integer, winY As Integer
    Dim winW As Integer, winH As Integer
    Dim i As Integer, row As Integer, col As Integer
    Dim slotX As Integer, slotY As Integer
    Dim slotSize As Integer
    
    ' Inicializar posicion si es 0
    If g_InvWinX = 0 And g_InvWinY = 0 Then
        g_InvWinX = 200
        g_InvWinY = 100
    End If
    
    winX = g_InvWinX
    winY = g_InvWinY
    winW = 230
    winH = 300
    slotSize = 32
    
    ' Fondo de la ventana
    Call Engine_Draw_Box(winX, winY, winW, winH, RGBA_From_Comp(220, 30, 30, 35))
    
    ' Barra de titulo
    Call Engine_Draw_Box(winX, winY, winW, 22, RGBA_From_Comp(255, 60, 40, 40))
    Call RenderText("Inventario", winX + 8, winY + 4, COLOR_WHITE, 4, False)
    
    ' Boton cerrar [X]
    Call Engine_Draw_Box(winX + winW - 20, winY + 3, 16, 16, RGBA_From_Comp(200, 180, 40, 40))
    Call RenderText("X", winX + winW - 15, winY + 4, COLOR_WHITE, 4, False)
    
    ' Grid de inventario (6 columnas x 6 filas = 36 slots visibles)
    For i = 1 To 36
        row = (i - 1) \ 6
        col = (i - 1) Mod 6
        slotX = winX + 8 + col * (slotSize + 2)
        slotY = winY + 28 + row * (slotSize + 2)
        
        ' Fondo del slot (resaltar si seleccionado)
        If CLng(i) = frmMain.Inventario.SelectedItem Then
            Call Engine_Draw_Box(slotX, slotY, slotSize, slotSize, RGBA_From_Comp(255, 150, 220, 120))
        Else
            Call Engine_Draw_Box(slotX, slotY, slotSize, slotSize, RGBA_From_Comp(180, 20, 20, 25))
        End If
        
        ' Dibujar item si existe
        If i <= MAX_INVENTORY_SLOTS Then
            With frmMain.Inventario
                If .GrhIndex(i) > 0 Then
                    Call Draw_GrhIndex(.GrhIndex(i), slotX, slotY)
                    If .Amount(i) > 1 Then
                        Call RenderText(CStr(.Amount(i)), slotX + 2, slotY + slotSize - 12, COLOR_WHITE, 4, False)
                    End If
                End If
            End With
        End If
    Next i
    
    ' Oro
    Call Engine_Draw_Box(winX + 8, winY + winH - 28, winW - 16, 22, RGBA_From_Comp(200, 40, 35, 25))
    Call RenderText("Oro: " & Format$(UserStats.GLD, "#,##0"), winX + 14, winY + winH - 24, COLOR_WHITE, 4, False)
    
    ' Dibujar item arrastrado si hay uno
    If g_InvDraggingSlot > 0 And g_InvDragGrh > 0 Then
        Call Draw_GrhIndex(g_InvDragGrh, g_LastMouseX - 16, g_LastMouseY - 16)
    End If
End Sub

' ============================================================================
' RenderFloatingSpells - Dibuja la ventana de hechizos flotante
' ============================================================================
Public Sub RenderFloatingSpells()
    On Error Resume Next
    
    Dim winX As Integer, winY As Integer
    Dim winW As Integer, winH As Integer
    Dim i As Integer, visibleCount As Integer
    Dim rowY As Integer
    
    ' Inicializar posicion si es 0
    If g_SpellWinX = 0 And g_SpellWinY = 0 Then
        g_SpellWinX = 450
        g_SpellWinY = 100
    End If
    
    winX = g_SpellWinX
    winY = g_SpellWinY
    winW = 200
    winH = 280
    
    ' Fondo de la ventana
    Call Engine_Draw_Box(winX, winY, winW, winH, RGBA_From_Comp(220, 30, 30, 35))
    
    ' Barra de titulo
    Call Engine_Draw_Box(winX, winY, winW, 22, RGBA_From_Comp(255, 60, 40, 40))
    Call RenderText("Hechizos", winX + 8, winY + 4, COLOR_WHITE, 4, False)
    
    ' Boton cerrar [X]
    Call Engine_Draw_Box(winX + winW - 20, winY + 3, 16, 16, RGBA_From_Comp(200, 180, 40, 40))
    Call RenderText("X", winX + winW - 15, winY + 4, COLOR_WHITE, 4, False)
    
    ' Lista de hechizos
    visibleCount = 0
    For i = 1 To MAXHECHI
        If UserHechizos(i) > 0 Then
            If visibleCount < 10 Then
                rowY = winY + 28 + visibleCount * 22
                ' Fondo de fila (resaltar si seleccionado)
                If i = g_SelectedSpellSlot Then
                    Call Engine_Draw_Box(winX + 8, rowY, winW - 16, 20, RGBA_From_Comp(255, 100, 180, 80))
                Else
                    Call Engine_Draw_Box(winX + 8, rowY, winW - 16, 20, RGBA_From_Comp(150, 25, 25, 30))
                End If
                If UserHechizos(i) <= NumHechizos Then
                    Call RenderText(HechizoData(UserHechizos(i)).Nombre, winX + 12, rowY + 4, COLOR_WHITE, 4, False)
                End If
            End If
            visibleCount = visibleCount + 1
        End If
    Next i
    
    ' Botones Lanzar e Info
    Call Engine_Draw_Box(winX + 8, winY + winH - 32, 85, 24, RGBA_From_Comp(200, 180, 40, 40))
    Call RenderText("Lanzar", winX + 22, winY + winH - 28, COLOR_WHITE, 4, False)
    
    Call Engine_Draw_Box(winX + winW - 93, winY + winH - 32, 85, 24, RGBA_From_Comp(200, 180, 40, 40))
    Call RenderText("Info", winX + winW - 65, winY + winH - 28, COLOR_WHITE, 4, False)
End Sub

' ============================================================================
' FloatingWindow_HandleMouseDown - Maneja clicks en ventanas flotantes
' Retorna True si el click fue consumido
' ============================================================================
Public Function FloatingWindow_HandleMouseDown(ByVal mouseX As Integer, ByVal mouseY As Integer, ByVal Button As Integer) As Boolean
    On Error Resume Next
    
    Dim winW As Integer, winH As Integer
    
    FloatingWindow_HandleMouseDown = False
    
    ' Verificar click en ventana de inventario
    If g_ShowInventory Then
        winW = 230
        winH = 300
        
        ' Click en boton X (cerrar)
        If mouseX >= g_InvWinX + winW - 20 And mouseX <= g_InvWinX + winW - 4 Then
            If mouseY >= g_InvWinY + 3 And mouseY <= g_InvWinY + 19 Then
                g_ShowInventory = False
                FloatingWindow_HandleMouseDown = True
                Exit Function
            End If
        End If
        
        ' Click en barra de titulo (arrastrar)
        If mouseX >= g_InvWinX And mouseX <= g_InvWinX + winW Then
            If mouseY >= g_InvWinY And mouseY <= g_InvWinY + 22 Then
                g_DraggingWindow = 1
                g_DragOffsetX = mouseX - g_InvWinX
                g_DragOffsetY = mouseY - g_InvWinY
                FloatingWindow_HandleMouseDown = True
                Exit Function
            End If
        End If
        
        ' Click en slots del inventario
        Dim slotX As Integer, slotY As Integer, slotSize As Integer
        Dim row As Integer, col As Integer, clickedSlot As Integer
        slotSize = 32
        
        For clickedSlot = 1 To 36
            row = (clickedSlot - 1) \ 6
            col = (clickedSlot - 1) Mod 6
            slotX = g_InvWinX + 8 + col * (slotSize + 2)
            slotY = g_InvWinY + 28 + row * (slotSize + 2)
            
            If mouseX >= slotX And mouseX <= slotX + slotSize Then
                If mouseY >= slotY And mouseY <= slotY + slotSize Then
                    If Button = 2 Then
                        ' Click derecho: iniciar arrastre
                        If frmMain.Inventario.GrhIndex(CByte(clickedSlot)) > 0 Then
                            g_InvDraggingSlot = clickedSlot
                            g_InvDragGrh = frmMain.Inventario.GrhIndex(CByte(clickedSlot))
                        End If
                    Else
                        ' Click izquierdo: seleccionar
                        g_SelectedInvSlot = clickedSlot
                        Call frmMain.Inventario.SeleccionarItem(CByte(clickedSlot))
                    End If
                    FloatingWindow_HandleMouseDown = True
                    Exit Function
                End If
            End If
        Next clickedSlot
        
        ' Click en otro lugar de la ventana
        If mouseX >= g_InvWinX And mouseX <= g_InvWinX + winW Then
            If mouseY >= g_InvWinY And mouseY <= g_InvWinY + winH Then
                FloatingWindow_HandleMouseDown = True
                Exit Function
            End If
        End If
    End If
    
    ' Verificar click en ventana de hechizos
    If g_ShowSpells Then
        winW = 200
        winH = 280
        
        ' Click en boton X (cerrar)
        If mouseX >= g_SpellWinX + winW - 20 And mouseX <= g_SpellWinX + winW - 4 Then
            If mouseY >= g_SpellWinY + 3 And mouseY <= g_SpellWinY + 19 Then
                g_ShowSpells = False
                FloatingWindow_HandleMouseDown = True
                Exit Function
            End If
        End If
        
        ' Click en barra de titulo (arrastrar)
        If mouseX >= g_SpellWinX And mouseX <= g_SpellWinX + winW Then
            If mouseY >= g_SpellWinY And mouseY <= g_SpellWinY + 22 Then
                g_DraggingWindow = 2
                g_DragOffsetX = mouseX - g_SpellWinX
                g_DragOffsetY = mouseY - g_SpellWinY
                FloatingWindow_HandleMouseDown = True
                Exit Function
            End If
        End If
        
        ' Click en boton Lanzar
        If mouseX >= g_SpellWinX + 8 And mouseX <= g_SpellWinX + 93 Then
            If mouseY >= g_SpellWinY + winH - 32 And mouseY <= g_SpellWinY + winH - 8 Then
                ' Lanzar hechizo seleccionado
                If g_SelectedSpellSlot > 0 And g_SelectedSpellSlot <= MAXHECHI Then
                    If UserHechizos(g_SelectedSpellSlot) > 0 Then
                        Call WriteCastSpell(g_SelectedSpellSlot)
                    End If
                End If
                FloatingWindow_HandleMouseDown = True
                Exit Function
            End If
        End If
        
        ' Click en boton Info
        If mouseX >= g_SpellWinX + winW - 93 And mouseX <= g_SpellWinX + winW - 8 Then
            If mouseY >= g_SpellWinY + winH - 32 And mouseY <= g_SpellWinY + winH - 8 Then
                ' Mostrar info del hechizo seleccionado
                If g_SelectedSpellSlot > 0 And g_SelectedSpellSlot <= MAXHECHI Then
                    If UserHechizos(g_SelectedSpellSlot) > 0 Then
                        Call WriteSpellInfo(g_SelectedSpellSlot)
                    End If
                End If
                FloatingWindow_HandleMouseDown = True
                Exit Function
            End If
        End If
        
        ' Click en filas de hechizos
        Dim spellRowY As Integer, spellIndex As Integer, visibleIdx As Integer
        visibleIdx = 0
        For spellIndex = 1 To MAXHECHI
            If UserHechizos(spellIndex) > 0 Then
                If visibleIdx < 10 Then
                    spellRowY = g_SpellWinY + 28 + visibleIdx * 22
                    If mouseX >= g_SpellWinX + 8 And mouseX <= g_SpellWinX + winW - 8 Then
                        If mouseY >= spellRowY And mouseY <= spellRowY + 20 Then
                            g_SelectedSpellSlot = spellIndex
                            FloatingWindow_HandleMouseDown = True
                            Exit Function
                        End If
                    End If
                End If
                visibleIdx = visibleIdx + 1
            End If
        Next spellIndex
        
        ' Click en otro lugar de la ventana
        If mouseX >= g_SpellWinX And mouseX <= g_SpellWinX + winW Then
            If mouseY >= g_SpellWinY And mouseY <= g_SpellWinY + winH Then
                FloatingWindow_HandleMouseDown = True
                Exit Function
            End If
        End If
    End If
End Function

' ============================================================================
' FloatingWindow_HandleMouseMove - Maneja arrastre de ventanas
' ============================================================================
Public Sub FloatingWindow_HandleMouseMove(ByVal mouseX As Integer, ByVal mouseY As Integer)
    On Error Resume Next
    
    ' Guardar ultima posicion del mouse para doble-click
    g_LastMouseX = mouseX
    g_LastMouseY = mouseY
    
    If g_DraggingWindow = 1 Then
        g_InvWinX = mouseX - g_DragOffsetX
        g_InvWinY = mouseY - g_DragOffsetY
        ' Limites
        If g_InvWinX < 0 Then g_InvWinX = 0
        If g_InvWinY < 0 Then g_InvWinY = 0
        If g_InvWinX > 700 Then g_InvWinX = 700
        If g_InvWinY > 400 Then g_InvWinY = 400
    ElseIf g_DraggingWindow = 2 Then
        g_SpellWinX = mouseX - g_DragOffsetX
        g_SpellWinY = mouseY - g_DragOffsetY
        ' Limites
        If g_SpellWinX < 0 Then g_SpellWinX = 0
        If g_SpellWinY < 0 Then g_SpellWinY = 0
        If g_SpellWinX > 750 Then g_SpellWinX = 750
        If g_SpellWinY > 420 Then g_SpellWinY = 420
    End If
End Sub

' ============================================================================
' FloatingWindow_HandleMouseUp - Termina arrastre
' ============================================================================
' ============================================================================
' GetInvSlotAtMouse - Retorna el slot del inventario en la posicion del mouse
' ============================================================================
Private Function GetInvSlotAtMouse(ByVal mouseX As Integer, ByVal mouseY As Integer) As Integer
    On Error Resume Next
    
    Dim slotX As Integer, slotY As Integer
    Dim row As Integer, col As Integer, i As Integer
    Dim slotSize As Integer
    
    slotSize = 32
    GetInvSlotAtMouse = 0
    
    For i = 1 To 36
        row = (i - 1) \ 6
        col = (i - 1) Mod 6
        slotX = g_InvWinX + 8 + col * (slotSize + 2)
        slotY = g_InvWinY + 28 + row * (slotSize + 2)
        
        If mouseX >= slotX And mouseX <= slotX + slotSize Then
            If mouseY >= slotY And mouseY <= slotY + slotSize Then
                GetInvSlotAtMouse = i
                Exit Function
            End If
        End If
    Next i
End Function

Public Sub FloatingWindow_HandleMouseUp()
    On Error Resume Next
    
    ' Terminar arrastre de ventana
    g_DraggingWindow = 0
    
    ' Manejar drop de item arrastrado
    If g_InvDraggingSlot > 0 And g_ShowInventory Then
        Dim dropSlot As Integer
        dropSlot = GetInvSlotAtMouse(g_LastMouseX, g_LastMouseY)
        
        If dropSlot > 0 And dropSlot <> g_InvDraggingSlot Then
            Call WriteItemMove(CByte(g_InvDraggingSlot), CByte(dropSlot))
        End If
        
        ' Limpiar estado de arrastre
        g_InvDraggingSlot = 0
        g_InvDragGrh = 0
    End If
End Sub

' ============================================================================
' FloatingWindow_HandleDblClick - Maneja doble-clicks en ventanas flotantes
' ============================================================================
Public Function FloatingWindow_HandleDblClick(ByVal mouseX As Integer, ByVal mouseY As Integer) As Boolean
    On Error Resume Next
    
    FloatingWindow_HandleDblClick = False
    
    ' Doble-click en inventario: usar item seleccionado
    If g_ShowInventory And g_SelectedInvSlot > 0 Then
        Dim slotX As Integer, slotY As Integer, slotSize As Integer
        Dim row As Integer, col As Integer
        slotSize = 32
        
        row = (g_SelectedInvSlot - 1) \ 6
        col = (g_SelectedInvSlot - 1) Mod 6
        slotX = g_InvWinX + 8 + col * (slotSize + 2)
        slotY = g_InvWinY + 28 + row * (slotSize + 2)
        
        If mouseX >= slotX And mouseX <= slotX + slotSize Then
            If mouseY >= slotY And mouseY <= slotY + slotSize Then
                ' Usar el item
                If frmMain.Inventario.GrhIndex(g_SelectedInvSlot) > 0 Then
                    ' Equipar o usar segun tipo de item
                    Dim invSlot As Byte
                    invSlot = CByte(g_SelectedInvSlot)
                    Dim objType As Integer
                    objType = frmMain.Inventario.ObjType(invSlot)
                    ' Si es equipable, equipar/desequipar. Si no, usar.
                    Select Case objType
                        Case eObjType.otArmadura, eObjType.otESCUDO, eObjType.otCASCO, eObjType.otWeapon, eObjType.otAnillos, eObjType.otFlechas, eObjType.OtHerramientas, eObjType.otmagicos
                            Call WriteEquipItem(invSlot)
                        Case Else
                            Call WriteUseItem(invSlot)
                    End Select
                End If
                FloatingWindow_HandleDblClick = True
                Exit Function
            End If
        End If
    End If
    
    ' Doble-click en hechizos: lanzar hechizo seleccionado
    If g_ShowSpells And g_SelectedSpellSlot > 0 Then
        If UserHechizos(g_SelectedSpellSlot) > 0 Then
            Call WriteCastSpell(g_SelectedSpellSlot)
            FloatingWindow_HandleDblClick = True
            Exit Function
        End If
    End If
End Function

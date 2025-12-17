VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "clsFloatingWindow"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

' Clase base para ventanas flotantes arrastrables
' Funcionalidades: arrastre, anclaje, limites de pantalla, persistencia

Private Const TITLEBAR_HEIGHT As Integer = 20
Private Const ANCHOR_BUTTON_SIZE As Integer = 16
Private Const CLOSE_BUTTON_SIZE As Integer = 16

' Propiedades de la ventana
Private m_Title As String
Private m_Left As Integer
Private m_Top As Integer
Private m_Width As Integer
Private m_Height As Integer
Private m_Visible As Boolean
Private m_IsAnchored As Boolean
Private m_IsDragging As Boolean
Private m_DragOffsetX As Integer
Private m_DragOffsetY As Integer

' Limites de pantalla
Private m_ScreenWidth As Integer
Private m_ScreenHeight As Integer

' GrhIndex para elementos visuales
Private m_GrhBackground As Long
Private m_GrhTitlebar As Long
Private m_GrhAnchorOn As Long
Private m_GrhAnchorOff As Long
Private m_GrhClose As Long

' Identificador para persistencia
Private m_WindowID As String

' Eventos que pueden ser manejados por clases derivadas
Public Event OnShow()
Public Event OnHide()
Public Event OnMove(ByVal newLeft As Integer, ByVal newTop As Integer)
Public Event OnRenderContent(ByVal contentLeft As Integer, ByVal contentTop As Integer, ByVal contentWidth As Integer, ByVal contentHeight As Integer)
Public Event OnContentClick(ByVal relativeX As Integer, ByVal relativeY As Integer, ByVal Button As Integer)

Public Sub Initialize(ByVal windowID As String, ByVal title As String, ByVal width As Integer, ByVal height As Integer, ByVal screenWidth As Integer, ByVal screenHeight As Integer)
    m_WindowID = windowID
    m_Title = title
    m_Width = width
    m_Height = height
    m_ScreenWidth = screenWidth
    m_ScreenHeight = screenHeight
    m_Visible = False
    m_IsAnchored = False
    m_IsDragging = False
    
    ' Posicion por defecto: centro de pantalla
    m_Left = (screenWidth - width) / 2
    m_Top = (screenHeight - height) / 2
    
    ' Cargar posicion guardada si existe
    Call LoadPosition
End Sub

Public Sub Show()
    m_Visible = True
    RaiseEvent OnShow
End Sub

Public Sub Hide()
    m_Visible = False
    m_IsDragging = False
    RaiseEvent OnHide
End Sub

Public Sub Toggle()
    If m_Visible Then
        Call Hide
    Else
        Call Show
    End If
End Sub

Public Sub Render()
    If Not m_Visible Then Exit Sub
    
    Dim TempColor(0 To 3) As RGBA
    Dim ContentTop As Integer
    
    ' Color de fondo
    TempColor(0) = RGBA_From_Comp(230, 32, 32, 32)
    TempColor(1) = TempColor(0)
    TempColor(2) = TempColor(0)
    TempColor(3) = TempColor(0)
    
    ' Fondo de la ventana
    Call Engine_Draw_Box(m_Left, m_Top, m_Width, m_Height, RGBA_From_Comp(230, 32, 32, 32))
    
    ' Borde
    Call Engine_Draw_Box(m_Left, m_Top, m_Width, 1, RGBA_From_Comp(255, 80, 80, 80))
    Call Engine_Draw_Box(m_Left, m_Top + m_Height - 1, m_Width, 1, RGBA_From_Comp(255, 80, 80, 80))
    Call Engine_Draw_Box(m_Left, m_Top, 1, m_Height, RGBA_From_Comp(255, 80, 80, 80))
    Call Engine_Draw_Box(m_Left + m_Width - 1, m_Top, 1, m_Height, RGBA_From_Comp(255, 80, 80, 80))
    
    ' Barra de titulo
    If m_IsDragging Then
        Call Engine_Draw_Box(m_Left + 1, m_Top + 1, m_Width - 2, TITLEBAR_HEIGHT, RGBA_From_Comp(255, 60, 100, 140))
    Else
        Call Engine_Draw_Box(m_Left + 1, m_Top + 1, m_Width - 2, TITLEBAR_HEIGHT, RGBA_From_Comp(255, 48, 48, 48))
    End If
    
    ' Titulo
    RenderText m_Title, m_Left + 5, m_Top + 3, COLOR_WHITE, 1, False
    
    ' Boton de anclaje
    If m_IsAnchored Then
        Call Engine_Draw_Box(m_Left + m_Width - ANCHOR_BUTTON_SIZE - CLOSE_BUTTON_SIZE - 6, m_Top + 2, ANCHOR_BUTTON_SIZE, ANCHOR_BUTTON_SIZE, RGBA_From_Comp(255, 0, 150, 0))
    Else
        Call Engine_Draw_Box(m_Left + m_Width - ANCHOR_BUTTON_SIZE - CLOSE_BUTTON_SIZE - 6, m_Top + 2, ANCHOR_BUTTON_SIZE, ANCHOR_BUTTON_SIZE, RGBA_From_Comp(255, 100, 100, 100))
    End If
    
    ' Boton de cerrar
    Call Engine_Draw_Box(m_Left + m_Width - CLOSE_BUTTON_SIZE - 3, m_Top + 2, CLOSE_BUTTON_SIZE, CLOSE_BUTTON_SIZE, RGBA_From_Comp(255, 150, 50, 50))
    
    ' Contenido (delegado a clase derivada)
    ContentTop = m_Top + TITLEBAR_HEIGHT + 2
    RaiseEvent OnRenderContent(m_Left + 2, ContentTop, m_Width - 4, m_Height - TITLEBAR_HEIGHT - 4)
End Sub

' Funcion de texto eliminada - usa RenderText global

Public Function HandleMouseDown(ByVal mouseX As Integer, ByVal mouseY As Integer, ByVal Button As Integer) As Boolean
    If Not m_Visible Then
        HandleMouseDown = False
        Exit Function
    End If
    
    ' Verificar si el click esta dentro de la ventana
    If mouseX < m_Left Or mouseX > m_Left + m_Width Or mouseY < m_Top Or mouseY > m_Top + m_Height Then
        HandleMouseDown = False
        Exit Function
    End If
    
    HandleMouseDown = True
    
    ' Verificar boton de cerrar
    If IsInCloseButton(mouseX, mouseY) Then
        Call Hide
        Exit Function
    End If
    
    ' Verificar boton de anclaje
    If IsInAnchorButton(mouseX, mouseY) Then
        m_IsAnchored = Not m_IsAnchored
        Call SavePosition
        Exit Function
    End If
    
    ' Verificar barra de titulo para arrastre
    If IsInTitlebar(mouseX, mouseY) And Not m_IsAnchored Then
        m_IsDragging = True
        m_DragOffsetX = mouseX - m_Left
        m_DragOffsetY = mouseY - m_Top
        Exit Function
    End If
    
    ' Click en contenido
    If mouseY > m_Top + TITLEBAR_HEIGHT Then
        RaiseEvent OnContentClick(mouseX - m_Left, mouseY - m_Top - TITLEBAR_HEIGHT, Button)
    End If
End Function

Public Sub HandleMouseMove(ByVal mouseX As Integer, ByVal mouseY As Integer)
    If Not m_Visible Then Exit Sub
    If Not m_IsDragging Then Exit Sub
    
    Dim newLeft As Integer
    Dim newTop As Integer
    
    newLeft = mouseX - m_DragOffsetX
    newTop = mouseY - m_DragOffsetY
    
    ' Aplicar limites de pantalla
    If newLeft < 0 Then newLeft = 0
    If newTop < 0 Then newTop = 0
    If newLeft + m_Width > m_ScreenWidth Then newLeft = m_ScreenWidth - m_Width
    If newTop + m_Height > m_ScreenHeight Then newTop = m_ScreenHeight - m_Height
    
    If newLeft <> m_Left Or newTop <> m_Top Then
        m_Left = newLeft
        m_Top = newTop
        RaiseEvent OnMove(m_Left, m_Top)
    End If
End Sub

Public Sub HandleMouseUp()
    If m_IsDragging Then
        m_IsDragging = False
        Call SavePosition
    End If
End Sub

Private Function IsInTitlebar(ByVal mouseX As Integer, ByVal mouseY As Integer) As Boolean
    IsInTitlebar = (mouseX >= m_Left And mouseX <= m_Left + m_Width - ANCHOR_BUTTON_SIZE - CLOSE_BUTTON_SIZE - 10 And _
                    mouseY >= m_Top And mouseY <= m_Top + TITLEBAR_HEIGHT)
End Function

Private Function IsInCloseButton(ByVal mouseX As Integer, ByVal mouseY As Integer) As Boolean
    Dim btnLeft As Integer
    btnLeft = m_Left + m_Width - CLOSE_BUTTON_SIZE - 3
    IsInCloseButton = (mouseX >= btnLeft And mouseX <= btnLeft + CLOSE_BUTTON_SIZE And _
                       mouseY >= m_Top + 2 And mouseY <= m_Top + 2 + CLOSE_BUTTON_SIZE)
End Function

Private Function IsInAnchorButton(ByVal mouseX As Integer, ByVal mouseY As Integer) As Boolean
    Dim btnLeft As Integer
    btnLeft = m_Left + m_Width - ANCHOR_BUTTON_SIZE - CLOSE_BUTTON_SIZE - 6
    IsInAnchorButton = (mouseX >= btnLeft And mouseX <= btnLeft + ANCHOR_BUTTON_SIZE And _
                        mouseY >= m_Top + 2 And mouseY <= m_Top + 2 + ANCHOR_BUTTON_SIZE)
End Function

Public Sub SavePosition()
    On Error Resume Next
    Dim configPath As String
    configPath = App.path & "\..\Recursos\OUTPUT\UI.ini"
    
    Call WritePrivateProfileString(m_WindowID, "Left", CStr(m_Left), configPath)
    Call WritePrivateProfileString(m_WindowID, "Top", CStr(m_Top), configPath)
    Call WritePrivateProfileString(m_WindowID, "Anchored", IIf(m_IsAnchored, "1", "0"), configPath)
End Sub

Public Sub LoadPosition()
    On Error Resume Next
    Dim configPath As String
    Dim buffer As String * 32
    Dim result As Long
    
    configPath = App.path & "\..\Recursos\OUTPUT\UI.ini"
    
    result = GetPrivateProfileString(m_WindowID, "Left", CStr(m_Left), buffer, 32, configPath)
    If result > 0 Then m_Left = Val(Left$(buffer, result))
    
    result = GetPrivateProfileString(m_WindowID, "Top", CStr(m_Top), buffer, 32, configPath)
    If result > 0 Then m_Top = Val(Left$(buffer, result))
    
    result = GetPrivateProfileString(m_WindowID, "Anchored", "0", buffer, 32, configPath)
    If result > 0 Then m_IsAnchored = (Left$(buffer, result) = "1")
    
    ' Asegurar que la ventana este dentro de los limites
    Call ClampToScreen
End Sub

Private Sub ClampToScreen()
    If m_Left < 0 Then m_Left = 0
    If m_Top < 0 Then m_Top = 0
    If m_Left + m_Width > m_ScreenWidth Then m_Left = m_ScreenWidth - m_Width
    If m_Top + m_Height > m_ScreenHeight Then m_Top = m_ScreenHeight - m_Height
End Sub

' Propiedades publicas
Public Property Get Title() As String
    Title = m_Title
End Property

Public Property Let Title(ByVal value As String)
    m_Title = value
End Property

Public Property Get Left() As Integer
    Left = m_Left
End Property

Public Property Let Left(ByVal value As Integer)
    m_Left = value
    Call ClampToScreen
End Property

Public Property Get Top() As Integer
    Top = m_Top
End Property

Public Property Let Top(ByVal value As Integer)
    m_Top = value
    Call ClampToScreen
End Property

Public Property Get Width() As Integer
    Width = m_Width
End Property

Public Property Get Height() As Integer
    Height = m_Height
End Property

Public Property Get Visible() As Boolean
    Visible = m_Visible
End Property

Public Property Let Visible(ByVal value As Boolean)
    If value Then
        Call Show
    Else
        Call Hide
    End If
End Property

Public Property Get IsAnchored() As Boolean
    IsAnchored = m_IsAnchored
End Property

Public Property Let IsAnchored(ByVal value As Boolean)
    m_IsAnchored = value
End Property

Public Property Get IsDragging() As Boolean
    IsDragging = m_IsDragging
End Property

Public Property Get ContentTop() As Integer
    ContentTop = m_Top + TITLEBAR_HEIGHT + 2
End Property

Public Property Get ContentLeft() As Integer
    ContentLeft = m_Left + 2
End Property

Public Property Get ContentWidth() As Integer
    ContentWidth = m_Width - 4
End Property

Public Property Get ContentHeight() As Integer
    ContentHeight = m_Height - TITLEBAR_HEIGHT - 4
End Property

Public Function IsPointInWindow(ByVal x As Integer, ByVal y As Integer) As Boolean
    IsPointInWindow = (x >= m_Left And x <= m_Left + m_Width And y >= m_Top And y <= m_Top + m_Height)
End Function

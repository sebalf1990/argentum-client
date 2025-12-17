VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "clsStatsWindow"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

' ============================================================================
' clsStatsWindow - Floating Character Stats Window
' Displays HP, Mana, Stamina, Level, Experience, and Skills
' ============================================================================

' Layout constants
Private Const WINDOW_WIDTH As Integer = 220
Private Const WINDOW_HEIGHT As Integer = 350
Private Const BAR_HEIGHT As Integer = 14
Private Const BAR_MARGIN As Integer = 8
Private Const SECTION_SPACING As Integer = 20

' Base window using composition
Private m_BaseWindow As clsFloatingWindow

' ============================================================================
' Initialization
' ============================================================================
Public Sub Initialize(ByVal screenWidth As Integer, ByVal screenHeight As Integer)
    Set m_BaseWindow = New clsFloatingWindow
    Call m_BaseWindow.Initialize("StatsWindow", "Estadisticas", WINDOW_WIDTH, WINDOW_HEIGHT, screenWidth, screenHeight)
End Sub

Private Sub Class_Terminate()
    Set m_BaseWindow = Nothing
End Sub

' ============================================================================
' Window Control
' ============================================================================
Public Sub Show()
    If Not m_BaseWindow Is Nothing Then
        Call m_BaseWindow.Show
    End If
End Sub

Public Sub Hide()
    If Not m_BaseWindow Is Nothing Then
        Call m_BaseWindow.Hide
    End If
End Sub

Public Sub Toggle()
    If Not m_BaseWindow Is Nothing Then
        Call m_BaseWindow.Toggle
    End If
End Sub

' ============================================================================
' Rendering
' ============================================================================
Public Sub Render()
    If m_BaseWindow Is Nothing Then Exit Sub
    If Not m_BaseWindow.Visible Then Exit Sub
    
    ' Render base window
    Call m_BaseWindow.Render
    
    ' Render stats content
    Call RenderContent
End Sub

Private Sub RenderContent()
    Dim startX As Integer
    Dim startY As Integer
    Dim barWidth As Integer
    Dim currentY As Integer
    
    startX = m_BaseWindow.Left + BAR_MARGIN
    startY = m_BaseWindow.ContentTop + 8
    barWidth = WINDOW_WIDTH - BAR_MARGIN * 2
    currentY = startY
    
    ' Character Name & Level
    RenderText userName, startX, currentY, COLOR_WHITE, 1, False
    currentY = currentY + 16
    RenderText "Nivel " & UserStats.Lvl & " - " & ListaClases(UserStats.Clase), startX, currentY, COLOR_WHITE, 1, False
    currentY = currentY + SECTION_SPACING
    
    ' HP Bar
    RenderText "Vida", startX, currentY, COLOR_WHITE, 1, False
    currentY = currentY + 12
    Call RenderProgressBar(startX, currentY, barWidth, BAR_HEIGHT, UserStats.MinHp, UserStats.MaxHp, RGB(180, 40, 40), RGB(60, 20, 20))
    RenderText CStr(UserStats.MinHp) & "/" & CStr(UserStats.MaxHp), startX + barWidth - 60, currentY + 1, COLOR_WHITE, 4, False
    currentY = currentY + BAR_HEIGHT + 6
    
    ' Mana Bar
    RenderText "Mana", startX, currentY, COLOR_WHITE, 1, False
    currentY = currentY + 12
    Call RenderProgressBar(startX, currentY, barWidth, BAR_HEIGHT, UserStats.minman, UserStats.maxman, RGB(40, 80, 180), RGB(20, 30, 60))
    RenderText CStr(UserStats.minman) & "/" & CStr(UserStats.maxman), startX + barWidth - 60, currentY + 1, COLOR_WHITE, 4, False
    currentY = currentY + BAR_HEIGHT + 6
    
    ' Stamina Bar
    RenderText "Energia", startX, currentY, COLOR_WHITE, 1, False
    currentY = currentY + 12
    Call RenderProgressBar(startX, currentY, barWidth, BAR_HEIGHT, UserStats.MinSTA, UserStats.MaxSTA, RGB(180, 150, 40), RGB(60, 50, 20))
    RenderText CStr(UserStats.MinSTA) & "/" & CStr(UserStats.MaxSTA), startX + barWidth - 60, currentY + 1, COLOR_WHITE, 4, False
    currentY = currentY + BAR_HEIGHT + SECTION_SPACING
    
    ' Experience
    RenderText "Experiencia", startX, currentY, COLOR_WHITE, 1, False
    currentY = currentY + 12
    Dim expPercent As Single
    If UserStats.PasarNivel > 0 Then
        expPercent = (UserStats.exp / UserStats.PasarNivel) * 100
    Else
        expPercent = 100
    End If
    Call RenderProgressBar(startX, currentY, barWidth, BAR_HEIGHT, UserStats.exp, UserStats.PasarNivel, RGB(80, 180, 80), RGB(30, 60, 30))
    RenderText Format$(expPercent, "0.0") & "%", startX + barWidth - 40, currentY + 1, COLOR_WHITE, 4, False
    currentY = currentY + BAR_HEIGHT + SECTION_SPACING
    
    ' Gold
    RenderText "Oro: " & Format$(UserStats.GLD, "#,##0"), startX, currentY, COLOR_WHITE, 1, False
    currentY = currentY + 16
    
    ' Skill Points
    If SkillPoints > 0 Then
        RenderText "Puntos de Skill: " & SkillPoints, startX, currentY, COLOR_WHITE, 1, False
    End If
End Sub

Private Sub RenderProgressBar(ByVal x As Integer, ByVal y As Integer, ByVal w As Integer, ByVal h As Integer, ByVal current As Long, ByVal maximum As Long, ByVal fillColor As Long, ByVal bgColor As Long)
    Dim fillWidth As Integer
    Dim percent As Single
    
    ' Background
    Call Engine_Draw_Box(x, y, w, h, RGBA_From_Comp(255, (bgColor And &HFF0000) \ &H10000, (bgColor And &HFF00&) \ &H100, bgColor And &HFF&))
    
    ' Fill
    If maximum > 0 Then
        percent = current / maximum
        If percent > 1 Then percent = 1
        If percent < 0 Then percent = 0
        fillWidth = CInt(percent * w)
        
        If fillWidth > 0 Then
            Call Engine_Draw_Box(x, y, fillWidth, h, RGBA_From_Comp(255, (fillColor And &HFF0000) \ &H10000, (fillColor And &HFF00&) \ &H100, fillColor And &HFF&))
        End If
    End If
    
    ' Border
    Call Engine_Draw_Box(x, y, w, 1, RGBA_From_Comp(200, 80, 80, 80))
    Call Engine_Draw_Box(x, y + h - 1, w, 1, RGBA_From_Comp(200, 80, 80, 80))
    Call Engine_Draw_Box(x, y, 1, h, RGBA_From_Comp(200, 80, 80, 80))
    Call Engine_Draw_Box(x + w - 1, y, 1, h, RGBA_From_Comp(200, 80, 80, 80))
End Sub

' ============================================================================
' Input Handling
' ============================================================================
Public Function HandleMouseDown(ByVal mouseX As Integer, ByVal mouseY As Integer, ByVal Button As Integer) As Boolean
    If m_BaseWindow Is Nothing Then
        HandleMouseDown = False
        Exit Function
    End If
    
    HandleMouseDown = m_BaseWindow.HandleMouseDown(mouseX, mouseY, Button)
End Function

Public Sub HandleMouseMove(ByVal mouseX As Integer, ByVal mouseY As Integer)
    If m_BaseWindow Is Nothing Then Exit Sub
    Call m_BaseWindow.HandleMouseMove(mouseX, mouseY)
End Sub

Public Sub HandleMouseUp()
    If m_BaseWindow Is Nothing Then Exit Sub
    Call m_BaseWindow.HandleMouseUp
End Sub

' ============================================================================
' Properties
' ============================================================================
Public Property Get Visible() As Boolean
    If m_BaseWindow Is Nothing Then
        Visible = False
    Else
        Visible = m_BaseWindow.Visible
    End If
End Property

Public Property Get IsDragging() As Boolean
    If m_BaseWindow Is Nothing Then
        IsDragging = False
    Else
        IsDragging = m_BaseWindow.IsDragging
    End If
End Property

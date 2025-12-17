VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "clsIconBar"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

' Barra de iconos vertical - 9 botones
' Coordenadas deben coincidir con TileEngine_RenderScreen.bas

Private Const BUTTON_X As Integer = 900
Private Const BUTTON_WIDTH As Integer = 70
Private Const BUTTON_HEIGHT As Integer = 18
Private Const BUTTON_START_Y As Integer = 50
Private Const BUTTON_SPACING As Integer = 22
Private Const BUTTON_COUNT As Integer = 9

Private m_Initialized As Boolean

Public Sub Initialize(ByVal screenWidth As Integer, Optional ByVal screenHeight As Integer = 768)
    m_Initialized = True
End Sub

Private Function GetButtonY(ByVal idx As Integer) As Integer
    GetButtonY = BUTTON_START_Y + idx * BUTTON_SPACING
End Function

Public Sub Render()
    ' Render desactivado - botones dibujados en TileEngine_RenderScreen.bas
End Sub

Public Function HandleClick(ByVal mouseX As Integer, ByVal mouseY As Integer) As Boolean
    Dim i As Integer
    Dim btnY As Integer
    
    HandleClick = False
    
    If mouseX >= BUTTON_X And mouseX <= BUTTON_X + BUTTON_WIDTH Then
        For i = 0 To BUTTON_COUNT - 1
            btnY = GetButtonY(i)
            If mouseY >= btnY And mouseY <= btnY + BUTTON_HEIGHT Then
                Call ExecuteButtonAction(i)
                HandleClick = True
                Exit Function
            End If
        Next i
    End If
End Function

Private Sub ExecuteButtonAction(ByVal idx As Integer)
    On Error Resume Next
    Select Case idx
        Case 0  ' Ajustes
            frmOpciones.Show vbModeless
        Case 1  ' Stats
            ' TODO: Stats window
        Case 2  ' Inventario
            g_ShowInventory = Not g_ShowInventory
        Case 3  ' Hechizos
            g_ShowSpells = Not g_ShowSpells
        Case 4  ' Llavero
            FrmKeyInv.Show vbModeless
        Case 5  ' Grupo
            FrmGrupo.Show vbModeless
        Case 6  ' Quests
            FrmQuests.Show vbModeless
        Case 7  ' Clanes
            frmGuildLeader.Show vbModeless
        Case 8  ' Retos
            frmRetos.Show vbModeless
    End Select
End Sub

Public Sub HandleKeyPress(ByVal keyCode As Integer)
    Select Case keyCode
        Case vbKeyF1: Call ExecuteButtonAction(0)
        Case vbKeyF2: Call ExecuteButtonAction(1)
        Case vbKeyF3: Call ExecuteButtonAction(2)
        Case vbKeyF4: Call ExecuteButtonAction(3)
        Case vbKeyF5: Call ExecuteButtonAction(4)
        Case vbKeyF6: Call ExecuteButtonAction(5)
        Case vbKeyF7: Call ExecuteButtonAction(6)
        Case vbKeyF8: Call ExecuteButtonAction(7)
        Case vbKeyF9: Call ExecuteButtonAction(8)
    End Select
End Sub
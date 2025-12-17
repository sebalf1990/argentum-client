VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "clsSpellWindow"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

' ============================================================================
' clsSpellWindow - Floating Spells/Hechizos Window
' Displays user's known spells in a scrollable list
' ============================================================================

' Layout constants
Private Const WINDOW_WIDTH As Integer = 200
Private Const WINDOW_HEIGHT As Integer = 280
Private Const SPELL_ROW_HEIGHT As Integer = 24
Private Const LIST_MARGIN_LEFT As Integer = 8
Private Const LIST_MARGIN_TOP As Integer = 8
Private Const MAX_VISIBLE_SPELLS As Integer = 10

' Base window using composition
Private m_BaseWindow As clsFloatingWindow

' Spell list state
Private m_HoveredSpell As Integer
Private m_SelectedSpell As Integer
Private m_ScrollOffset As Integer

' ============================================================================
' Initialization
' ============================================================================
Public Sub Initialize(ByVal screenWidth As Integer, ByVal screenHeight As Integer)
    Set m_BaseWindow = New clsFloatingWindow
    Call m_BaseWindow.Initialize("SpellWindow", "Hechizos", WINDOW_WIDTH, WINDOW_HEIGHT, screenWidth, screenHeight)
    
    m_HoveredSpell = 0
    m_SelectedSpell = 0
    m_ScrollOffset = 0
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
    
    ' Render spell list
    Call RenderSpellList
End Sub

Private Sub RenderSpellList()
    Dim i As Integer
    Dim spellIndex As Integer
    Dim rowY As Integer
    Dim listStartX As Integer
    Dim listStartY As Integer
    Dim listWidth As Integer
    Dim visibleCount As Integer
    
    listStartX = m_BaseWindow.Left + LIST_MARGIN_LEFT
    listStartY = m_BaseWindow.ContentTop + LIST_MARGIN_TOP
    listWidth = WINDOW_WIDTH - LIST_MARGIN_LEFT * 2
    
    visibleCount = 0
    
    For i = 1 To MAXHECHI
        If UserHechizos(i) > 0 Then
            ' Check if this spell is visible (after scroll offset)
            If visibleCount >= m_ScrollOffset And visibleCount < m_ScrollOffset + MAX_VISIBLE_SPELLS Then
                spellIndex = i
                rowY = listStartY + (visibleCount - m_ScrollOffset) * SPELL_ROW_HEIGHT
                
                ' Draw row background
                If spellIndex = m_SelectedSpell Then
                    Call Engine_Draw_Box(listStartX, rowY, listWidth, SPELL_ROW_HEIGHT - 2, RGBA_From_Comp(255, 60, 80, 100))
                ElseIf spellIndex = m_HoveredSpell Then
                    Call Engine_Draw_Box(listStartX, rowY, listWidth, SPELL_ROW_HEIGHT - 2, RGBA_From_Comp(200, 50, 50, 60))
                Else
                    Call Engine_Draw_Box(listStartX, rowY, listWidth, SPELL_ROW_HEIGHT - 2, RGBA_From_Comp(150, 32, 32, 32))
                End If
                
                ' Draw spell name
                If UserHechizos(i) > 0 And UserHechizos(i) <= NumHechizos Then
                    RenderText HechizoData(UserHechizos(i)).Nombre, listStartX + 4, rowY + 4, COLOR_WHITE, 1, False
                End If
            End If
            visibleCount = visibleCount + 1
        End If
    Next i
    
    ' Draw scroll indicator if needed
    If visibleCount > MAX_VISIBLE_SPELLS Then
        Call RenderScrollIndicator(listStartX + listWidth - 8, listStartY, visibleCount)
    End If
End Sub

Private Sub RenderScrollIndicator(ByVal x As Integer, ByVal y As Integer, ByVal totalCount As Integer)
    Dim scrollHeight As Integer
    Dim thumbHeight As Integer
    Dim thumbY As Integer
    
    scrollHeight = MAX_VISIBLE_SPELLS * SPELL_ROW_HEIGHT - 4
    thumbHeight = (MAX_VISIBLE_SPELLS / totalCount) * scrollHeight
    If thumbHeight < 10 Then thumbHeight = 10
    
    thumbY = y + (m_ScrollOffset / (totalCount - MAX_VISIBLE_SPELLS)) * (scrollHeight - thumbHeight)
    
    ' Track
    Call Engine_Draw_Box(x, y, 6, scrollHeight, RGBA_From_Comp(150, 20, 20, 20))
    
    ' Thumb
    Call Engine_Draw_Box(x, thumbY, 6, thumbHeight, RGBA_From_Comp(200, 80, 80, 80))
End Sub

' ============================================================================
' Input Handling
' ============================================================================
Public Function HandleMouseDown(ByVal mouseX As Integer, ByVal mouseY As Integer, ByVal Button As Integer) As Boolean
    If m_BaseWindow Is Nothing Then
        HandleMouseDown = False
        Exit Function
    End If
    
    If m_BaseWindow.HandleMouseDown(mouseX, mouseY, Button) Then
        HandleMouseDown = True
        Exit Function
    End If
    
    ' Check for spell click
    Dim clickedSpell As Integer
    clickedSpell = GetSpellAtPosition(mouseX, mouseY)
    
    If clickedSpell > 0 Then
        m_SelectedSpell = clickedSpell
        HandleMouseDown = True
    End If
End Function

Public Sub HandleMouseMove(ByVal mouseX As Integer, ByVal mouseY As Integer)
    If m_BaseWindow Is Nothing Then Exit Sub
    
    Call m_BaseWindow.HandleMouseMove(mouseX, mouseY)
    m_HoveredSpell = GetSpellAtPosition(mouseX, mouseY)
End Sub

Public Sub HandleMouseUp()
    If m_BaseWindow Is Nothing Then Exit Sub
    Call m_BaseWindow.HandleMouseUp
End Sub

Private Function GetSpellAtPosition(ByVal mouseX As Integer, ByVal mouseY As Integer) As Integer
    If m_BaseWindow Is Nothing Then
        GetSpellAtPosition = 0
        Exit Function
    End If
    
    If Not m_BaseWindow.Visible Then
        GetSpellAtPosition = 0
        Exit Function
    End If
    
    Dim listStartX As Integer
    Dim listStartY As Integer
    Dim relX As Integer
    Dim relY As Integer
    Dim rowIndex As Integer
    Dim visibleIndex As Integer
    Dim i As Integer
    
    listStartX = m_BaseWindow.Left + LIST_MARGIN_LEFT
    listStartY = m_BaseWindow.ContentTop + LIST_MARGIN_TOP
    
    relX = mouseX - listStartX
    relY = mouseY - listStartY
    
    If relX < 0 Or relY < 0 Then
        GetSpellAtPosition = 0
        Exit Function
    End If
    
    If relX > WINDOW_WIDTH - LIST_MARGIN_LEFT * 2 Then
        GetSpellAtPosition = 0
        Exit Function
    End If
    
    rowIndex = relY \ SPELL_ROW_HEIGHT
    visibleIndex = rowIndex + m_ScrollOffset
    
    ' Find the actual spell slot
    Dim count As Integer
    count = 0
    For i = 1 To MAXHECHI
        If UserHechizos(i) > 0 Then
            If count = visibleIndex Then
                GetSpellAtPosition = i
                Exit Function
            End If
            count = count + 1
        End If
    Next i
    
    GetSpellAtPosition = 0
End Function

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

Public Property Get SelectedSpell() As Integer
    SelectedSpell = m_SelectedSpell
End Property

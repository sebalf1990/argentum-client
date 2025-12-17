VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "clsInventoryWindow"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

' ============================================================================
' clsInventoryWindow - Floating Inventory Window
' Displays user inventory in a 6x7 grid (42 slots)
' ============================================================================

' Layout constants
Private Const WINDOW_WIDTH As Integer = 230
Private Const WINDOW_HEIGHT As Integer = 320
Private Const GRID_COLS As Integer = 6
Private Const GRID_ROWS As Integer = 7
Private Const SLOT_SIZE As Integer = 32
Private Const SLOT_SPACING As Integer = 2
Private Const GRID_MARGIN_LEFT As Integer = 8
Private Const GRID_MARGIN_TOP As Integer = 28
Private Const GOLD_SLOT_HEIGHT As Integer = 24

' Base window using composition
Private m_BaseWindow As clsFloatingWindow

' Inventory state
Private m_HoveredSlot As Integer
Private m_SelectedSlot As Integer

' ============================================================================
' Initialization
' ============================================================================
Public Sub Initialize(ByVal screenWidth As Integer, ByVal screenHeight As Integer)
    Set m_BaseWindow = New clsFloatingWindow
    Call m_BaseWindow.Initialize("InventoryWindow", "Inventario", WINDOW_WIDTH, WINDOW_HEIGHT, screenWidth, screenHeight)
    
    m_HoveredSlot = 0
    m_SelectedSlot = 0
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
    
    ' Render base window (background, titlebar, buttons)
    Call m_BaseWindow.Render
    
    ' Render inventory grid
    Call RenderInventoryGrid
    
    ' Render gold at bottom
    Call RenderGoldSlot
End Sub

Private Sub RenderInventoryGrid()
    Dim i As Integer
    Dim row As Integer
    Dim col As Integer
    Dim slotX As Integer
    Dim slotY As Integer
    Dim gridStartX As Integer
    Dim gridStartY As Integer
    
    gridStartX = m_BaseWindow.Left + GRID_MARGIN_LEFT
    gridStartY = m_BaseWindow.ContentTop + 4
    
    For i = 1 To MAX_INVENTORY_SLOTS
        row = (i - 1) \ GRID_COLS
        col = (i - 1) Mod GRID_COLS
        
        slotX = gridStartX + col * (SLOT_SIZE + SLOT_SPACING)
        slotY = gridStartY + row * (SLOT_SIZE + SLOT_SPACING)
        
        ' Draw slot background
        If i = m_SelectedSlot Then
            ' Selected slot - lighter background
            Call Engine_Draw_Box(slotX, slotY, SLOT_SIZE, SLOT_SIZE, RGBA_From_Comp(255, 60, 80, 100))
        ElseIf i = m_HoveredSlot Then
            ' Hovered slot
            Call Engine_Draw_Box(slotX, slotY, SLOT_SIZE, SLOT_SIZE, RGBA_From_Comp(255, 50, 50, 60))
        Else
            ' Normal slot
            Call Engine_Draw_Box(slotX, slotY, SLOT_SIZE, SLOT_SIZE, RGBA_From_Comp(200, 24, 24, 24))
        End If
        
        ' Draw slot border
        Call Engine_Draw_Box(slotX, slotY, SLOT_SIZE, 1, RGBA_From_Comp(150, 60, 60, 60))
        Call Engine_Draw_Box(slotX, slotY + SLOT_SIZE - 1, SLOT_SIZE, 1, RGBA_From_Comp(150, 60, 60, 60))
        Call Engine_Draw_Box(slotX, slotY, 1, SLOT_SIZE, RGBA_From_Comp(150, 60, 60, 60))
        Call Engine_Draw_Box(slotX + SLOT_SIZE - 1, slotY, 1, SLOT_SIZE, RGBA_From_Comp(150, 60, 60, 60))
        
        ' Draw item if present
        Call RenderSlotContent(i, slotX, slotY)
    Next i
End Sub

Private Sub RenderSlotContent(ByVal Slot As Integer, ByVal slotX As Integer, ByVal slotY As Integer)
    If Slot < 1 Or Slot > MAX_INVENTORY_SLOTS Then Exit Sub
    
    With UserInventory.Slots(Slot)
        If .GrhIndex > 0 Then
            ' Draw item icon
            Call Draw_GrhIndex(.GrhIndex, slotX, slotY)
            
            ' Draw amount if > 1
            If .Amount > 1 Then
                Dim amountText As String
                If .Amount > 9999 Then
                    amountText = CStr(Round(.Amount / 1000, 1)) & "K"
                Else
                    amountText = CStr(.Amount)
                End If
                RenderText amountText, slotX + 2, slotY + SLOT_SIZE - 12, COLOR_WHITE, 4, False
            End If
            
            ' Draw equipped indicator
            If .Equipped Then
                Call Engine_Draw_Box(slotX, slotY, SLOT_SIZE, 2, RGBA_From_Comp(255, 0, 200, 100))
            End If
            
            ' Draw red tint if can't use
            If .PuedeUsar = 0 Then
                Call Engine_Draw_Box(slotX, slotY, SLOT_SIZE, SLOT_SIZE, RGBA_From_Comp(100, 150, 0, 0))
            End If
        End If
    End With
End Sub

Private Sub RenderGoldSlot()
    Dim goldX As Integer
    Dim goldY As Integer
    Dim goldWidth As Integer
    
    goldX = m_BaseWindow.Left + GRID_MARGIN_LEFT
    goldY = m_BaseWindow.Top + WINDOW_HEIGHT - GOLD_SLOT_HEIGHT - 8
    goldWidth = WINDOW_WIDTH - GRID_MARGIN_LEFT * 2
    
    ' Gold background
    Call Engine_Draw_Box(goldX, goldY, goldWidth, GOLD_SLOT_HEIGHT, RGBA_From_Comp(200, 40, 35, 20))
    
    ' Gold border
    Call Engine_Draw_Box(goldX, goldY, goldWidth, 1, RGBA_From_Comp(200, 180, 150, 50))
    Call Engine_Draw_Box(goldX, goldY + GOLD_SLOT_HEIGHT - 1, goldWidth, 1, RGBA_From_Comp(200, 180, 150, 50))
    
    ' Gold amount text
    Dim goldText As String
    goldText = "Oro: " & Format$(UserStats.GLD, "#,##0")
    RenderText goldText, goldX + 8, goldY + 5, COLOR_WHITE, 1, False
End Sub

' ============================================================================
' Input Handling
' ============================================================================
Public Function HandleMouseDown(ByVal mouseX As Integer, ByVal mouseY As Integer, ByVal Button As Integer) As Boolean
    If m_BaseWindow Is Nothing Then
        HandleMouseDown = False
        Exit Function
    End If
    
    ' First let base window handle (titlebar, close, anchor)
    If m_BaseWindow.HandleMouseDown(mouseX, mouseY, Button) Then
        HandleMouseDown = True
        Exit Function
    End If
    
    ' Check for slot click
    Dim clickedSlot As Integer
    clickedSlot = GetSlotAtPosition(mouseX, mouseY)
    
    If clickedSlot > 0 Then
        m_SelectedSlot = clickedSlot
        HandleMouseDown = True
        
        ' Left click selects, right click could show context menu
        If Button = vbLeftButton Then
            ' Update global selected slot for compatibility
            If UserInventory.Slots(clickedSlot).ObjIndex > 0 Then
                ' Could trigger use on double-click later
            End If
        End If
    End If
End Function

Public Sub HandleMouseMove(ByVal mouseX As Integer, ByVal mouseY As Integer)
    If m_BaseWindow Is Nothing Then Exit Sub
    
    Call m_BaseWindow.HandleMouseMove(mouseX, mouseY)
    
    ' Update hovered slot
    m_HoveredSlot = GetSlotAtPosition(mouseX, mouseY)
End Sub

Public Sub HandleMouseUp()
    If m_BaseWindow Is Nothing Then Exit Sub
    Call m_BaseWindow.HandleMouseUp
End Sub

Private Function GetSlotAtPosition(ByVal mouseX As Integer, ByVal mouseY As Integer) As Integer
    If m_BaseWindow Is Nothing Then
        GetSlotAtPosition = 0
        Exit Function
    End If
    
    If Not m_BaseWindow.Visible Then
        GetSlotAtPosition = 0
        Exit Function
    End If
    
    Dim gridStartX As Integer
    Dim gridStartY As Integer
    Dim relX As Integer
    Dim relY As Integer
    Dim col As Integer
    Dim row As Integer
    
    gridStartX = m_BaseWindow.Left + GRID_MARGIN_LEFT
    gridStartY = m_BaseWindow.ContentTop + 4
    
    relX = mouseX - gridStartX
    relY = mouseY - gridStartY
    
    If relX < 0 Or relY < 0 Then
        GetSlotAtPosition = 0
        Exit Function
    End If
    
    col = relX \ (SLOT_SIZE + SLOT_SPACING)
    row = relY \ (SLOT_SIZE + SLOT_SPACING)
    
    If col >= GRID_COLS Or row >= GRID_ROWS Then
        GetSlotAtPosition = 0
        Exit Function
    End If
    
    ' Check if within actual slot bounds (not in spacing)
    If (relX Mod (SLOT_SIZE + SLOT_SPACING)) > SLOT_SIZE Then
        GetSlotAtPosition = 0
        Exit Function
    End If
    
    If (relY Mod (SLOT_SIZE + SLOT_SPACING)) > SLOT_SIZE Then
        GetSlotAtPosition = 0
        Exit Function
    End If
    
    GetSlotAtPosition = row * GRID_COLS + col + 1
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

Public Property Get SelectedSlot() As Integer
    SelectedSlot = m_SelectedSlot
End Property

Public Property Get HoveredSlot() As Integer
    HoveredSlot = m_HoveredSlot
End Property

Attribute VB_Name = "ModWindowManager"
Option Explicit

' ============================================================================
' ModWindowManager.bas - Floating Window Manager
' Coordinates all floating windows, handles input routing and rendering
' ============================================================================

' Window instances (Public for IconBar access)
Public g_InventoryWindow As clsInventoryWindow
Public g_SpellWindow As clsSpellWindow
Public g_StatsWindow As clsStatsWindow

' Screen dimensions
Private m_ScreenWidth As Integer
Private m_ScreenHeight As Integer

' Initialization flag
Private m_Initialized As Boolean

' ============================================================================
' Initialization
' ============================================================================
Public Sub WindowManager_Initialize(ByVal screenWidth As Integer, ByVal screenHeight As Integer)
    m_ScreenWidth = screenWidth
    m_ScreenHeight = screenHeight
    
    ' Create window instances
    Set g_InventoryWindow = New clsInventoryWindow
    Set g_SpellWindow = New clsSpellWindow
    Set g_StatsWindow = New clsStatsWindow
    
    ' Initialize each window
    Call g_InventoryWindow.Initialize(screenWidth, screenHeight)
    Call g_SpellWindow.Initialize(screenWidth, screenHeight)
    Call g_StatsWindow.Initialize(screenWidth, screenHeight)
    
    m_Initialized = True
End Sub

Public Sub WindowManager_Terminate()
    Set g_InventoryWindow = Nothing
    Set g_SpellWindow = Nothing
    Set g_StatsWindow = Nothing
    m_Initialized = False
End Sub

' ============================================================================
' Rendering - Called from Graficos_Renderizado
' ============================================================================
Public Sub WindowManager_Render()
    If Not m_Initialized Then Exit Sub
    
    ' Render windows in order (bottom to top)
    If Not g_StatsWindow Is Nothing Then
        Call g_StatsWindow.Render
    End If
    
    If Not g_SpellWindow Is Nothing Then
        Call g_SpellWindow.Render
    End If
    
    If Not g_InventoryWindow Is Nothing Then
        Call g_InventoryWindow.Render
    End If
End Sub

' ============================================================================
' Window Toggle - Called from IconBar
' ============================================================================
Public Sub WindowManager_ToggleWindow(ByVal iconType As Integer)
    If Not m_Initialized Then Exit Sub
    
    Select Case iconType
        Case 2 ' eIcon_Inventory
            If Not g_InventoryWindow Is Nothing Then
                Call g_InventoryWindow.Toggle
            End If
            
        Case 3 ' eIcon_Spells
            If Not g_SpellWindow Is Nothing Then
                Call g_SpellWindow.Toggle
            End If
            
        Case 1 ' eIcon_Stats
            If Not g_StatsWindow Is Nothing Then
                Call g_StatsWindow.Toggle
            End If
    End Select
    
    ' Update IconBar visibility flags
    Call SyncIconBarFlags
End Sub

Private Sub SyncIconBarFlags()
    ' No longer needed - IconBar reads directly from g_InventoryWindow, g_SpellWindow, g_StatsWindow
End Sub

' ============================================================================
' Input Handling - Returns True if input was consumed by a window
' ============================================================================
Public Function WindowManager_HandleMouseDown(ByVal mouseX As Integer, ByVal mouseY As Integer, ByVal Button As Integer) As Boolean
    If Not m_Initialized Then
        WindowManager_HandleMouseDown = False
        Exit Function
    End If
    
    ' Check windows in reverse render order (top to bottom)
    If Not g_InventoryWindow Is Nothing Then
        If g_InventoryWindow.HandleMouseDown(mouseX, mouseY, Button) Then
            WindowManager_HandleMouseDown = True
            Exit Function
        End If
    End If
    
    If Not g_SpellWindow Is Nothing Then
        If g_SpellWindow.HandleMouseDown(mouseX, mouseY, Button) Then
            WindowManager_HandleMouseDown = True
            Exit Function
        End If
    End If
    
    If Not g_StatsWindow Is Nothing Then
        If g_StatsWindow.HandleMouseDown(mouseX, mouseY, Button) Then
            WindowManager_HandleMouseDown = True
            Exit Function
        End If
    End If
    
    WindowManager_HandleMouseDown = False
End Function

Public Sub WindowManager_HandleMouseMove(ByVal mouseX As Integer, ByVal mouseY As Integer)
    If Not m_Initialized Then Exit Sub
    
    If Not g_InventoryWindow Is Nothing Then
        Call g_InventoryWindow.HandleMouseMove(mouseX, mouseY)
    End If
    
    If Not g_SpellWindow Is Nothing Then
        Call g_SpellWindow.HandleMouseMove(mouseX, mouseY)
    End If
    
    If Not g_StatsWindow Is Nothing Then
        Call g_StatsWindow.HandleMouseMove(mouseX, mouseY)
    End If
End Sub

Public Sub WindowManager_HandleMouseUp()
    If Not m_Initialized Then Exit Sub
    
    If Not g_InventoryWindow Is Nothing Then
        Call g_InventoryWindow.HandleMouseUp
    End If
    
    If Not g_SpellWindow Is Nothing Then
        Call g_SpellWindow.HandleMouseUp
    End If
    
    If Not g_StatsWindow Is Nothing Then
        Call g_StatsWindow.HandleMouseUp
    End If
End Sub

' ============================================================================
' Window Visibility Getters
' ============================================================================
Public Function IsInventoryVisible() As Boolean
    If g_InventoryWindow Is Nothing Then
        IsInventoryVisible = False
    Else
        IsInventoryVisible = g_InventoryWindow.Visible
    End If
End Function

Public Function IsSpellWindowVisible() As Boolean
    If g_SpellWindow Is Nothing Then
        IsSpellWindowVisible = False
    Else
        IsSpellWindowVisible = g_SpellWindow.Visible
    End If
End Function

Public Function IsStatsWindowVisible() As Boolean
    If g_StatsWindow Is Nothing Then
        IsStatsWindowVisible = False
    Else
        IsStatsWindowVisible = g_StatsWindow.Visible
    End If
End Function

' ============================================================================
' Check if any window is being dragged
' ============================================================================
Public Function IsAnyWindowDragging() As Boolean
    IsAnyWindowDragging = False
    
    If Not g_InventoryWindow Is Nothing Then
        If g_InventoryWindow.IsDragging Then
            IsAnyWindowDragging = True
            Exit Function
        End If
    End If
    
    If Not g_SpellWindow Is Nothing Then
        If g_SpellWindow.IsDragging Then
            IsAnyWindowDragging = True
            Exit Function
        End If
    End If
    
    If Not g_StatsWindow Is Nothing Then
        If g_StatsWindow.IsDragging Then
            IsAnyWindowDragging = True
            Exit Function
        End If
    End If
End Function

' ============================================================================
' Diagnostic function - returns status code for debugging
' 0 = Not initialized, 1 = Initialized but inventory Nothing, 2 = Initialized OK
' ============================================================================
Public Function WindowManager_GetStatus() As Integer
    If Not m_Initialized Then
        WindowManager_GetStatus = 0
        Exit Function
    End If
    If g_InventoryWindow Is Nothing Then
        WindowManager_GetStatus = 1
        Exit Function
    End If
    WindowManager_GetStatus = 2
End Function

Public Function WindowManager_IsInventoryVisible() As Boolean
    If Not m_Initialized Then
        WindowManager_IsInventoryVisible = False
        Exit Function
    End If
    If g_InventoryWindow Is Nothing Then
        WindowManager_IsInventoryVisible = False
        Exit Function
    End If
    WindowManager_IsInventoryVisible = g_InventoryWindow.Visible
End Function

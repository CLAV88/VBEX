Attribute VB_Name = "fsview"
'
' fsview
' ======
'
' Introspect the file system.
' 1. Path exists
' 2. Sub Items of path
' 3. Recursive Find
' 4. Glob search (Only uses VB `?` and `*` wild cards)
'
' Copyright (c) 2014 Philip Wales
' This file (fsview.bas) is distributed under the MIT license.
' Obtain a copy of the license here: http://opensource.org/licenses/MIT

Private Const ALLPAT As String = "*"
Public Const PARDIR As String = ".."
Public Const CURDIR As String = "."
'
' Introspect FileSystem
' ---------------------
''
' returns whether file or folder exists or not.
' Use `vbType` argument to filter/include files.
' See <http://msdn.microsoft.com/en-us/library/dk008ty4(v=vs.90).aspx>
' for more types
Public Function Exists(ByVal file_path As String, _
        ByVal Optional vbType As Integer = vbDirectory) As Boolean

    If Not file_path = vbNullString Then
    
        Exists = Not (Dir$(RTrimSep(file_path), vbType) = vbNullString)
        
    End If
    
End Function
''
' Will not return true if a folder exists of the same name
Public Function FileExists(ByVal file_path As String)

    FileExists = Exists(file_path, vbNormal)
    
End Function
''
' vbDirectory option still includes files.
' FML
Public Function FolderExists(ByVal folder_path As String)

    FolderExists = Exists(folder_path, vbDirectory) _
                   And Not Exists(folder_path, vbNormal)
    
End Function
''
' returns a List of strings that are paths of subitems in root which
' match pat.
Public Function SubItems(ByVal root As String, ByVal Optional pat As String = ALLPAT, _
        ByVal Optional vbType As Integer = vbDirectory) As List
                  
    Set SubItems = New List
    
    Dim sub_item As String
    sub_item = Dir$(pJoin(root, pat), vbType)
    
    While sub_item <> vbNullString
    
        SubItems.Append pJoin(root, sub_item)
        sub_item = Dir$()
        
    Wend
    
End Function
Public Function SubFiles(ByVal root As String, _
        Optional pat As String = ALLPAT) As List

    Set SubFiles = SubItems(root, pat, vbNormal)
    
End Function
''
' Why on earth would I want . and .. included in sub folders?
' When vbDirectory is passed to dir it still includes files.  Why the would
' anyone want that?  Now there is no direct way to actually list subfolders
' only get a list of both files and folders and filter out files
Public Function SubFolders(ByVal root As String, ByVal Optional pat As String = vbNullString, _
        ByVal Optional skipDots As Boolean = True) As List
                    
    Set SubFolders = SubItems(root, pat, vbDirectory)
    
    If skipDots And SubFolders.count > 0 Then

        If SubFolders.Item(1) = pJoin(root, CURDIR) Then ' else root
            SubFolders.Remove 1
            If SubFolders.Item(1) = pJoin(root, PARDIR) Then  ' else mountpoint
                SubFolders.Remove 1
            End If 
        End IF
        
    End If
    
    Set SubFolders = seq.Filter("os.FolderExists", SubFolders)
    
End Function
Public Function Find(ByVal root As String, ByVal Optional pat As String = "*", _
        ByVal Optional vbType As Integer = vbNormal) As List

    Set Find = New List
    
    FindRecurse root, Find, pat, vbType
    
End Function
Private Sub FindRecurse(ByVal root As String, ByRef items As List, _
        Optional pat As String = "*", ByVal Optional vbType As Integer = vbNormal)
    
    Dim folder As Variant
    For Each folder In SubFolders(root)
        FindRecurse folder, items, pat, vbType
    Next folder
    
    items.Extend SubItems(root, pat, vbType)
    
End Sub
Public Function Glob(ByVal pattern As String) As List
    
    Dim root As String
    root = LongestRoot(pattern)
    
    Dim patterns() As String
    patterns = Split(right$(pattern, Len(pattern) - Len(root)), SEP)
    
    Set Glob = GlobRecurse(root, patterns, 0)
    
End Function
Private Function GlobRecurse(ByVal root As String, ByRef patterns() As String, ByVal index As Integer) As List
   
    If index = UBound(patterns) Then
        Set GlobRecurse = SubItems(root, patterns(index))
    Else
        
        Set GlobRecurse = New List
        
        Dim folder As Variant
        For Each folder In SubFolders(root, patterns(index))
            GlobRecurse.Extend GlobRecurse(folder, patterns, index + 1)
        Next folder
        
    End If
    
End Function

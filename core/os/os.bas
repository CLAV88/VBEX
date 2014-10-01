Attribute VB_Name = "os"
'
' os
' ==
'
' Advanced filesystem operations for VBA.
'
' Copyright (c) 2014 Philip Wales
' This file (os.bas) is distributed under the MIT license.
' Obtain a copy of the license here: http://opensource.org/licenses/MIT
'
' Scripting.FileSystemObject is slow and unstable since it relies on sending
' signals to ActiveX objects across the system.  This module only uses built-in
' functions of Visual Basic, such as `Dir`, `Kill`, `Name`, etc.
'
' _os is not object oriented_, it only deals with path-strings or Lists of
' path-strings.
'
' Most code is based as closely on Python's "os" module (hence the name) and
' sub modules as possible despite language differences.
'
'
' Sources referenced:
' http://hg.python.org/cpython/file/7ff62415e426/Lib/os.py
' http://hg.python.org/cpython/file/7ff62415e426/Lib/ntpath.py
' http://hg.python.org/cpython/file/7ff62415e426/Lib/shutil.py
'
Option Explicit
'
' Constants
' ---------
'
Public Const EXTSEP As String = "."
Public Const PARDIR As String = ".."
Public Const CURDIR As String = "."
Public Const SEP As String = "\" ' "/" for UNIX if you ever run VBA on UNIX...
Public Const PATHSEP As String = ";" ' not used...

Private Const ALLPAT As String = "*"

Public Enum osErrNums
    overwriteRefusal '= ?
    unknown ' = ?
End Enum
Private Enum vbErrNums
    badFileName = 52
    fileNotFound = 53
    alreadyExists = 58
    accessError = 75
    pathNotFound = 76
End Enum

'
' Path Manipulations
' ------------------
'
''
' Returns the base name of a path, either the lowest folder or file
' Note! that `suffix` will be removed from the end regardless if its an actual filename
' extension or not.
' root/name.ext -> name.ext
' name.ext -> name.ext
' root/ ->
' root/name+suffix -> suffix -> name
' "root/name.ext" -> ".ext" -> "name"
' "root/name.ext" -> "ext" -> "name."  !
Public Function BaseName(ByVal file_path As String, ByVal Optional suffix As String) As String

    Dim path_split As Variant
    path_split = Split(file_path, SEP)
    
    BaseName = path_split(UBound(path_split))
    
    If suffix <> vbNullString Then
    
        Dim base_length As Integer
        base_length = Len(BaseName) - Len(suffix)
        
        ' replace suffix with nothing and only look for suffix the end of the string
        BaseName = left$(BaseName, base_length) & _
                   Replace$(BaseName, suffix, "", base_length + 1)
                   
    End If
    
End Function
''
' Returns the path of the parent folder. This is the opposite of `BaseName`.
' r/o/o/t/name -> r/o/o/t
' r/o/o/t/ -> r/o/o/t
' name ->
Public Function RootName(ByVal path As String) As String

    RootName = ParentDir(path, 1)
    
End Function
''
' path -> 0 -> path
' path/ -> 1 -> path
' root/name -> 1 -> root ! `RootName`
' E/D/C/B/A/name -> 2 -> E/D/C/B
' E/D/C/B/A/name -> 3 -> E/D/C
' E/D/C/B/A/name -> 5 -> E
' E/D/C/B/A/name -> 6 ->
' E/D/C/B/A/name -> 7 ->
' ...
Public Function ParentDir(ByVal path As String, _
                   ByVal parent_height As Integer) As String
    
    Dim split_path As Variant
    split_path = Split(path, SEP)
    
    Dim parent_count As Integer
    parent_count = UBound(split_path) - parent_height
    
    If parent_count > 0 Then

        ReDim Preserve split_path(LBound(split_path) To parent_count)
        
    End If
     
    ParentDir = Join(split_path, SEP)
   
End Function
''
' Returns the file extension of the file.
' path.ext -> .ext
' path ->
' path.bad.ext -> .ext
Public Function Ext(ByVal file_path As String) As String

    Dim base_name As String
    base_name = BaseName(file_path)
    
    If InStr(base_name, EXTSEP) Then
    
        Dim fsplit As Variant
        fsplit = Split(base_name, EXTSEP)
        
        Ext = EXTSEP & fsplit(UBound(fsplit))
        
    End If
    
End Function
''
' Removes trailing SEP from path
' path/ -> path
' path -> path
' /path -> /path
Private Function RTrimSep(ByVal path As String) As String

    If right$(path, 1) = SEP Then
        ' ends with SEP return all but end
        RTrimSep = left$(path, Len(path) - 1)
        
    Else
        RTrimSep = path
        
    End If
    
End Function
''
' safely join two strings to form a path, inserting `SEP` if needed.
' root/ -> base -> root/base
' root -> base -> root/base
' root -> /base -> root//base ! BAD BAD BAD
Public Function pJoin(ByVal root_path As String, ByVal file_path As String) As String

    pJoin = RTrimSep(root_path) & SEP & file_path
    
End Function
''
' Inserts `to_append` in behind of the base name of string `file_path` but in
' front of the extension
' root/name.ext -> appended -> root/nameappended.ext
Public Function Append(ByVal file_path As String, ByVal to_append As String) As String

    Dim file_ext As String
    file_ext = Ext(file_path)
    
    Append = pJoin(RootName(file_path), _
                   BaseName(file_path, suffix:=file_ext) & _
                   to_append & file_ext)
                     
End Function
''
' Inserts `to_prepend` in front of the base name of string `file_path`
' root/name.ext -> prepended -> root/prependedname.ext
Public Function Prepend(ByVal file_path As String, ByVal to_prepend As String) As String
    
    Prepend = pJoin(RootName(file_path), to_prepend & BaseName(file_path))

End Function
''
' Replaces current extension of `file_path` with `new_ext`
' path.old -> new -> path.new
' path.old -> .new -> path.new
' path -> new -> path.new
' path.bad.old -> new -> path.bad.new
Public Function ChangeExt(ByVal file_path As String, ByVal new_ext As String) As String
    
    Dim current_ext As String
    current_ext = Ext(file_path)
    
    Dim base_length As String
    base_length = Len(file_path) - Len(current_ext)
    
    ' ".ext" or "ext" -> "ext"
    new_ext = Replace$(new_ext, EXTSEP, vbNullString, 1, 1)

    ChangeExt = left$(file_path, base_length) & EXTSEP & new_ext
    
End Function
''
' Returns if the path contains a "?" or a "*"
Public Function IsPattern(ByVal path As String) As Boolean
    IsPattern = (InStr(1, path, "?") + InStr(1, path, "*") <> 0)
End Function
''
' Finds the longest path in pattern that is not a pattern.
Public Function LongestRoot(ByVal pattern As String) As String
    
    Dim charPos As Integer
    charPos = InStr(1, pattern, "?") - 1
    If charPos < 0 Then charPos = Len(pattern)
    
    Dim wildPos As Integer
    wildPos = InStr(1, pattern, "*") - 1
    If wildPos < 0 Then wildPos = Len(pattern)

    LongestRoot = RootName(Left$(pattern, IIf(charPos <= wildPos, charPos, wildPos)))
    
End Function
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
'
'
' File System Modifications
' -------------------------
'
'
Public Sub Move(ByVal src_path As String, ByVal dest_path As String, _
        Optional create_parent As Boolean = False)

    On Error GoTo ErrHandler

    DestIsFolderFeature dest_path, src_path
    
    If create_parent Then CreateRootPath dest_path
    
    Name src_path As dest_path
    If Not Exists(dest_path) Then Err.Raise -1
    If Exists(src_path) Then Err.Raise -2
    
CleanExit:
    Exit Function
  
ErrHandler:
    Select Case Err.Number
    Case -1
        Err.Raise osErrNums.unknown, "Move", _
            "Destination still doesn't exist after errorless `Name As`"
    Case -2
        Err.Raise osErrNums.unkown, "Move", _
            "Source still exists after errorless `Name As`"
    ' Case vbErrors
    ' Raise better error
    Case Else
        Err.Raise Err.Number
    End Select

End Function
Public Sub Remove(ByVal file_path As String)
    

    On Error GoTo ErrHandler
    
    Kill file_path
    
    If Exists(dest_path) Then Err.Raise -1
    
CleanExit:
    Exit Function

ErrHandler:
    Select Case Err.Number
    Case -1
        Err.Raise osErrNums.unknown, "Remove", _
            "Destination still exists after errorless `Kill`"
    ' Case vbErrors
    ' Raise better error
    Case Else
        Err.Raise Err.Number
    End Select
    
End Function
Public Sub MakeDir(ByVal folder_path As String, ByVal Optional create_parent As Boolean = False)
                
    Dim check As Boolean
   On Error GoTo ErrHandler
        
    If create_parent Then CreateRootPath folder_path
    MkDir folder_path
    
    If Not FolderExists(dest_path) Then Err.Raise -1
    
CleanExit:
    Exit Function
    
ErrHandler:
    Select Case Err.Number
    Case -1
        Err.Raise osErrNums.unknown, "MakeDir", _
            "Destination does not exist after errorless `MkDir`"
    ' Case vbErrors
    ' Raise better error
    Case Else
        Err.Raise Err.Number
    End Select
    
End Function
Public Sub CopyFile(ByVal src_path As String, ByVal dest_path As String, _
        Optional create_parent As Boolean = False)
    
    On Error GoTo ErrHandler
    
    DestIsFolderFeature dest_path, src_path
    
    If FileExists(dest_path) Then Err.Raise -1
    
    If create_parent Then CreateRootPath dest_path
    FileCopy src_path, dest_path
    
    If Not FileExists(dest_path) Then Err.Raise -2, "CopyFile"

CleanExit:
   Exit Function

ErrHandler:
    Select Case Err.Number
    Case -1
        Err.Raise osErrNums.overwriteRefusal, "CopyFile", _
            "Will not overwrite file at destination.  Remove it first if desired."
    Case -2
        Err.Raise osErrNums.unknown, "CopyFile", _
            "Destination does not exist after errorless `FileCopy`"
    ' Case vbErrors
    ' Raise better error
    Case Else
        Err.Raise Err.Number
    End Select
    
End Function
Private Sub CreateRootPath(ByVal path As String)

    Dim parent_folder As String
    parent_folder = RootName(path)
    
    If Not FolderExists(parent_folder) Then
    
        MakeDir parent_folder, create_parent:=True
        
    End If
    
End Function
Private Sub DestIsFolderFeature(ByRef dest_path As String, _
        ByVal src_path As String)
    
    If right$(dest_path, 1) = SEP Or FolderExists(dest_path) Then 
        ' Destination is a folder.
        dest_path = pJoin(dest_path, BaseName(src_path))
    
    End If
    
End Sub

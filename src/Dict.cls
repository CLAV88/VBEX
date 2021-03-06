VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Dict"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = True
Option Explicit
'
' Dict
' ====
'
' Mutelable Mapping class based on Python's `Dict`
'
' Copywrite (C) 2014 Philip Wales
' This file (Dict.cls) is distributed under the GPL-3.0 license
' Obtain a copy of the GPL-3.0 license <http://opensource.org/licenses/GPL-3.0>
'
Implements Showable
' Should implement more Interfaces but this is the only mapping type yet.
'
' Public Members
' --------------
' None
'
' Should implement more Interfaces but this is the only mapping type yet.
'
Private pDict As Scripting.Dictionary
'
' Constructors
' ------------
'
Private Sub Class_Initialize()

    Set pDict = New Scripting.Dictionary
    
End Sub
Public Function Create(ParamArray assocs()) As Dict

    Set Create = FromAssocs(List.Copy(assocs))
    
End Function
Public Function FromLists(ByVal ks As Linear, ByVal vs As Linear) As Dict
    Debug.Assert (ks.UpperBound = vs.UpperBound And _
        ks.LowerBound = vs.LowerBound) ' TODO: raise error
    
    Dim result As New Dict
    
    ' TODO: use Zip. then expect users to use `FromAssocs`?
    Dim i As Long
    For i = ks.LowerBound To ks.UpperBound
        result.Add ks.Item(i), vs.Item(i)
    Next i
    
    Set FromLists = result
    
End Function
' TODO: use a defined type not a tuple but the type must be public....
Public Function FromAssocs(ByVal assocs) As Dict
    
    Dim result As New Dict
    
    Dim kv
    For Each kv In assocs
        result.Add kv.key, kv.Value
    Next
    
    Set FromAssocs = result
    
End Function
Public Function FromKeys(ByVal keySet as ISetLike, ByVal op As IApplicable) As Dict

    Dim result As New Dict
    
    Dim key As Variant
    For Each key In keySet.Elements
        result.Add key, op.Apply(key)
    Next

    Set FromKeys = result
End Function
Public Function Copy(ByVal thatD As Dict) As Dict

    Set Copy = FromAssocs(thatD.Pairs)
    
End Function
'
' Public Properties
' -----------------
'
' ### Single Item actions
'
''
' `Item`: same as usual
' TODO: how does pDict do this -> hashtables
Public Property Get Item(ByVal k) As Variant
Attribute Item.VB_UserMemId = 0

    If pDict.Exists(k) Then
        Assign Item, pDict(k)
    Else
        KeyError Me, "Item", defShow.Show(k) & " is not an entry"
    End If
    
End Property
Public Property Let Item(ByVal k, ByVal v)
Attribute Item.VB_UserMemId = 0

    pDict(k) = v
    
End Property
Public Property Set Item(ByVal k, ByVal v)
Attribute Item.VB_UserMemId = 0

    Set pDict(k) = v
    
End Property
''
' GetItem: Return default value if `key` does not exist
Public Function GetItem(ByVal k, Optional ByVal default = Empty) As Variant
        
    Console.PrintLine "WARNING: Method Dict.GetItem is deprecated."
    Assign GetItem, GetOrElse(k, default)
    
End Function
Public Function GetOrElse(ByVal k, Optional ByVal default = Empty) As Variant

    Assign GetOrElse, MaybeGet(k).GetOrElse(default)

End Function
Public Function MaybeGet(ByVal k) As Maybe

    Set MaybeGet = Maybe.Attempt(ByName.Create(OnArgs.Make("Item", VbGet, Me), k))

End Function
''
' Pair: return a `Tuple` of (key, value)
Public Function Pair(ByVal k) As Assoc

    Set Pair = Assoc.Make(k, pDict(k))
    
End Function
'
<<<<<<< HEAD
' ### Produce Dicts
'
Public Function MapValues(ByVal op As IApplicable) As Dict

    Dim result As New Dict
    Dim key As Variant
    For Each key In pDict.keys
        result.Add key, op.Apply(pDict(key))
=======
' Produce Dicts
' -------------
'
Public Function MapValues(ByVal op As Applicable) As Dict

    Dim result As New Dict
    Dim k
    For Each k In pDict.Keys
        result.Add k, op.Apply(pDict.Item(k))
>>>>>>> 657e6ad39542e8f79bc640baf67c60ca2cd876a7
    Next

    Set MapValues = result

End Function
'
<<<<<<< HEAD
' ### Produce Lists
=======
' FilterKeys
' FilterValues
' FilterNotKeys
' FilterNotValues
'
' TODO: is Dict SetLike?
'
' Produce Lists
' -------------
>>>>>>> 657e6ad39542e8f79bc640baf67c60ca2cd876a7
'
Public Function Keys() As List

    Set Keys = List.Copy(pDict.Keys)
    
End Function
Public Function Values() As List

    Set Values = List.Copy(pDict.Items)
    
End Function
Public Function Pairs() As List

    Dim result As List
    Set result = List.Create
    
    Dim k
    For Each k In Keys
        result.Append Pair(k)
    Next
    
    Set Pairs = result
    
End Function
'
' Public Methods
' --------------
'
Public Function Count() As Long

    Count = pDict.Count
    
End Function
Public Sub Add(ByVal k, ByVal v)

    pDict.Add k, v
    
End Sub
''
' Remove: Remove entry
Public Sub Remove(ByVal k)

    pDict.Remove k
    
End Sub
Public Function Exists(ByVal k) As Boolean

    Exists = pDict.Exists(k)
    
End Function
Public Sub Update(ByVal other As Dict)

    Dim k
    For Each k In other.Keys
        pDict(k) = other(k)
    Next
    
End Sub
Public Sub Clear()

    pDict.RemoveAll
    
End Sub
'
' Showable
' ---------
'
Public Function Show() As String

    Show = defShow.ShowableObject(Me, Pairs.ToArray)
    
End Function
Private Function Showable_Show() As String

    Showable_Show = Show

End Function

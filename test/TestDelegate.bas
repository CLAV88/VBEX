Attribute VB_Name = "DictTest"
Option Explicit
Option Private Module

'@TestModule
Private Assert As New Rubberduck.AssertClass

Private globalVar As String
Private Const HELLO_WORLD As String = "Hello, World!"
Private Const GOODBYE_WORLD As String = "GoodBye, World!"

Public Sub HelloWorld()
    
    globalVar = HELLO_WORLD
    
End Sub
Public Sub GoodByeWorld()

    globalVar = GOODBYE_WORLD

End Sub

'@TestMethod
Public Sub TestHelloWorld()

    globalVar = GOODBYE_WORLD
    Assert.AreEqual GOODBYE_WORLD, globalVar, "Initialization"

    Dim thunk As DelegateProj.Delegate
    Set thunk = DelegateProj.Delegate.Create(AddressOf HelloWorld)
    thunk.Run
    
    Assert.AreEqual HELLO_WORLD, globalVar, "Value changed"
    
End Sub
'@TestMethod
Public Sub TestMultipleInstances()

    globalVar = ""

    Dim thunk1 As DelegateProj.Delegate
    Set thunk1 = DelegateProj.Delegate.Create(AddressOf HelloWorld)
    
    Dim thunk2 As DelegateProj.Delegate
    Set thunk2 = DelegateProj.Delegate.Create(AddressOf GoodByeWorld)
    
    Assert.AreEqual "", globalVar, "Check initialization"
    thunk1.Run
    Assert.AreEqual HELLO_WORLD, globalVar, "First Thunk call"
    thunk2.Run
    Assert.AreEqual GOODBYE_WORLD, globalVar, "Second Thunk call"
    

End Sub

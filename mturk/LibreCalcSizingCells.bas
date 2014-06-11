REM  Resizes columns and rows; sets cells to word-wrap; freezes top row.
REM  To be used in LibreCalc

Sub Main

End Sub


sub SizingCells
rem ----------------------------------------------------------------------
rem define variables
dim document   as object
dim dispatcher as object
rem ----------------------------------------------------------------------
rem get access to the document
document   = ThisComponent.CurrentController.Frame
dispatcher = createUnoService("com.sun.star.frame.DispatchHelper")

rem ----------------------------------------------------------------------
dispatcher.executeDispatch(document, ".uno:SelectAll", "", 0, Array())

rem ----------------------------------------------------------------------
dim args2(0) as new com.sun.star.beans.PropertyValue
args2(0).Name = "RowHeight"
args2(0).Value = 762

dispatcher.executeDispatch(document, ".uno:RowHeight", "", 0, args2())

rem ----------------------------------------------------------------------
dim args3(0) as new com.sun.star.beans.PropertyValue
args3(0).Name = "ColumnWidth"
args3(0).Value = 2540

dispatcher.executeDispatch(document, ".uno:ColumnWidth", "", 0, args3())

rem ----------------------------------------------------------------------
dim args4(0) as new com.sun.star.beans.PropertyValue
args4(0).Name = "WrapText"
args4(0).Value = true

dispatcher.executeDispatch(document, ".uno:WrapText", "", 0, args4())

 
rem ----------------------------------------------------------------------
dispatcher.executeDispatch(document, ".uno:FreezePanes", "", 0, Array())


end sub

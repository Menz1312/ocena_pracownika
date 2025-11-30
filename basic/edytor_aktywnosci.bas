REM  ***** MAKRA DLA FORMULARZA EDYCJI (frmEdytorAktywnosci)  *****

' To makro przypisz do zdarzenia "Status elementu zmieniony" w lstTypAktywnosci
Sub OnTypAktywnosciChanged(oEvent As Object)
    Dim oForm As Object
    Dim oList As Object
    Dim oStatement As Object
    Dim oResultSet As Object
    Dim iSelectedID As Integer
    Dim dPunkty As Double
    Dim bCzyCiagla As Boolean
    
    oList = oEvent.Source.Model
    oForm = oList.Parent
    
    ' Sprawdź, czy coś wybrano
    If oList.SelectedItems(0) = -1 Then Exit Sub
    
    ' Pobierz ID wybranej aktywności
    ' (Korzystamy z ValueItemList, bo BoundField może nie być jeszcze zaktualizowane)
    iSelectedID = oList.ValueItemList(oList.SelectedItems(0))
    
    ' Pobierz połączenie z bazą z formularza
    If IsNull(oForm.ActiveConnection) Then Exit Sub
    oStatement = oForm.ActiveConnection.createStatement()
    
    ' Pobierz punkty i flagę ciągłości dla tego typu
    sSQL = "SELECT ""punkty_domyslne"", ""czy_ciagla"" FROM ""oceny_pracownikow"".""sl_typy_aktywnosci"" WHERE ""id_typu_aktywnosci"" = " & iSelectedID
    oResultSet = oStatement.executeQuery(sSQL)
    
    If oResultSet.next() Then
        ' 1. OBSŁUGA PUNKTÓW
        dPunkty = oResultSet.getDouble(1)
        If oResultSet.wasNull() Then
            ' Jeśli NULL (np. publikacja), wyczyść pole i pozwól wpisać
            oForm.getByName("numPunkty").BoundField.updateNull()
        Else
            ' Jeśli są punkty domyślne, wpisz je
            oForm.getByName("numPunkty").BoundField.updateDouble(dPunkty)
        End If
        
        ' 2. OBSŁUGA DATY ZAKOŃCZENIA
        bCzyCiagla = oResultSet.getBoolean(2)
        Dim oDataZak As Object
        oDataZak = oForm.getByName("datZakonczenia")
        
        If bCzyCiagla Then
            oDataZak.Enabled = True ' Odblokuj
        Else
            oDataZak.BoundField.updateNull() ' Wyczyść datę zakończenia
            oDataZak.Enabled = False ' Zablokuj
        End If
    End If
End Sub

' To makro przypisz do przycisku [Zapisz] w Edytorze
Sub ZapiszIZamknij
    Dim oForm As Object
    oForm = ThisComponent.DrawPage.Forms.GetByIndex(0).getByName("SubForm_Edycja")
    
    If oForm.isNew Then
        oForm.insertRow()
    Else
        oForm.updateRow()
    End If
    
    ' Zamknij okno edytora
    ThisComponent.CurrentController.Frame.close(True)
    
    ' Opcjonalnie: Spróbuj odświeżyć Dashboard, jeśli jest otwarty w tle
    On Error Resume Next
    Dim oDash As Object
    oDash = ThisDatabaseDocument.FormDocuments.getByName("frmAdministracyjny")
    If Not IsNull(oDash.Component) Then
        oDash.Component.DrawPage.Forms.GetByIndex(0).getByName("SubForm_Aktywnosci").reload()
        oDash.Component.DrawPage.Forms.GetByIndex(0).getByName("SubForm_Podsumowanie").reload()
    End If
End Sub

' To makro przypisz do przycisku [Anuluj]
Sub AnulujZmiany
    ThisComponent.CurrentController.Frame.close(True)
End Sub
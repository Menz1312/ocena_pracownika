REM  ***** MAKRA DLA FORMULARZA EDYCJI (frmEdytorAktywnosci)  *****

' 1. To makro przypisz do zdarzenia "Status elementu zmieniony" w lstTypAktywnosci
Sub OnTypAktywnosciChanged(oEvent As Object)
    Dim oForm As Object
    Dim oList As Object
    Dim oStatement As Object
    Dim oResultSet As Object
    Dim iSelectedID As Integer
    
    ' Zmienne do przechowywania pobranych danych
    Dim dPunktyDomyslne As Double, dPunktyMin As Double, dPunktyMax As Double
    Dim bDomyslneNull As Boolean, bMinNull As Boolean, bMaxNull As Boolean
    Dim bCzyCiagla As Boolean
    
    oList = oEvent.Source.Model
    oForm = oList.Parent
    
    ' Sprawdź, czy coś wybrano
    If oList.SelectedItems(0) = -1 Then Exit Sub
    
    ' Pobierz ID wybranej aktywności
    iSelectedID = oList.ValueItemList(oList.SelectedItems(0))
    
    If IsNull(oForm.ActiveConnection) Then Exit Sub
    oStatement = oForm.ActiveConnection.createStatement()
    
    ' Pobierz wszystkie potrzebne dane jednym zapytaniem
    sSQL = "SELECT ""punkty_domyslne"", ""czy_ciagla"", ""punkty_min"", ""punkty_max"" FROM ""oceny_pracownikow"".""sl_typy_aktywnosci"" WHERE ""id_typu_aktywnosci"" = " & iSelectedID
    oResultSet = oStatement.executeQuery(sSQL)
    
    If oResultSet.next() Then
        ' Pobieramy wartości do zmiennych
        dPunktyDomyslne = oResultSet.getDouble(1)
        bDomyslneNull = oResultSet.wasNull()
        
        bCzyCiagla = oResultSet.getBoolean(2)
        
        dPunktyMin = oResultSet.getDouble(3)
        bMinNull = oResultSet.wasNull()
        
        dPunktyMax = oResultSet.getDouble(4)
        bMaxNull = oResultSet.wasNull()
        
        ' =========================================================
        ' A. USTAWIANIE WARTOŚCI STARTOWEJ PUNKTÓW (TWOJA ZMIANA)
        ' =========================================================
        Dim oFieldPunkty As Object
        oFieldPunkty = oForm.getByName("numPunkty").BoundField
        
        If Not bDomyslneNull Then
            ' Priorytet 1: Jest sztywna wartość domyślna (np. 60) -> Wpisz ją
            oFieldPunkty.updateDouble(dPunktyDomyslne)
        ElseIf Not bMinNull Then
            ' Priorytet 2: Brak domyślnej, ale jest minimum (np. 5) -> Wpisz minimum
            oFieldPunkty.updateDouble(dPunktyMin)
        Else
            ' Priorytet 3: Brak domyślnej i brak minimum -> Wyzeruj pole (0.00)
            oFieldPunkty.updateDouble(0.00)
        End If
        
        ' =========================================================
        ' B. CZAS TRWANIA (CIĄGŁOŚĆ)
        ' =========================================================
        Dim oDataZak As Object
        oDataZak = oForm.getByName("datZakonczenia")
        
        If bCzyCiagla Then
            oDataZak.Enabled = True
        Else
            oDataZak.BoundField.updateNull()
            oDataZak.Enabled = False
        End If
        
        ' =========================================================
        ' C. WYŚWIETLANIE LIMITÓW (MIN / MAX)
        ' =========================================================
        Dim txtMin As Object, txtMax As Object
        txtMin = oForm.getByName("txtMin")
        txtMax = oForm.getByName("txtMax")
        
        ' Wpisz MIN lub wyczyść
        If bMinNull Then
            txtMin.Text = "" 
        Else
            txtMin.Text = dPunktyMin
        End If
        
        ' Wpisz MAX lub wyczyść
        If bMaxNull Then
            txtMax.Text = ""
        Else
            txtMax.Text = dPunktyMax
        End If
    End If
End Sub

' 2. To makro przypisz do przycisku [Zapisz]
Sub ZapiszIZamknij
    Dim oForm As Object
    Dim oNumPunkty As Object
    Dim txtMin As Object, txtMax As Object
    Dim dWartosc As Double
    Dim dMin As Double, dMax As Double
    
    oForm = ThisComponent.DrawPage.Forms.GetByIndex(0).getByName("SubForm_Edycja")
    oNumPunkty = oForm.getByName("numPunkty")
    
    ' --- WALIDACJA PUNKTÓW ---
    
    ' Sprawdź czy wpisano cokolwiek
    If IsNull(oNumPunkty.BoundField.getString()) Or oNumPunkty.BoundField.getString() = "" Then
        MsgBox "Proszę wpisać liczbę punktów.", 16, "Błąd walidacji"
        Exit Sub
    End If
    
    dWartosc = oNumPunkty.BoundField.getDouble()
    txtMin = oForm.getByName("txtMin")
    txtMax = oForm.getByName("txtMax")
    
    ' Sprawdź MINIMUM (jeśli pole limitu nie jest puste)
    If txtMin.Text <> "" Then
        dMin = CDbl(txtMin.Text)
        If dWartosc < dMin Then
            MsgBox "Wpisana liczba punktów (" & dWartosc & ") jest mniejsza niż wymagane minimum (" & dMin & ").", 16, "Błąd walidacji"
            Exit Sub
        End If
    End If
    
    ' Sprawdź MAXIMUM (jeśli pole limitu nie jest puste)
    If txtMax.Text <> "" Then
        dMax = CDbl(txtMax.Text)
        If dWartosc > dMax Then
            MsgBox "Wpisana liczba punktów (" & dWartosc & ") przekracza dozwolone maksimum (" & dMax & ").", 16, "Błąd walidacji"
            Exit Sub
        End If
    End If
    
    ' --- KONIEC WALIDACJI ---

    ' Zapisz rekord
    If oForm.isNew Then
        oForm.insertRow()
    Else
        oForm.updateRow()
    End If
    
    ' Zamknij okno
    ThisComponent.CurrentController.Frame.close(True)
    
    ' Odśwież Dashboard (jeśli otwarty)
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
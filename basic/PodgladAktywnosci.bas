REM  *****  BASIC  *****

' Pomocnicza funkcja otwierająca formularz
Function OtworzFormularz(sNazwa As String) As Object
    Dim oFormDoc As Object
    oFormDoc = ThisDatabaseDocument.FormDocuments.getByName(sNazwa)
    OtworzFormularz = oFormDoc.open()
End Function

Sub ZmienFiltrPracownika(oEvent As Object)
    Dim oForm As Object
    Dim oStatement As Object
    Dim sSQL As String
    Dim iWybraneID As Integer
    Dim oListBox As Object

    ' 1. Pobieramy kontrolkę
    oListBox = oEvent.Source.Model
    
    ' Zabezpieczenie: czy coś wybrano?
    If IsEmpty(oListBox.SelectedValue) Then Exit Sub
    
    iWybraneID = CInt(oListBox.SelectedValue)
    oForm = oListBox.Parent

    ' 2. Połączenie
    oStatement = oForm.ActiveConnection.createStatement()

    ' 3. Zapytanie SQL (Dostosowane do tabeli filtr_uzytkownika)
    ' Zwróć uwagę na zmianę nazw kolumn: wybrane_id_pracownika -> id_pracownika
    sSQL = "INSERT INTO pcz_oceny.filtr_uzytkownika (nazwa_uzytkownika, id_pracownika) " & _
           "VALUES (current_user, " & iWybraneID & ") " & _
           "ON CONFLICT (nazwa_uzytkownika) " & _
           "DO UPDATE SET id_pracownika = EXCLUDED.id_pracownika, ostatnia_aktualizacja = CURRENT_TIMESTAMP;"

    ' 4. Wykonanie i odświeżenie
    oStatement.executeUpdate(sSQL)
    oForm.reload()
End Sub

Sub ZmienFiltrOkresu(oEvent As Object)
    Dim oForm As Object
    Dim oStatement As Object
    Dim sSQL As String
    Dim iWybraneID As Integer
    Dim oListBox As Object

    oListBox = oEvent.Source.Model
    
    If IsEmpty(oListBox.SelectedValue) Then Exit Sub
    
    iWybraneID = CInt(oListBox.SelectedValue)
    oForm = oListBox.Parent

    oStatement = oForm.ActiveConnection.createStatement()

    ' 3. Zapytanie SQL (Dostosowane do tabeli filtr_uzytkownika)
    ' Zwróć uwagę na zmianę nazw kolumn: wybrane_id_okresu -> id_okresu
    sSQL = "INSERT INTO pcz_oceny.filtr_uzytkownika (nazwa_uzytkownika, id_okresu) " & _
           "VALUES (current_user, " & iWybraneID & ") " & _
           "ON CONFLICT (nazwa_uzytkownika) " & _
           "DO UPDATE SET id_okresu = EXCLUDED.id_okresu, ostatnia_aktualizacja = CURRENT_TIMESTAMP;"

    oStatement.executeUpdate(sSQL)
    oForm.reload()
End Sub

Sub OtworzDoDodania
    Dim oDashForm As Object
    Dim oEdytorDoc As Object
    Dim oEdytorForm As Object
    Dim iPracownikID As Integer
    
    oDashForm = ThisComponent.DrawPage.Forms.GetByIndex(0) ' MainForm
    
    ' 1. Pobierz ID wybranego pracownika z tabeli filtr_globalny
    iPracownikID = oDashForm.getInt(oDashForm.findColumn("id_pracownika"))
    
    ' 2. Otwórz formularz edycji
    oEdytorDoc = OtworzFormularz("frmEdytorAktywnosci")
    
    ' 3. Skonfiguruj go do dodawania
    oEdytorForm = oEdytorDoc.DrawPage.Forms.GetByIndex(0).getByName("SubForm_Edycja")
    
    ' Czekaj chwilę, aż formularz się załaduje
    Do While oEdytorForm.isLoaded = False
        Wait 10
    Loop
    
    oEdytorForm.moveToInsertRow() ' Tryb nowego rekordu
    
    ' 4. Wpisz ID pracownika do ukrytego pola (powiązanie rekordu)
    'oEdytorForm.getByName("txtIDPracownika").BoundField.updateInt(iPracownikID)
End Sub

' Przypisz do przycisku [Edytuj zaznaczoną...]
Sub OtworzDoEdycji
    Dim oDashSubForm As Object
    Dim oEdytorDoc As Object
    Dim oEdytorForm As Object
    Dim iAktywnoscID As Integer
    
    ' 1. Pobierz ID aktywności z zaznaczonego wiersza w tabeli
    oDashSubForm = ThisComponent.DrawPage.Forms.GetByIndex(0).getByName("SubForm_Aktywnosci")
    
    If oDashSubForm.RowCount = 0 Then Exit Sub ' Nic nie ma
    iAktywnoscID = oDashSubForm.getInt(oDashSubForm.findColumn("id_aktywnosci"))
    
    ' 2. Otwórz formularz edycji
    oEdytorDoc = OtworzFormularz("frmEdytorAktywnosci")
    
    ' 3. Skonfiguruj go do edycji konkretnego rekordu (filtrowanie)
    oEdytorForm = oEdytorDoc.DrawPage.Forms.GetByIndex(0).getByName("SubForm_Edycja")
    
    Do While oEdytorForm.isLoaded = False
        Wait 10
    Loop
    
    ' Ustaw filtr, aby pokazać tylko ten jeden rekord
    oEdytorForm.Filter = """id_aktywnosci"" = " & iAktywnoscID
    oEdytorForm.ApplyFilter = True
    oEdytorForm.reload()
End Sub

' Przypisz do przycisku [Usuń zaznaczoną]
Sub UsunAktywnosc
    Dim oDashSubForm As Object
    Dim iAktywnoscID As Integer
    Dim oStatement As Object
    Dim sSQL As String
    
    ' 1. Pobierz podformularz i ID
    oDashSubForm = ThisComponent.DrawPage.Forms.GetByIndex(0).getByName("SubForm_Aktywnosci")
    
    If oDashSubForm.RowCount = 0 Then Exit Sub
    iAktywnoscID = oDashSubForm.getInt(oDashSubForm.findColumn("id_aktywnosci"))
    
    ' 2. Potwierdzenie
    If MsgBox("Czy na pewno chcesz usunąć tę aktywność?", 36, "Potwierdzenie") = 6 Then
        
        ' 3. Zamiast .deleteRow(), wykonujemy SQL bezpośrednio na bazie
        If IsNull(oDashSubForm.ActiveConnection) Then
             MsgBox "Brak połączenia z bazą!", 16, "Błąd"
             Exit Sub
        End If
        
        oStatement = oDashSubForm.ActiveConnection.createStatement()
        
        ' Budujemy zapytanie SQL DELETE
        sSQL = "DELETE FROM ""pcz_oceny"".""aktywnosci_pracownika"" WHERE ""id_aktywnosci"" = " & iAktywnoscID
        
        ' Wykonujemy
        On Error GoTo BladSQL
        oStatement.executeUpdate(sSQL)
        
        ' 4. Odświeżamy widoki, żeby zniknęło z listy
        oDashSubForm.reload()
        ThisComponent.DrawPage.Forms.GetByIndex(0).getByName("SubForm_Podsumowanie").reload()
        
        Exit Sub
        
    BladSQL:
        MsgBox "Błąd usuwania SQL: " & Error, 16, "Błąd"
    End If
End Sub
REM  ***** BASIC  *****

Option Explicit

' Główna procedura wywoływana przy zdarzeniu "Stan elementu zmieniony" listy lstTypAktywnosci
Sub PoWyborzeTypuAktywnosci(oEvent As Object)
    Dim oForm As Object
    Dim oListBox As Object
    Dim iWybraneID As Integer
    
    ' Dostęp do bazy
    Dim oConn As Object
    Dim oStmt As Object
    Dim oResult As Object
    Dim sSQL As String
    
    ' Zmienne konfiguracyjne
    Dim bCzyCiagla As Boolean
    Dim bCzyWspol As Boolean
    Dim dPktMin As Double, dPktMax As Double, dPktDef As Double
    Dim bMaMin As Boolean, bMaMax As Boolean, bMaDef As Boolean
    
    ' Kontrolki formularza
    Dim cDataDo As Object
    Dim cUdzial As Object
    Dim cPunkty As Object
    Dim cInfoMin As Object
    Dim cInfoMax As Object
    
    ' 1. Inicjalizacja
    oListBox = oEvent.Source.Model
    oForm = oListBox.Parent
    
    ' Jeśli nic nie wybrano, przerwij
    If IsEmpty(oListBox.SelectedValue) Then Exit Sub
    iWybraneID = CInt(oListBox.SelectedValue)
    
    ' Pobranie referencji do kontrolek
    cDataDo = oForm.getByName("datZakonczenia")
    cUdzial = oForm.getByName("numUdzial")
    cPunkty = oForm.getByName("numPunkty")
    cInfoMin = oForm.getByName("txtPunktyMin")
    cInfoMax = oForm.getByName("txtPunktyMax")
    
    ' 2. Zapytanie SQL - Pobieramy flagi i punkty
    ' Łączymy się z filtrem_uzytkownika, żeby wiedzieć jaki jest ROK OCENY
    sSQL = "SELECT " & _
           "  ta.czy_ciagla, ta.czy_udzial, " & _
           "  ka.punkty_min, ka.punkty_max, ka.punkty_domyslne " & _
           "FROM pcz_oceny.typy_aktywnosci ta " & _
           "JOIN pcz_oceny.konfiguracja_aktywnosci ka ON ta.id_typu = ka.id_typu " & _
           "JOIN pcz_oceny.filtr_uzytkownika f ON ka.id_okresu = f.id_okresu " & _
           "WHERE f.nazwa_uzytkownika = CURRENT_USER " & _
           "  AND ta.id_typu = " & iWybraneID
           
    oConn = oForm.ActiveConnection
    oStmt = oConn.createStatement()
    oResult = oStmt.executeQuery(sSQL)
    
    If oResult.next() Then
        ' Odczyt danych (GetBoolean/GetDouble)
        bCzyCiagla = oResult.getBoolean(1)
        bCzyWspol = oResult.getBoolean(2)
        
        ' Obsługa NULLi dla punktów (0 oznacza zazwyczaj NULL w metodzie getDouble, trzeba uważać)
        ' Lepsza metoda: sprawdzenie wasNull()
        dPktMin = oResult.getDouble(3)
        bMaMin = Not oResult.wasNull()
        
        dPktMax = oResult.getDouble(4)
        bMaMax = Not oResult.wasNull()
        
        dPktDef = oResult.getDouble(5)
        bMaDef = Not oResult.wasNull()
    Else
        MsgBox "Błąd: Nie znaleziono konfiguracji dla tej aktywności w bieżącym okresie!", 16, "Błąd"
        Exit Sub
    End If
    
    ' 3. Logika Interfejsu
    
    ' A. Czy ciągła (Data zakończenia)
    If bCzyCiagla Then
        cDataDo.Enabled = True
    Else
        cDataDo.Enabled = False
        cDataDo.BoundField.updateNull() ' Czyścimy pole w bazie
        ' cDataDo.Text = "" ' Opcjonalnie czyścimy wizualnie
    End If
    
    ' B. Czy współautorstwo (Udział %)
    If bCzyWspol Then
        cUdzial.Enabled = True
    Else
        cUdzial.Enabled = False
        cUdzial.BoundField.updateDouble(100.00) ' Ustawiamy sztywno 100%
    End If
    
    ' C. Punkty - Informacja wizualna
    If bMaMin Then cInfoMin.Text = "Min: " & dPktMin Else cInfoMin.Text = "Min: -"
    If bMaMax Then cInfoMax.Text = "Max: " & dPktMax Else cInfoMax.Text = "Max: -"
    
    ' D. Punkty - Wstawienie domyślnych (tylko jeśli pole jest puste lub równe 0)
    If bMaDef Then
        If cPunkty.BoundField.getDouble() = 0 Then
            cPunkty.BoundField.updateDouble(dPktDef)
        End If
    End If

End Sub

Sub OdswiezFormularzGlowny()
    Dim oComponents As Object
    Dim oDoc As Object
    Dim oEnum As Object
    Dim sTitle As String
    Dim oDrawPage As Object
    Dim oForms As Object
    Dim oMainForm As Object
    
    ' Pobieramy wszystkie otwarte okna w LibreOffice
    oComponents = StarDesktop.getComponents()
    oEnum = oComponents.createEnumeration()
    
    ' Pętla po oknach
    While oEnum.hasMoreElements()
        oDoc = oEnum.nextElement()
        
        ' Sprawdzamy tylko dokumenty (żeby nie trafić na dziwne obiekty systemowe)
        If HasUnoInterfaces(oDoc, "com.sun.star.frame.XModel") Then
            ' Sprawdzamy tytuł okna. 
            ' UWAGA: Tytuł może brzmieć "frmGlowny" lub "TwojaBaza.odb : frmGlowny"
            ' Dlatego używamy InStr, żeby sprawdzić czy nazwa zawiera "frmGlowny"
            sTitle = oDoc.Title
            
            If InStr(sTitle, "frmPodgladAktywnosci") > 0 Then
                ' Znaleźliśmy formularz główny! Teraz dobieramy się do jego wnętrza.
                
                On Error Resume Next ' Zabezpieczenie na wypadek błędów struktury
                oDrawPage = oDoc.getDrawPage()
                oForms = oDrawPage.getForms()
                
                If oForms.hasByName("MainForm") Then
                    oMainForm = oForms.getByName("MainForm")
                    
                    ' Odświeżamy listę aktywności (żeby zobaczyć nowy wpis)
                    If oMainForm.hasByName("SubForm_Aktywnosci") Then
                        oMainForm.getByName("SubForm_Aktywnosci").reload()
                    End If
                    
                    ' Odświeżamy podsumowanie (żeby przeliczyły się punkty)
                    If oMainForm.hasByName("SubForm_Podsumowanie") Then
                        oMainForm.getByName("SubForm_Podsumowanie").reload()
                    End If
                    
                    ' Opcjonalnie: odświeżamy też szczegóły (gdyby coś się zmieniło w nagłówku)
                     If oMainForm.hasByName("SubForm_DaneGlowne") Then
                        oMainForm.getByName("SubForm_DaneGlowne").reload()
                    End If
                End If
                On Error GoTo 0
                
                ' Możemy wyjść z pętli, bo znaleźliśmy co chcieliśmy
                Exit Sub
            End If
        End If
    Wend
End Sub

' Procedura pod przycisk "Zapisz"
Sub ZapiszIZamknij(oEvent As Object)
    Dim oForm As Object
    oForm = oEvent.Source.Model.Parent
    
    ' Prosta walidacja (opcjonalna)
    ' Można tu sprawdzić czy punkty mieszczą się w min/max
    
    If oForm.isNew Then
        oForm.insertRow()
    Else
        oForm.updateRow()
    End If
    
    OdswiezFormularzGlowny()
    
    ' Zamknij okno
    ThisComponent.CurrentController.Frame.close(True)
    
    ' UWAGA: Odświeżenie rodzica (frmGlowny) jest trudne z poziomu Basic, 
    ' jeśli okna są niezależne. Użytkownik zazwyczaj musi kliknąć "Odśwież" na głównym.
End Sub

' Procedura pod przycisk "Anuluj"
Sub AnulujZmiany(oEvent As Object)
    ThisComponent.CurrentController.Frame.close(True)
End Sub
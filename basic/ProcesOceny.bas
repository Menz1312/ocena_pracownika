Option Explicit


' =====================================================================
' Zmienne globalne kontrolujące zachowanie formularza
' =====================================================================

Global bZezwolNaZapis As Boolean
Global bTrybWymuszonejEdycji As Boolean

Sub UstawStanInterfejsu(oForm As Object, bOdblokuj As Boolean)
    Dim i As Integer
    Dim oElement As Object
    
    ' Iterujemy po wszystkich kontrolkach w podformularzu
    For i = 0 To oForm.Count - 1
        oElement = oForm.getByIndex(i)
        
        ' Szukamy tylko pól tekstowych i list rozwijanych
        If oElement.supportsService("com.sun.star.form.component.ListBox") Or _
           oElement.supportsService("com.sun.star.form.component.TextField") Then
            
            ' Twarda zmiana stanu wizualnego (True = aktywne, False = wyszarzone)
            oElement.Enabled = bOdblokuj
            
        End If
    Next i
End Sub

' =====================================================================
' MAKRO Kierownik_PoZmianieRekordu: Blokuje formularz przy każdym załadowaniu rekordu
' =====================================================================
Sub Kierownik_PoZmianieRekordu(oEvent As Object)
    Dim oForm As Object
    oForm = oEvent.Source
    
    ' Zabezpieczenie: upewniamy się, że to na pewno formularz bazy danych
    If oForm.ImplementationName = "com.sun.star.comp.forms.ODatabaseForm" Then
        
        If bTrybWymuszonejEdycji = False Then
            oForm.AllowUpdates = False
            UstawStanInterfejsu(oForm, False) '<-- TWARDE WYSZARZENIE KONTROLEK
        Else
            oForm.AllowUpdates = True
            UstawStanInterfejsu(oForm, True)  '<-- TWARDE ODBLOKOWANIE KONTROLEK
        End If
        
        bZezwolNaZapis = False
    End If
End Sub

' =====================================================================
' MAKRO Komisja_PoZmianieRekordu: Blokada dla formularza Komisji (Podepnij pod: Po zmianie rekordu)
' =====================================================================
Sub Komisja_PoZmianieRekordu(oEvent As Object)
    Dim oForm As Object
    oForm = oEvent.Source
    
    If oForm.ImplementationName = "com.sun.star.comp.forms.ODatabaseForm" Then
        If bTrybWymuszonejEdycji = False Then
            oForm.AllowUpdates = False
            UstawStanInterfejsu(oForm, False) ' Wyszarza kontrolki
        Else
            oForm.AllowUpdates = True
            UstawStanInterfejsu(oForm, True)  ' Odblokowuje kontrolki
        End If
        bZezwolNaZapis = False
    End If
End Sub

' =====================================================================
' MAKRO Formularz_PrzedAktualizacja: Cicha tarcza blokująca auto-zapis
' =====================================================================
Function Formularz_PrzedAktualizacja(oEvent As Object) As Boolean
    If bZezwolNaZapis = True Then
        Formularz_PrzedAktualizacja = True ' Zapis z przycisku Zatwierdź -> Puszczamy
    Else
        Formularz_PrzedAktualizacja = False ' Auto-zapis z systemu -> Blokujemy!
    End If
End Function

' =====================================================================
' MAKRO OdblokujEdycje: Przycisk EDYTUJ
' =====================================================================
Sub OdblokujEdycje(oEvent As Object)
    Dim oForm As Object
    oForm = oEvent.Source.Model.Parent
    
    ' Ustawiamy flagę na STAŁE (aż do momentu zapisu lub odrzucenia)
    bTrybWymuszonejEdycji = True 
    
    oForm.AllowUpdates = True
    oForm.reload() 
    
    MsgBox "Tryb edycji włączony. Możesz wprowadzić zmiany.", 64, "Edycja odblokowana"
End Sub

' =====================================================================
' MAKRO ZatwierdzOceneKierownika: Przycisk ZATWIERDŹ (Z zamrażaniem wyliczonych punktów)
' =====================================================================
Sub ZatwierdzOceneKierownika(oEvent As Object)
    Dim oForm As Object
    Dim oConn As Object
    Dim oStmt As Object
    Dim sSQL As String
    Dim iPracID As Integer
    Dim iOkresID As Integer
    Dim sKierZatwierdzil As String
    
    oForm = oEvent.Source.Model.Parent
    
    ' 1. Sprawdzamy, czy w bazie jest już podpis kierownika
    sKierZatwierdzil = oForm.getString(oForm.findColumn("kier_zatwierdzil_user"))
    
    If sKierZatwierdzil <> "" And bTrybWymuszonejEdycji = False Then
        MsgBox "Formularz jest zablokowany. Kliknij 'Edytuj', aby wprowadzić zmiany.", 48, "Informacja"
        Exit Sub
    End If
    
    bZezwolNaZapis = True
    oForm.AllowUpdates = True 
    
    ' 2. Zapisujemy ręcznie wprowadzone dane (oceny, uzasadnienia)
    If oForm.isModified Then
        On Error GoTo BladWalidacji
        oForm.updateRow()
        On Error GoTo 0 
    End If
    
    bZezwolNaZapis = False
    
    iPracID = oForm.getInt(oForm.findColumn("id_pracownika"))
    iOkresID = oForm.getInt(oForm.findColumn("id_okresu"))
    
    oConn = oForm.ActiveConnection
    oStmt = oConn.createStatement()
    
    ' Zapytanie SQL, które najpierw liczy punkty (WITH), 
    ' a potem od razu aktualizuje rekord oceny, dokonując ostatecznego "zamrożenia"
    sSQL = "WITH punkty AS ( " & _
           "  SELECT " & _
           "    COALESCE(SUM(CASE WHEN gd.kod_grupy = 'PUB' THEN ap.przyznane_punkty ELSE 0 END), 0) AS pkt_pub, " & _
           "    COALESCE(SUM(CASE WHEN gd.kod_grupy = 'DYD' THEN ap.przyznane_punkty ELSE 0 END), 0) AS pkt_dyd, " & _
           "    COALESCE(SUM(CASE WHEN gd.kod_grupy = 'ORG' THEN ap.przyznane_punkty ELSE 0 END), 0) AS pkt_org, " & _
           "    COALESCE(SUM(CASE WHEN gd.kod_grupy = 'BR'  THEN ap.przyznane_punkty ELSE 0 END), 0) AS pkt_br, " & _
           "    COALESCE(SUM(ap.przyznane_punkty), 0) AS pkt_total " & _
           "  FROM pcz_oceny.aktywnosci_pracownika ap " & _
           "  JOIN pcz_oceny.okresy_oceny oo ON oo.id_okresu = " & iOkresID & " " & _
           "  JOIN pcz_oceny.typy_aktywnosci ta ON ap.id_typu_aktywnosci = ta.id_typu " & _
           "  JOIN pcz_oceny.grupy_dzialan gd ON ta.id_grupy = gd.id_grupy " & _
           "  WHERE ap.id_pracownika = " & iPracID & " AND ap.data_rozpoczecia BETWEEN oo.data_od AND oo.data_do " & _
           ") " & _
           "UPDATE pcz_oceny.oceny_okresowe " & _
           "SET kier_zatwierdzil_user = CURRENT_USER, " & _
           "    kier_zatwierdzil_data = CURRENT_TIMESTAMP, " & _
           "    suma_pkt_pub = p.pkt_pub, " & _
           "    suma_pkt_dyd = p.pkt_dyd, " & _
           "    suma_pkt_org = p.pkt_org, " & _
           "    suma_pkt_br  = p.pkt_br, " & _
           "    suma_pkt_total = p.pkt_total " & _
           "FROM punkty p " & _
           "WHERE id_pracownika = " & iPracID & " AND id_okresu = " & iOkresID
           
    oStmt.executeUpdate(sSQL)
    
    ' 4. Zdejmujemy flagę i zamykamy kłódkę
    bTrybWymuszonejEdycji = False 
    oForm.AllowUpdates = False
    oForm.reload()
    
    MsgBox "Ocena została zatwierdzona. Liczba punktów została poprawnie zamrożona na potrzeby Komisji.", 64, "Sukces"
    
    Exit Sub 

BladWalidacji:
    bZezwolNaZapis = False 
    MsgBox "Nie można zatwierdzić oceny. Upewnij się, że wypełniłeś WSZYSTKIE wymagane pola (oceny i uzasadnienia).", 48, "Brakujące dane"
End Sub

' =====================================================================
' MAKRO ZatwierdzOceneKomisji: Zapis dla Komisji (Podepnij pod przycisk: Zatwierdź)
' =====================================================================
Sub ZatwierdzOceneKomisji(oEvent As Object)
    Dim oForm As Object
    Dim oConn As Object
    Dim oStmt As Object
    Dim sSQL As String
    Dim iPracID As Integer
    Dim iOkresID As Integer
    Dim sKomZatwierdzil As String
    
    oForm = oEvent.Source.Model.Parent
    
    ' =================================================================
    ' TARCZA ANTY-FOKUSOWA: Wymuszamy zrzut danych z ekranu do pamięci
    ' =================================================================
    On Error Resume Next
    Dim oCtrl As Object
    oCtrl = ThisComponent.CurrentController.getControl(oEvent.Source.Model)
    oCtrl.setFocus()
    On Error GoTo 0
    
    ' Sprawdzamy, czy w bazie jest już podpis KOMISJI
    sKomZatwierdzil = oForm.getString(oForm.findColumn("kom_zatwierdzil_user"))
    
    If sKomZatwierdzil <> "" And bTrybWymuszonejEdycji = False Then
        MsgBox "Formularz jest zablokowany. Kliknij 'Edytuj', aby wprowadzić zmiany.", 48, "Informacja"
        Exit Sub
    End If
    
    bZezwolNaZapis = True
    oForm.AllowUpdates = True 
    
    If oForm.isModified Then
        On Error GoTo BladWalidacji
        oForm.updateRow()
        On Error GoTo 0 
    End If
    
    bZezwolNaZapis = False
    
    iPracID = oForm.getInt(oForm.findColumn("id_pracownika"))
    iOkresID = oForm.getInt(oForm.findColumn("id_okresu"))
    
    oConn = oForm.ActiveConnection
    oStmt = oConn.createStatement()
    
    ' Aktualizujemy wyłącznie podpis Komisji (punkty zostały już zamrożone przez kierownika)
    sSQL = "UPDATE pcz_oceny.oceny_okresowe " & _
           "SET kom_zatwierdzil_user = CURRENT_USER, " & _
           "    kom_zatwierdzil_data = CURRENT_TIMESTAMP " & _
           "WHERE id_pracownika = " & iPracID & " AND id_okresu = " & iOkresID
           
    oStmt.executeUpdate(sSQL)
    
    ' Zdejmujemy flagę i zamykamy kłódkę
    bTrybWymuszonejEdycji = False 
    oForm.AllowUpdates = False
    oForm.reload()
    
    MsgBox "Ocena Komisji została zatwierdzona.", 64, "Sukces"
    Exit Sub 

BladWalidacji:
    bZezwolNaZapis = False 
    MsgBox "Nie można zatwierdzić. Upewnij się, że wypełniłeś wymaganą Ocenę oraz Uzasadnienie.", 48, "Brakujące dane"
End Sub

' =====================================================================
' MAKRO Ocena_SprawdzPrzedFokusem: STRAŻNIK (Podpinane pod: Gdy fokus zostanie uzyskany)
' Działa dla obu ListBoxów (Pracownika i Okresu)
' =====================================================================
Sub Ocena_SprawdzPrzedFokusem(oEvent As Object)
    Dim oListBoxCtrl As Object
    Dim oForm As Object
    Dim oSubDecyzje As Object
    Dim iOdpowiedz As Integer
    
    ' W zdarzeniach fokusu oEvent.Source to kontroler widoku (View), a nie model
    oListBoxCtrl = oEvent.Source
    oForm = oListBoxCtrl.Model.Parent
    
    If oForm.hasByName("SubForm_Decyzje") Then
        oSubDecyzje = oForm.getByName("SubForm_Decyzje")
        
        ' Jeśli są niezapisane zmiany
        If oSubDecyzje.isModified Then
            iOdpowiedz = MsgBox("Masz niezapisane zmiany w ocenie. Czy chcesz je odrzucić, aby zmienić wybór?", 36, "Niezapisane zmiany")
            
            If iOdpowiedz = 6 Then 
                ' TAK - Odrzucamy. Lista może się normalnie otworzyć.
                oSubDecyzje.cancelRowUpdates()
                bTrybWymuszonejEdycji = False
                oSubDecyzje.AllowUpdates = False
                oForm.reload()
            Else 
                ' NIE - Użytkownik chce zapisać!
                ' Brutalnie odbieramy fokus z listy rozwijanej, żeby się nie otworzyła,
                ' i przenosimy go na przycisk "Zatwierdź" w podformularzu.
                On Error Resume Next
                Dim oZatwierdzBtnModel As Object
                oZatwierdzBtnModel = oSubDecyzje.getByName("btnZatwierdz")
                ThisComponent.CurrentController.getControl(oZatwierdzBtnModel).setFocus()
                On Error GoTo 0
            End If
        End If
    End If
End Sub

' =====================================================================
' MAKRO Ocena_ZmienFiltrPracownika: Zmiana Pracownika
' =====================================================================
Sub Ocena_ZmienFiltrPracownika(oEvent As Object)
    Dim oListBox As Object, oForm As Object, oStatement As Object, oRes As Object
    Dim sSQL As String
    Dim iWybraneID As Integer, iOkresID As Integer
    Dim bCzyOceniony As Boolean
    
    oListBox = oEvent.Source.Model
    If IsEmpty(oListBox.SelectedValue) Then Exit Sub
    oForm = oListBox.Parent
    iWybraneID = CInt(oListBox.SelectedValue)
    oStatement = oForm.ActiveConnection.createStatement()
    
    ' 1. Zmień filtr 
    sSQL = "INSERT INTO pcz_oceny.filtr_uzytkownika (nazwa_uzytkownika, id_pracownika) VALUES (current_user, " & iWybraneID & ") ON CONFLICT (nazwa_uzytkownika) DO UPDATE SET id_pracownika = EXCLUDED.id_pracownika;"
    oStatement.executeUpdate(sSQL)
    
    ' 2. Utwórz szkielet oceny i sprawdź, czy była już wpisana
    bCzyOceniony = False ' Domyślnie zakładamy, że brak oceny
    
    sSQL = "SELECT id_okresu FROM pcz_oceny.filtr_uzytkownika WHERE nazwa_uzytkownika = current_user"
    oRes = oStatement.executeQuery(sSQL)
    If oRes.next() Then
        iOkresID = oRes.getInt(1)
        sSQL = "INSERT INTO pcz_oceny.oceny_okresowe (id_pracownika, id_okresu) SELECT " & iWybraneID & ", " & iOkresID & " WHERE NOT EXISTS (SELECT 1 FROM pcz_oceny.oceny_okresowe WHERE id_pracownika = " & iWybraneID & " AND id_okresu = " & iOkresID & ")"
        oStatement.executeUpdate(sSQL)
        
        ' === SPRAWDZENIE OCENY PRZED PRZEŁADOWANIEM ===
        sSQL = "SELECT kier_zatwierdzil_user FROM pcz_oceny.oceny_okresowe WHERE id_pracownika = " & iWybraneID & " AND id_okresu = " & iOkresID
        Dim oResOcena As Object
        oResOcena = oStatement.executeQuery(sSQL)
        If oResOcena.next() Then
            If Not oResOcena.wasNull() Then
                If oResOcena.getString(1) <> "" Then
                    bCzyOceniony = True ' Podpis istnieje
                End If
            End If
        End If
    End If
    
    ' === USTAWIENIE FLAGI I ODŚWIEŻENIE ===
    If bCzyOceniony = False Then
        bTrybWymuszonejEdycji = True  ' Odblokowujemy formularz
    Else
        bTrybWymuszonejEdycji = False ' Blokujemy formularz
    End If
    
    oForm.reload()
End Sub

' =====================================================================
' MAKRO Ocena_ZmienFiltrOkresu: Zmiana Okresu
' =====================================================================
Sub Ocena_ZmienFiltrOkresu(oEvent As Object)
    Dim oListBox As Object, oForm As Object, oStatement As Object, oRes As Object
    Dim sSQL As String
    Dim iWybraneID As Integer, iPracID As Integer
    Dim bCzyOceniony As Boolean
    
    oListBox = oEvent.Source.Model
    If IsEmpty(oListBox.SelectedValue) Then Exit Sub
    oForm = oListBox.Parent
    iWybraneID = CInt(oListBox.SelectedValue)
    oStatement = oForm.ActiveConnection.createStatement()
    
    ' 1. Zmień filtr
    sSQL = "INSERT INTO pcz_oceny.filtr_uzytkownika (nazwa_uzytkownika, id_okresu) VALUES (current_user, " & iWybraneID & ") ON CONFLICT (nazwa_uzytkownika) DO UPDATE SET id_okresu = EXCLUDED.id_okresu;"
    oStatement.executeUpdate(sSQL)
    
    ' 2. Utwórz szkielet oceny i sprawdź
    bCzyOceniony = False 
    
    sSQL = "SELECT id_pracownika FROM pcz_oceny.filtr_uzytkownika WHERE nazwa_uzytkownika = current_user"
    oRes = oStatement.executeQuery(sSQL)
    If oRes.next() Then
        iPracID = oRes.getInt(1)
        sSQL = "INSERT INTO pcz_oceny.oceny_okresowe (id_pracownika, id_okresu) SELECT " & iPracID & ", " & iWybraneID & " WHERE NOT EXISTS (SELECT 1 FROM pcz_oceny.oceny_okresowe WHERE id_pracownika = " & iPracID & " AND id_okresu = " & iWybraneID & ")"
        oStatement.executeUpdate(sSQL)
        
        ' === SPRAWDZENIE OCENY PRZED PRZEŁADOWANIEM ===
        sSQL = "SELECT kier_zatwierdzil_user FROM pcz_oceny.oceny_okresowe WHERE id_pracownika = " & iPracID & " AND id_okresu = " & iWybraneID
        Dim oResOcena As Object
        oResOcena = oStatement.executeQuery(sSQL)
        If oResOcena.next() Then
            If Not oResOcena.wasNull() Then
                If oResOcena.getString(1) <> "" Then
                    bCzyOceniony = True ' Podpis istnieje
                End If
            End If
        End If
    End If
    
    ' === USTAWIENIE FLAGI I ODŚWIEŻENIE ===
    If bCzyOceniony = False Then
        bTrybWymuszonejEdycji = True  ' Odblokowujemy
    Else
        bTrybWymuszonejEdycji = False ' Blokujemy
    End If
    
    oForm.reload()
End Sub

' =====================================================================
' MAKRO Odwolawcza_ZmienFiltrPracownika: Zmiana Pracownika (BEZ LAGÓW)
' =====================================================================
Sub Odwolawcza_ZmienFiltrPracownika(oEvent As Object)
    Dim oListBox As Object, oForm As Object, oSubForm As Object
    Dim oStatement As Object, oRes As Object, oResOcena As Object
    Dim sSQL As String
    Dim iWybraneID As Integer, iOkresID As Integer
    Dim bCzyOceniony As Boolean
    
    oListBox = oEvent.Source.Model
    If IsEmpty(oListBox.SelectedValue) Then Exit Sub
    oForm = oListBox.Parent
    iWybraneID = CInt(oListBox.SelectedValue)
    oStatement = oForm.ActiveConnection.createStatement()
    
    ' 1. Zmień filtr 
    sSQL = "INSERT INTO pcz_oceny.filtr_uzytkownika (nazwa_uzytkownika, id_pracownika) VALUES (current_user, " & iWybraneID & ") ON CONFLICT (nazwa_uzytkownika) DO UPDATE SET id_pracownika = EXCLUDED.id_pracownika;"
    oStatement.executeUpdate(sSQL)
    
    ' 2. Utwórz szkielet i sprawdź podpis
    bCzyOceniony = False 
    
    sSQL = "SELECT id_okresu FROM pcz_oceny.filtr_uzytkownika WHERE nazwa_uzytkownika = current_user"
    oRes = oStatement.executeQuery(sSQL)
    If oRes.next() Then
        iOkresID = oRes.getInt(1)
        sSQL = "INSERT INTO pcz_oceny.oceny_okresowe (id_pracownika, id_okresu) SELECT " & iWybraneID & ", " & iOkresID & " WHERE NOT EXISTS (SELECT 1 FROM pcz_oceny.oceny_okresowe WHERE id_pracownika = " & iWybraneID & " AND id_okresu = " & iOkresID & ")"
        oStatement.executeUpdate(sSQL)
        
        sSQL = "SELECT odw_zatwierdzil_user FROM pcz_oceny.oceny_okresowe WHERE id_pracownika = " & iWybraneID & " AND id_okresu = " & iOkresID
        oResOcena = oStatement.executeQuery(sSQL)
        If oResOcena.next() Then
            If Not oResOcena.wasNull() Then
                If oResOcena.getString(1) <> "" Then
                    bCzyOceniony = True 
                End If
            End If
        End If
    End If
    
    ' 3. Ustaw flagę
    If bCzyOceniony = False Then
        bTrybWymuszonejEdycji = True  
    Else
        bTrybWymuszonejEdycji = False 
    End If
    
    ' 4. KLUCZOWA POPRAWKA: Ręczne sterowanie SubFormem (eliminuje opóźnienie)
    oForm.reload() ' Przeładowanie głównego (Link Master/Slave)
    
    If oForm.hasByName("SubForm_Decyzje") Then
        oSubForm = oForm.getByName("SubForm_Decyzje")
        oSubForm.reload() ' Wymuszenie pobrania danych
        
        ' Twarde ustawienie interfejsu TU I TERAZ
        If bTrybWymuszonejEdycji = True Then
            oSubForm.AllowUpdates = True
            UstawStanInterfejsu(oSubForm, True)
        Else
            oSubForm.AllowUpdates = False
            UstawStanInterfejsu(oSubForm, False)
        End If
    End If
End Sub

' =====================================================================
' MAKRO Odwolawcza_ZmienFiltrOkresu: Zmiana Okresu (BEZ LAGÓW)
' =====================================================================
Sub Odwolawcza_ZmienFiltrOkresu(oEvent As Object)
    Dim oListBox As Object, oForm As Object, oSubForm As Object
    Dim oStatement As Object, oRes As Object, oResOcena As Object
    Dim sSQL As String
    Dim iWybraneID As Integer, iPracID As Integer
    Dim bCzyOceniony As Boolean
    
    oListBox = oEvent.Source.Model
    If IsEmpty(oListBox.SelectedValue) Then Exit Sub
    oForm = oListBox.Parent
    iWybraneID = CInt(oListBox.SelectedValue)
    oStatement = oForm.ActiveConnection.createStatement()
    
    ' 1. Zmień filtr
    sSQL = "INSERT INTO pcz_oceny.filtr_uzytkownika (nazwa_uzytkownika, id_okresu) VALUES (current_user, " & iWybraneID & ") ON CONFLICT (nazwa_uzytkownika) DO UPDATE SET id_okresu = EXCLUDED.id_okresu;"
    oStatement.executeUpdate(sSQL)
    
    ' 2. Utwórz szkielet i sprawdź podpis
    bCzyOceniony = False 
    
    sSQL = "SELECT id_pracownika FROM pcz_oceny.filtr_uzytkownika WHERE nazwa_uzytkownika = current_user"
    oRes = oStatement.executeQuery(sSQL)
    If oRes.next() Then
        iPracID = oRes.getInt(1)
        sSQL = "INSERT INTO pcz_oceny.oceny_okresowe (id_pracownika, id_okresu) SELECT " & iPracID & ", " & iWybraneID & " WHERE NOT EXISTS (SELECT 1 FROM pcz_oceny.oceny_okresowe WHERE id_pracownika = " & iPracID & " AND id_okresu = " & iWybraneID & ")"
        oStatement.executeUpdate(sSQL)
        
        sSQL = "SELECT odw_zatwierdzil_user FROM pcz_oceny.oceny_okresowe WHERE id_pracownika = " & iPracID & " AND id_okresu = " & iWybraneID
        oResOcena = oStatement.executeQuery(sSQL)
        If oResOcena.next() Then
            If Not oResOcena.wasNull() Then
                If oResOcena.getString(1) <> "" Then
                    bCzyOceniony = True 
                End If
            End If
        End If
    End If
    
    ' 3. Ustaw flagę
    If bCzyOceniony = False Then
        bTrybWymuszonejEdycji = True  
    Else
        bTrybWymuszonejEdycji = False 
    End If
    
    ' 4. KLUCZOWA POPRAWKA
    oForm.reload()
    
    If oForm.hasByName("SubForm_Decyzje") Then
        oSubForm = oForm.getByName("SubForm_Decyzje")
        oSubForm.reload()
        
        If bTrybWymuszonejEdycji = True Then
            oSubForm.AllowUpdates = True
            UstawStanInterfejsu(oSubForm, True)
        Else
            oSubForm.AllowUpdates = False
            UstawStanInterfejsu(oSubForm, False)
        End If
    End If
End Sub
    
    ' === USTAWIENIE FLAGI I ODŚWIEŻENIE ===
    If bCzyOceniony = False Then
        bTrybWymuszonejEdycji = True  ' Odblokowujemy
    Else
        bTrybWymuszonejEdycji = False ' Blokujemy
    End If
    
    oForm.reload()
End Sub

' =====================================================================
' MAKRO: Blokada/Odblokowanie interfejsu (Podepnij pod SubForm_Decyzje)
' =====================================================================
Sub Odwolawcza_PoZmianieRekordu(oEvent As Object)
    Dim oForm As Object
    oForm = oEvent.Source
    
    ' Upewniamy się, że to formularz bazy danych
    If oForm.ImplementationName = "com.sun.star.comp.forms.ODatabaseForm" Then
        
        ' Sprawdzamy flagę ustawioną wcześniej przez makra filtrujące
        If bTrybWymuszonejEdycji = False Then
            ' 1. Blokujemy zapis danych
            oForm.AllowUpdates = False
            ' 2. Blokujemy wizualnie kontrolki (szare tło)
            UstawStanInterfejsu(oForm, False) 
        Else
            ' 1. Odblokowujemy zapis
            oForm.AllowUpdates = True
            ' 2. Odblokowujemy wizualnie kontrolki
            UstawStanInterfejsu(oForm, True)
        End If
        
        ' Resetujemy flagę zapisu (standardowa procedura bezpieczeństwa)
        bZezwolNaZapis = False
    End If
End Sub

' =====================================================================
' MAKRO ZatwierdzOceneOdwolawcza: Zapis dla Komisji Odwoławczej
' =====================================================================
Sub ZatwierdzOceneOdwolawcza(oEvent As Object)
    Dim oForm As Object
    Dim oConn As Object
    Dim oStmt As Object
    Dim sSQL As String
    Dim iPracID As Integer
    Dim iOkresID As Integer
    Dim sOdwZatwierdzil As String ' <--- POPRAWKA 1: Prawidłowa nazwa zmiennej
    
    oForm = oEvent.Source.Model.Parent
    
    ' =================================================================
    ' TARCZA ANTY-FOKUSOWA: Wymuszamy zrzut danych z ekranu do pamięci
    ' =================================================================
    On Error Resume Next
    Dim oCtrl As Object
    oCtrl = ThisComponent.CurrentController.getControl(oEvent.Source.Model)
    oCtrl.setFocus()
    On Error GoTo 0
    
    ' Sprawdzamy, czy w bazie jest już podpis KOMISJI ODWOŁAWCZEJ
    sOdwZatwierdzil = oForm.getString(oForm.findColumn("odw_zatwierdzil_user"))
    
    If sOdwZatwierdzil <> "" And bTrybWymuszonejEdycji = False Then
        MsgBox "Formularz jest zablokowany. Kliknij 'Edytuj', aby wprowadzić zmiany.", 48, "Informacja"
        Exit Sub
    End If
    
    bZezwolNaZapis = True
    oForm.AllowUpdates = True 
    
    ' POPRAWKA 2: Pancerne wymuszenie zapisu (tak jak w poprzednim formularzu)
    If oForm.isModified Then
        On Error GoTo BladWalidacji
        oForm.updateRow()
        On Error GoTo 0 
    Else
        ' Jeśli Base nie wykrył zmian mimo zmiany fokusu, wymuszamy zapis!
        On Error GoTo BladWalidacji
        oForm.updateRow()
        On Error GoTo 0 
    End If
    
    bZezwolNaZapis = False
    
    iPracID = oForm.getInt(oForm.findColumn("id_pracownika"))
    iOkresID = oForm.getInt(oForm.findColumn("id_okresu"))
    
    oConn = oForm.ActiveConnection
    oStmt = oConn.createStatement()
    
    ' Aktualizujemy wyłącznie podpis Komisji Odwoławczej
    sSQL = "UPDATE pcz_oceny.oceny_okresowe " & _
           "SET odw_zatwierdzil_user = CURRENT_USER, " & _
           "    odw_zatwierdzil_data = CURRENT_TIMESTAMP " & _
           "WHERE id_pracownika = " & iPracID & " AND id_okresu = " & iOkresID
           
    oStmt.executeUpdate(sSQL)
    
    ' Zdejmujemy flagę i zamykamy kłódkę
    bTrybWymuszonejEdycji = False 
    oForm.AllowUpdates = False
    oForm.reload()
    
    MsgBox "Decyzja Odwoławcza została zatwierdzona.", 64, "Sukces"
    Exit Sub 

BladWalidacji:
    bZezwolNaZapis = False 
    MsgBox "Nie można zatwierdzić. Upewnij się, że wybrałeś Decyzję i wpisałeś Uzasadnienie.", 48, "Brakujące dane"
End Sub
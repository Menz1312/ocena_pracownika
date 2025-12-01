REM  ***** GENERATOR RAPORTU  *****

Sub GenerujArkuszOceny
    Dim oStatement As Object
    Dim oResultSet As Object
    Dim sSQL As String
    Dim sSciezkaSzablonu As String
    Dim oDoc As Object
    Dim sUrl As String
    Dim sStanowisko As String
    
    ' --- 1. KONFIGURACJA ---
    ' UWAGA: Zmień tę ścieżkę na lokalizację swojego pliku .ott!
    ' W Windows używamy podwójnych ukośników lub url: file:///C:/...
    sSciezkaSzablonu = "D:\Studia\Praca inżynierska\Szablon_Zal1_Ocena.ott" 
    sUrl = ConvertToURL(sSciezkaSzablonu)
    
    If Dir(sSciezkaSzablonu) = "" Then
        MsgBox "Nie znaleziono pliku szablonu: " & sSciezkaSzablonu, 16, "Błąd"
        Exit Sub
    End If

    ' --- 2. OTWARCIE NOWEGO DOKUMENTU Z SZABLONU ---
    Dim args(0) As New com.sun.star.beans.PropertyValue
    args(0).Name = "AsTemplate"
    args(0).Value = True
    
    oDoc = StarDesktop.loadComponentFromURL(sUrl, "_blank", 0, args())
    
    ' Pobierz połączenie z bazy
    Dim oConn As Object
    oConn = ThisDatabaseDocument.CurrentController.ActiveConnection
    oStatement = oConn.createStatement()
    
    ' --- 3. DANE NAGŁÓWKOWE (Pracownik) ---
    ' Pobieramy dane wybranego pracownika korzystając z filtra globalnego
    sSQL = "SELECT p.imie_nazwisko, p.nazwa_stanowiska " & _
           "FROM oceny_pracownikow.v_dane_pracownikow p " & _
           "JOIN oceny_pracownikow.filtr_globalny f ON p.id_pracownika = f.id_wybranego_pracownika"
           
    oResultSet = oStatement.executeQuery(sSQL)
    
    If oResultSet.next() Then
        WstawDoZakladki(oDoc, "bmkImieNazwisko", oResultSet.getString(1))
        sStanowisko = oResultSet.getString(2)
        
        ' Obsługa przekreślania (zostawiamy tylko właściwe stanowisko)
        ' Nazwy stanowisk muszą pasować do tych w bazie (tabela typy_stanowisk)
        
        If sStanowisko = "badawczo-dydaktyczny" Then
            PrzekreslZakladke(oDoc, "bmkOpcjaDyd")
            PrzekreslZakladke(oDoc, "bmkOpcjaBad")
            ' bmkOpcjaBadDyd zostaje czyste
        ElseIf sStanowisko = "badawczy" Then
            PrzekreslZakladke(oDoc, "bmkOpcjaDyd")
            PrzekreslZakladke(oDoc, "bmkOpcjaBadDyd")
            ' bmkOpcjaBad zostaje czyste
        ElseIf sStanowisko = "dydaktyczny" Then
            PrzekreslZakladke(oDoc, "bmkOpcjaBad")
            PrzekreslZakladke(oDoc, "bmkOpcjaBadDyd")
            ' bmkOpcjaDyd zostaje czyste
        End If
    End If
    
    ' --- 4. TABELA AKTYWNOŚCI (Pętla po Lp) ---
    sSQL = "SELECT numer_lp, suma_punktow FROM oceny_pracownikow.v_raport_1_agregacja"
    oResultSet = oStatement.executeQuery(sSQL)
    
    Dim iLp As Integer
    Dim dPkt As Double
    Dim sBmkName As String
    
    While oResultSet.next()
        iLp = oResultSet.getInt(1)
        dPkt = oResultSet.getDouble(2)
        
        ' Konstruujemy nazwę zakładki, np. bmkLp14
        sBmkName = "bmkLp" & iLp
        
        ' Wstawiamy punkty
        WstawDoZakladki(oDoc, sBmkName, Format(dPkt, "0.00"))
    Wend
    
    ' --- 5. SUMY KOŃCOWE (Stopka) ---
    ' Korzystamy z widoku Dashboardu, który ma już gotowe sumy
    sSQL = "SELECT kod_grupy, suma_punktow FROM oceny_pracownikow.v_dashboard_podsumowanie_live"
    oResultSet = oStatement.executeQuery(sSQL)
    
    Dim sKod As String
    Dim dTotal As Double
    dTotal = 0
    
    While oResultSet.next()
        sKod = oResultSet.getString(1)
        dPkt = oResultSet.getDouble(2)
        dTotal = dTotal + dPkt
        
        If sKod = "PUB" Then WstawDoZakladki(oDoc, "bmkSumaPub", Format(dPkt, "0.00"))
        If sKod = "BR" Then  WstawDoZakladki(oDoc, "bmkSumaBR", Format(dPkt, "0.00"))
        If sKod = "DYD" Then WstawDoZakladki(oDoc, "bmkSumaDyd", Format(dPkt, "0.00"))
        If sKod = "ORG" Then WstawDoZakladki(oDoc, "bmkSumaOrg", Format(dPkt, "0.00"))
    Wend
    
    ' Suma całkowita
    WstawDoZakladki(oDoc, "bmkSumaTotal", Format(dTotal, "0.00"))
    
    MsgBox "Arkusz oceny został wygenerowany.", 64, "Gotowe"
End Sub

' ---------------------------------------------------------
' FUNKCJE POMOCNICZE
' ---------------------------------------------------------

Sub WstawDoZakladki(oDoc As Object, sNazwaZakladki As String, sTekst As String)
    Dim oBookmarks As Object
    Dim oAnchor As Object
    
    oBookmarks = oDoc.Bookmarks
    
    If oBookmarks.hasByName(sNazwaZakladki) Then
        oAnchor = oBookmarks.getByName(sNazwaZakladki).Anchor
        oAnchor.String = sTekst
    End If
End Sub

Sub PrzekreslZakladke(oDoc As Object, sNazwaZakladki As String)
    Dim oBookmarks As Object
    Dim oAnchor As Object
    
    oBookmarks = oDoc.Bookmarks
    
    If oBookmarks.hasByName(sNazwaZakladki) Then
        oAnchor = oBookmarks.getByName(sNazwaZakladki).Anchor
        ' Ustawienie przekreślenia (Strikeout)
        ' 1 = pojedyncze, 0 = brak
        oAnchor.CharStrikeout = 1 
    End If
End Sub

Sub GenerujOceneOkresowa
    Dim oStatement As Object
    Dim oResultSet As Object
    Dim sSQL As String
    Dim sSciezkaSzablonu As String
    Dim oDoc As Object
    Dim sUrl As String
    
    ' Zmienne na dane
    Dim sStanowisko As String
    Dim dDataOd As Date, dDataDo As Date
    Dim sOkres As String
    Dim sMiejscePracy As String
    
    ' --- 1. KONFIGURACJA ---
    sSciezkaSzablonu = "D:\Studia\Praca inżynierska\Szablon_Zal2_Ocena.ott"
    
    If Dir(sSciezkaSzablonu) = "" Then
        MsgBox "Nie znaleziono pliku szablonu: " & sSciezkaSzablonu, 16, "Błąd"
        Exit Sub
    End If
    sUrl = ConvertToURL(sSciezkaSzablonu)

    ' --- 2. OTWARCIE DOKUMENTU ---
    Dim args(0) As New com.sun.star.beans.PropertyValue
    args(0).Name = "AsTemplate"
    args(0).Value = True
    
    oDoc = StarDesktop.loadComponentFromURL(sUrl, "_blank", 0, args())
    
    ' Połączenie z bazą
    Dim oConn As Object
    oConn = ThisDatabaseDocument.CurrentController.ActiveConnection
    oStatement = oConn.createStatement()
    
    ' --- 3. DANE OSOBOWE I FILTR ---
    ' Pobieramy dane pracownika ORAZ daty z filtra globalnego
    sSQL = "SELECT " & _
           "p.imie_nazwisko, p.orcid, p.data_zatrudnienia, " & _
           "p.nazwa_katedry, p.nazwa_wydzialu, p.nazwa_stopnia, p.nazwa_stanowiska, " & _
           "f.data_od, f.data_do " & _
           "FROM oceny_pracownikow.v_dane_pracownikow p " & _
           "JOIN oceny_pracownikow.filtr_globalny f ON p.id_pracownika = f.id_wybranego_pracownika"
           
    oResultSet = oStatement.executeQuery(sSQL)
    
    If oResultSet.next() Then
        ' Wypełnianie prostych pól tekstowych
        WstawDoZakladki(oDoc, "bmkImieNazwisko", oResultSet.getString(1))
        WstawDoZakladki(oDoc, "bmkOrcid", oResultSet.getString(2))
        
        ' Pobieramy datę jako tekst (YYYY-MM-DD), konwertujemy na datę Basic i formatujemy
		WstawDoZakladki(oDoc, "bmkDataZatrudnienia", Format(CDateFromIso(oResultSet.getString(3)), "DD.MM.YYYY"))
        
        ' Miejsce pracy (Katedra + Wydział)
        sMiejscePracy = oResultSet.getString(5) & ", " & oResultSet.getString(4)
        WstawDoZakladki(oDoc, "bmkMiejscePracy", sMiejscePracy)
        
        WstawDoZakladki(oDoc, "bmkTytulStopien", oResultSet.getString(6))
        
        ' Stanowisko i Skreślanie
        sStanowisko = oResultSet.getString(7)
        WstawDoZakladki(oDoc, "bmkStanowisko", sStanowisko)
        
        ' Logika skreślania grup pracowniczych
        If sStanowisko = "badawczo-dydaktyczny" Then
            PrzekreslZakladke(oDoc, "bmkOpcjaDyd")
            PrzekreslZakladke(oDoc, "bmkOpcjaBad")
        ElseIf sStanowisko = "badawczy" Then
            PrzekreslZakladke(oDoc, "bmkOpcjaDyd")
            PrzekreslZakladke(oDoc, "bmkOpcjaBadDyd")
        ElseIf sStanowisko = "dydaktyczny" Then
            PrzekreslZakladke(oDoc, "bmkOpcjaBad")
            PrzekreslZakladke(oDoc, "bmkOpcjaBadDyd")
        End If
        
        ' Okres Oceny (złożenie dat od-do)
        dDataOd = CDateFromIso(oResultSet.getString(8))
        dDataDo = CDateFromIso(oResultSet.getString(9))
        sOkres = Format(dDataOd, "DD.MM.YYYY") & " - " & Format(dDataDo, "DD.MM.YYYY")
        WstawDoZakladki(oDoc, "bmkOkresOceny", sOkres)
        
        ' Pola, których na razie nie mamy w bazie (zostawiamy puste lub wpisujemy domyślne)
        ' bmkDyscyplina - wymagałoby osobnego zapytania do tabeli deklaracje
        ' bmkWymiarCzasu - zazwyczaj "Pełny etat", można wpisać na sztywno lub zostawić
        ' bmkFunkcje, bmkPoprzedniaOcena - do uzupełnienia ręcznego
    End If
    
    ' --- 4. PUNKTY (Z WIDOKU PODSUMOWANIA - POPRAWIONA LOGIKA) ---
    sSQL = "SELECT kod_grupy, suma_punktow FROM oceny_pracownikow.v_dashboard_podsumowanie_live"
    oResultSet = oStatement.executeQuery(sSQL)
    
    Dim sKod As String
    Dim dPkt As Double
    Dim dTotal As Double
    
    ' Zmienne tymczasowe na sumy (inicjalizujemy zerami)
    Dim dPub As Double, dBR As Double, dDyd As Double, dOrg As Double
    dPub = 0
    dBR = 0
    dDyd = 0
    dOrg = 0
    dTotal = 0
    
    ' Pętla: Tylko zbieramy dane do zmiennych (nie dotykamy jeszcze dokumentu!)
    While oResultSet.next()
        sKod = oResultSet.getString(1)
        dPkt = oResultSet.getDouble(2)
        dTotal = dTotal + dPkt
        
        If sKod = "PUB" Then dPub = dPkt
        If sKod = "BR" Then  dBR = dPkt
        If sKod = "DYD" Then dDyd = dPkt
        If sKod = "ORG" Then dOrg = dPkt
    Wend
    
    ' Dopiero teraz, RAZ, wpisujemy ostateczne wartości do dokumentu
    WstawDoZakladki(oDoc, "bmkPktPub", Format(dPub, "0.00"))
    WstawDoZakladki(oDoc, "bmkPktBR", Format(dBR, "0.00"))
    WstawDoZakladki(oDoc, "bmkPktDyd", Format(dDyd, "0.00"))
    WstawDoZakladki(oDoc, "bmkPktOrg", Format(dOrg, "0.00"))
    
    ' Suma całkowita
    WstawDoZakladki(oDoc, "bmkPktTotal", Format(dTotal, "0.00"))
    
    MsgBox "Ocena Okresowa została wygenerowana.", 64, "Gotowe"
End Sub

' --- Funkcja pomocnicza do konwersji daty z SQL (YYYY-MM-DD) na Date ---
Function CDateFromIso(sDate as String) As Date
    If sDate = "" Then Exit Function
    CDateFromIso = DateSerial(Left(sDate, 4), Mid(sDate, 6, 2), Right(sDate, 2))
End Function
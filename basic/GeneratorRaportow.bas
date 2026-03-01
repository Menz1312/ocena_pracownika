' =========================================================
' MODUŁ RAPORTOWANIA (Dostosowany do pcz_oceny)
' =========================================================

Option Explicit

Sub GenerujArkuszOceny
    Dim oStatement As Object
    Dim oResultSet As Object
    Dim sSQL As String
    Dim sSciezkaSzablonu As String
    Dim oDoc As Object
    Dim sUrl As String
    Dim sGrupaStanowisk As String ' Zmieniono nazwę zmiennej dla jasności
    
    ' --- 1. KONFIGURACJA ---
    sSciezkaSzablonu = "/home/tomasz/Dokumenty/studia/praca_inzynierska/Szablon_Zal1_Ocena.ott" 
    sUrl = ConvertToURL(sSciezkaSzablonu)
    
    If Dir(sSciezkaSzablonu) = "" Then
        MsgBox "Nie znaleziono pliku szablonu: " & sSciezkaSzablonu, 16, "Błąd"
        Exit Sub
    End If

    ' --- 2. OTWARCIE NOWEGO DOKUMENTU ---
    Dim args(0) As New com.sun.star.beans.PropertyValue
    args(0).Name = "AsTemplate"
    args(0).Value = True
    oDoc = StarDesktop.loadComponentFromURL(sUrl, "_blank", 0, args())
    
    ' Połączenie z bazą
    Dim oConn As Object
    oConn = ThisDatabaseDocument.CurrentController.ActiveConnection
    oStatement = oConn.createStatement()
    
    ' --- 3. DANE NAGŁÓWKOWE ---
    ' Używamy nowego widoku v_szczegoly_wybranego_pracownika
    ' Zwraca on nazwisko, imie, grupę stanowisk itp.
    sSQL = "SELECT nazwisko || ' ' || imie, grupa_stanowisk " & _
           "FROM pcz_oceny.v_szczegoly_wybranego_pracownika"
           
    oResultSet = oStatement.executeQuery(sSQL)
    
    If oResultSet.next() Then
        WstawDoZakladki(oDoc, "bmkImieNazwisko", oResultSet.getString(1))
        sGrupaStanowisk = oResultSet.getString(2) ' Np. "Badawczo-dydaktyczna"
        
        ' Obsługa przekreślania (Dopasuj nazwy stringów do Twoich w bazie!)
        ' W bazie masz: "Badawczo-dydaktyczna", "Badawcza", "Dydaktyczna"
        
        If sGrupaStanowisk = "Badawczo-dydaktyczny" Then
            PrzekreslZakladke(oDoc, "bmkOpcjaDyd")
            PrzekreslZakladke(oDoc, "bmkOpcjaBad")
        ElseIf sGrupaStanowisk = "Badawczy" Then
            PrzekreslZakladke(oDoc, "bmkOpcjaDyd")
            PrzekreslZakladke(oDoc, "bmkOpcjaBadDyd")
        ElseIf sGrupaStanowisk = "Dydaktyczny" Then
            PrzekreslZakladke(oDoc, "bmkOpcjaBad")
            PrzekreslZakladke(oDoc, "bmkOpcjaBadDyd")
        End If
    End If
    
    ' --- 4. SZCZEGÓŁY PUNKTACJI (Zał. 1 - Lista Lp.) ---
    ' Tutaj musimy pobrać punkty dla poszczególnych "Lp" z konfiguracji.
    ' Musimy zsumować punkty dla każdego numeru Lp (np. 1., 10a. itp.)
    
    sSQL = "SELECT ka.lp, SUM(ap.przyznane_punkty) " & _
           "FROM pcz_oceny.aktywnosci_pracownika ap " & _
           "JOIN pcz_oceny.typy_aktywnosci ta ON ap.id_typu_aktywnosci = ta.id_typu " & _
           "JOIN pcz_oceny.konfiguracja_aktywnosci ka ON ta.id_typu = ka.id_typu " & _
           "JOIN pcz_oceny.filtr_uzytkownika f ON f.nazwa_uzytkownika = CURRENT_USER " & _
           "WHERE ap.id_pracownika = f.id_pracownika " & _
           "  AND ka.id_okresu = f.id_okresu " & _
           "  AND ap.data_rozpoczecia >= (SELECT data_od FROM pcz_oceny.okresy_oceny WHERE id_okresu = f.id_okresu) " & _
           "  AND ap.data_rozpoczecia <= (SELECT data_do FROM pcz_oceny.okresy_oceny WHERE id_okresu = f.id_okresu) " & _
           "GROUP BY ka.lp"

    oResultSet = oStatement.executeQuery(sSQL)
    
    Dim sLp As String
    Dim dPkt As Double
    Dim sBmkName As String
    
    While oResultSet.next()
        sLp = oResultSet.getString(1)   ' Np. "1.", "10a."
        dPkt = oResultSet.getDouble(2)
        
        ' Usuwamy kropkę na końcu jeśli jest, żeby stworzyć poprawną nazwę zakładki
        ' Np. z "1." robimy "bmkLp1", z "10a." -> "bmkLp10a"
        sLp = Replace(sLp, ".", "") 
        sBmkName = "bmkLp" & sLp
        
        WstawDoZakladki(oDoc, sBmkName, Format(dPkt, "0.00"))
    Wend
    
    ' --- 5. SUMY KOŃCOWE ---
    ' Korzystamy z nowego widoku v_podsumowanie_wertykalne
    sSQL = "SELECT nazwa_grupy, uzyskane FROM pcz_oceny.v_podsumowanie_wertykalne " & _
           "WHERE nazwa_uzytkownika = CURRENT_USER"
           
    oResultSet = oStatement.executeQuery(sSQL)
    
    Dim sNazwaGrupy As String
    
    While oResultSet.next()
        sNazwaGrupy = oResultSet.getString(1)
        dPkt = oResultSet.getDouble(2)
        
        ' Mapowanie nazw grup z bazy na zakładki w szablonie
        ' Upewnij się, że nazwy w Case odpowiadają tym w bazie (tabela grupy_dzialan)
        Select Case sNazwaGrupy
            Case "Działalność publikacyjna (art. i monografie)"
                WstawDoZakladki(oDoc, "bmkSumaPub", Format(dPkt, "0.00"))
            Case "Działalność B+R"
                WstawDoZakladki(oDoc, "bmkSumaBR", Format(dPkt, "0.00"))
            Case "Działalność dydaktyczna"
                WstawDoZakladki(oDoc, "bmkSumaDyd", Format(dPkt, "0.00"))
            Case "Działalność organizacyjna i pozostałe"
                WstawDoZakladki(oDoc, "bmkSumaOrg", Format(dPkt, "0.00"))
            Case "=== SUMA ŁĄCZNA ==="
                WstawDoZakladki(oDoc, "bmkSumaTotal", Format(dPkt, "0.00"))
        End Select
    Wend
    
    MsgBox "Arkusz oceny został wygenerowany.", 64, "Gotowe"
End Sub

' ---------------------------------------------------------

Sub GenerujOceneOkresowa
    Dim oStatement As Object
    Dim oResultSet As Object
    Dim sSQL As String
    Dim sSciezkaSzablonu As String
    Dim oDoc As Object
    Dim sUrl As String
    Dim dDataOd As Date, dDataDo As Date
    Dim sOkres As String
    
    sSciezkaSzablonu = "/home/tomasz/Dokumenty/studia/praca_inzynierska/Szablon_Zal2_Ocena.ott"
    
    If Dir(sSciezkaSzablonu) = "" Then
        MsgBox "Nie znaleziono pliku szablonu!", 16, "Błąd"
        Exit Sub
    End If
    sUrl = ConvertToURL(sSciezkaSzablonu)

    Dim args(0) As New com.sun.star.beans.PropertyValue
    args(0).Name = "AsTemplate"
    args(0).Value = True
    oDoc = StarDesktop.loadComponentFromURL(sUrl, "_blank", 0, args())
    
    Dim oConn As Object
    oConn = ThisDatabaseDocument.CurrentController.ActiveConnection
    oStatement = oConn.createStatement()
    
    ' --- DANE OSOBOWE ---
    ' Pobieramy dane z v_szczegoly_wybranego_pracownika + daty okresu z filtr_uzytkownika
    sSQL = "SELECT " & _
           "  v.nazwisko || ' ' || v.imie, " & _
           "  v.orcid, " & _
           "  v.data_zatrudnienia, " & _
           "  v.nazwa_jednostki, " & _ 
           "  v.stopien_pelny, " & _
           "  v.nazwa_stanowiska, " & _
           "  v.grupa_stanowisk, " & _
           "  oo.data_od, " & _
           "  oo.data_do " & _
           "FROM pcz_oceny.v_szczegoly_wybranego_pracownika v " & _
           "JOIN pcz_oceny.filtr_uzytkownika f ON v.nazwa_uzytkownika = f.nazwa_uzytkownika " & _
           "JOIN pcz_oceny.okresy_oceny oo ON f.id_okresu = oo.id_okresu"
           
    oResultSet = oStatement.executeQuery(sSQL)
    
    If oResultSet.next() Then
        WstawDoZakladki(oDoc, "bmkImieNazwisko", oResultSet.getString(1))
        WstawDoZakladki(oDoc, "bmkOrcid", oResultSet.getString(2))
        
        ' Data zatrudnienia
        Dim sDataZatrudnienia as String
        sDataZatrudnienia = oResultSet.getString(3)
        If sDataZatrudnienia <> "" Then
             WstawDoZakladki(oDoc, "bmkDataZatrudnienia", Format(CDateFromIso(sDataZatrudnienia), "DD.MM.YYYY"))
        End If
        
        ' Jednostka
        WstawDoZakladki(oDoc, "bmkMiejscePracy", oResultSet.getString(4)) ' Np. Katedra X
        WstawDoZakladki(oDoc, "bmkTytulStopien", oResultSet.getString(5))
        WstawDoZakladki(oDoc, "bmkStanowisko", oResultSet.getString(6))
        
        Dim sGrupa as String
        sGrupa = oResultSet.getString(7)
        
        ' Skreślanie (Dostosuj nazwy!)
        If sGrupa = "Badawczo-dydaktyczny" Then
            PrzekreslZakladke(oDoc, "bmkOpcjaDyd")
            PrzekreslZakladke(oDoc, "bmkOpcjaBad")
        ElseIf sGrupa = "Badawczy" Then
            PrzekreslZakladke(oDoc, "bmkOpcjaDyd")
            PrzekreslZakladke(oDoc, "bmkOpcjaBadDyd")
        ElseIf sGrupa = "Dydaktyczny" Then
            PrzekreslZakladke(oDoc, "bmkOpcjaBad")
            PrzekreslZakladke(oDoc, "bmkOpcjaBadDyd")
        End If
        
        ' Okres
        dDataOd = CDateFromIso(oResultSet.getString(8))
        dDataDo = CDateFromIso(oResultSet.getString(9))
        sOkres = Format(dDataOd, "DD.MM.YYYY") & " - " & Format(dDataDo, "DD.MM.YYYY")
        WstawDoZakladki(oDoc, "bmkOkresOceny", sOkres)
    End If
    
    ' --- PUNKTY (Z tego samego widoku v_podsumowanie_wertykalne) ---
    sSQL = "SELECT nazwa_grupy, uzyskane FROM pcz_oceny.v_podsumowanie_wertykalne " & _
           "WHERE nazwa_uzytkownika = CURRENT_USER"
    oResultSet = oStatement.executeQuery(sSQL)
    
    Dim sNazwaG as String
    Dim dPkt2 as Double
    
    While oResultSet.next()
        sNazwaG = oResultSet.getString(1)
        dPkt2 = oResultSet.getDouble(2)
        
        Select Case sNazwaG
            Case "Działalność publikacyjna (art. i monografie)"
                WstawDoZakladki(oDoc, "bmkPktPub", Format(dPkt2, "0.00"))
            Case "Działalność B+R"
                WstawDoZakladki(oDoc, "bmkPktBR", Format(dPkt2, "0.00"))
            Case "Działalność dydaktyczna"
                WstawDoZakladki(oDoc, "bmkPktDyd", Format(dPkt2, "0.00"))
            Case "Działalność organizacyjna i pozostałe"
                WstawDoZakladki(oDoc, "bmkPktOrg", Format(dPkt2, "0.00"))
            Case "=== SUMA ŁĄCZNA ==="
                WstawDoZakladki(oDoc, "bmkPktTotal", Format(dPkt2, "0.00"))
        End Select
    Wend
    
    MsgBox "Ocena Okresowa została wygenerowana.", 64, "Gotowe"
End Sub

' ---------------------------------------------------------
' FUNKCJE POMOCNICZE (BEZ ZMIAN)
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
        oAnchor.CharStrikeout = 1 
    End If
End Sub

Function CDateFromIso(sDate as String) As Date
    If sDate = "" Then Exit Function
    ' Zabezpieczenie na wypadek daty już sformatowanej lub pustej
    On Error Resume Next
    CDateFromIso = DateSerial(Left(sDate, 4), Mid(sDate, 6, 2), Right(sDate, 2))
End Function
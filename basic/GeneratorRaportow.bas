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

' =====================================================================
' MAKRO: Generowanie kompletnego Załącznika nr 2 (Ocena Okresowa)
' =====================================================================
Sub GenerujOceneOkresowa
    Dim oStatement As Object
    Dim oResultSet As Object
    Dim sSQL As String
    Dim sSciezkaSzablonu As String
    Dim oDoc As Object
    Dim sUrl As String
    
    ' ========================================================
    ' PAMIĘTAJ O ZMIANIE ŚCIEŻKI DO PLIKU, JEŚLI JEST INNA!
    sSciezkaSzablonu = "/home/tomasz/Dokumenty/studia/praca_inzynierska/Szablon_Zal2_Ocena.ott"
    ' ========================================================
    
    If Dir(sSciezkaSzablonu) = "" Then
        MsgBox "Nie znaleziono pliku szablonu! Sprawdź ścieżkę.", 16, "Błąd"
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
    
    ' SUPER-ZAPYTANIE: Wyciąga absolutnie wszystkie dane z 3 etapów oceny jednym strzałem
    sSQL = "SELECT " & _
           "  v.nazwisko || ' ' || v.imie AS pracownik, v.orcid, v.data_zatrudnienia, v.nazwa_wydzialu || ', ' || v.nazwa_katedry, v.stopien_pelny, v.nazwa_stanowiska, v.grupa_stanowisk, " & _
           "  oo.data_od, oo.data_do, " & _
           "  o.suma_pkt_pub, o.suma_pkt_dyd, o.suma_pkt_org, o.suma_pkt_br, o.suma_pkt_total, " & _
           "  rk.nazwa_roli, op.nazwa_oceny AS oc_pub, od.nazwa_oceny AS oc_dyd, org.nazwa_oceny AS oc_org, ob.nazwa_oceny AS oc_br, ot.nazwa_oceny AS oc_tot, " & _
           "  o.kier_uzasadnienie_punktow, o.kier_uzasadnienie_oceny, o.kier_zatwierdzil_data, " & _
           "  okom.nazwa_oceny AS kom_oc, o.kom_uzasadnienie, o.kom_wniosek_zatrudnienie, o.kom_zatwierdzil_data, " & _
           "  do.tresc_decyzji, o.odw_uzasadnienie, o.odw_zatwierdzil_data, " & _
           "  v.nazwa_dyscypliny, v.wymiar_etatu " & _"FROM pcz_oceny.filtr_uzytkownika f " & _
           "JOIN pcz_oceny.v_szczegoly_wybranego_pracownika v ON f.nazwa_uzytkownika = v.nazwa_uzytkownika " & _
           "JOIN pcz_oceny.okresy_oceny oo ON f.id_okresu = oo.id_okresu " & _
           "JOIN pcz_oceny.oceny_okresowe o ON f.id_pracownika = o.id_pracownika AND f.id_okresu = o.id_okresu " & _
           "LEFT JOIN pcz_oceny.role_oceniajacych rk ON o.kier_id_roli = rk.id_roli " & _
           "LEFT JOIN pcz_oceny.skala_ocen op ON o.kier_id_oceny_pub = op.id_oceny " & _
           "LEFT JOIN pcz_oceny.skala_ocen od ON o.kier_id_oceny_dyd = od.id_oceny " & _
           "LEFT JOIN pcz_oceny.skala_ocen org ON o.kier_id_oceny_org = org.id_oceny " & _
           "LEFT JOIN pcz_oceny.skala_ocen ob ON o.kier_id_oceny_br = ob.id_oceny " & _
           "LEFT JOIN pcz_oceny.skala_ocen ot ON o.kier_id_oceny_total = ot.id_oceny " & _
           "LEFT JOIN pcz_oceny.skala_ocen okom ON o.kom_id_oceny = okom.id_oceny " & _
           "LEFT JOIN pcz_oceny.decyzje_odwolawcze do ON o.odw_id_decyzji = do.id_decyzji " & _
           "WHERE f.nazwa_uzytkownika = CURRENT_USER"
           
    oResultSet = oStatement.executeQuery(sSQL)
    
    If oResultSet.next() Then
        
        ' =======================================================
        ' 1. DANE PRACOWNIKA
        ' =======================================================
        WstawDoZakladki(oDoc, "bmkImieNazwisko", oResultSet.getString(1))
        WstawDoZakladki(oDoc, "bmkOrcid", oResultSet.getString(2))
        
        Dim sDataZatrudnienia As String
        sDataZatrudnienia = oResultSet.getString(3)
        If sDataZatrudnienia <> "" Then WstawDoZakladki(oDoc, "bmkDataZatrudnienia", Format(CDateFromIso(sDataZatrudnienia), "DD.MM.YYYY"))
        
        WstawDoZakladki(oDoc, "bmkMiejscePracy", oResultSet.getString(4))
        WstawDoZakladki(oDoc, "bmkTytulStopien", oResultSet.getString(5))
        WstawDoZakladki(oDoc, "bmkStanowisko", oResultSet.getString(6))
        
        WstawDoZakladki(oDoc, "bmkDyscyplina", oResultSet.getString(31))
        WstawDoZakladki(oDoc, "bmkEtat", oResultSet.getString(32))

        ' =======================================================
        ' 2. SKREŚLENIA: GRUPA STANOWISK
        ' =======================================================
        Dim sGrupa As String
        sGrupa = oResultSet.getString(7)
        
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
        
        ' =======================================================
        ' 3. OKRES OCENY
        ' =======================================================
        Dim dDataOd As Date, dDataDo As Date
        dDataOd = CDateFromIso(oResultSet.getString(8))
        dDataDo = CDateFromIso(oResultSet.getString(9))
        WstawDoZakladki(oDoc, "bmkOkresOceny", Format(dDataOd, "DD.MM.YYYY") & " - " & Format(dDataDo, "DD.MM.YYYY"))
        
        ' =======================================================
        ' 4. ZAMROŻONE PUNKTY
        ' =======================================================
        WstawDoZakladki(oDoc, "bmkPktPub", oResultSet.getString(10))
        WstawDoZakladki(oDoc, "bmkPktDyd", oResultSet.getString(11))
        WstawDoZakladki(oDoc, "bmkPktOrg", oResultSet.getString(12))
        WstawDoZakladki(oDoc, "bmkPktBR", oResultSet.getString(13))
        WstawDoZakladki(oDoc, "bmkPktTotal", oResultSet.getString(14))
        
        ' =======================================================
        ' 5. ETAP I: KIEROWNIK
        ' =======================================================
        Dim sRolaKierownika As String
        sRolaKierownika = oResultSet.getString(15) ' Pobieramy rolę z bazy
        
        If sRolaKierownika = "Prodziekan ds. nauki" Then
            PrzekreslZakladke(oDoc, "bmkRolaDziekan")
            PrzekreslZakladke(oDoc, "bmkRolaKierownik")
            
        ElseIf sRolaKierownika = "Dziekan" Then
            PrzekreslZakladke(oDoc, "bmkRolaProdziekan")
            PrzekreslZakladke(oDoc, "bmkRolaKierownik")
            
        ElseIf sRolaKierownika = "Kierownik jednostki międzywydziałowej" Then
            PrzekreslZakladke(oDoc, "bmkRolaProdziekan")
            PrzekreslZakladke(oDoc, "bmkRolaDziekan")
        End If
        
        WstawDoZakladki(oDoc, "bmkKierOcenaPub", oResultSet.getString(16))
        WstawDoZakladki(oDoc, "bmkKierOcenaDyd", oResultSet.getString(17))
        WstawDoZakladki(oDoc, "bmkKierOcenaOrg", oResultSet.getString(18))
        WstawDoZakladki(oDoc, "bmkKierOcenaBR", oResultSet.getString(19))
        WstawDoZakladki(oDoc, "bmkKierOcenaTotal", oResultSet.getString(20))
        WstawDoZakladki(oDoc, "bmkKierUzasPkt", oResultSet.getString(21))
        WstawDoZakladki(oDoc, "bmkKierUzasOceny", oResultSet.getString(22))
        
        If oResultSet.getString(23) <> "" Then WstawDoZakladki(oDoc, "bmkKierData", Format(CDateFromIso(Left(oResultSet.getString(23), 10)), "DD.MM.YYYY"))
        
        ' =======================================================
        ' 6. ETAP II: KOMISJA
        ' =======================================================
        Dim sKomOcena As String
        sKomOcena = oResultSet.getString(24) ' Pobieramy ocenę komisji z bazy
        
        If sKomOcena <> "" Then
            If sKomOcena = "Negatywna" Then
                PrzekreslZakladke(oDoc, "bmkKomOcenaPozytywna")
                PrzekreslZakladke(oDoc, "bmkKomOcenaWarunkowa")
                PrzekreslZakladke(oDoc, "bmkKomOcenaPozytywna2")
                PrzekreslZakladke(oDoc, "bmkKomOcenaWarunkowa2")
                
            ElseIf sKomOcena = "Pozytywna" Then
                PrzekreslZakladke(oDoc, "bmkKomOcenaNegatywna")
                PrzekreslZakladke(oDoc, "bmkKomOcenaWarunkowa")
                PrzekreslZakladke(oDoc, "bmkKomOcenaNegatywna2")
                PrzekreslZakladke(oDoc, "bmkKomOcenaWarunkowa2")
                
            ElseIf sKomOcena = "Pozytywna warunkowa" Then
                PrzekreslZakladke(oDoc, "bmkKomOcenaNegatywna")
                PrzekreslZakladke(oDoc, "bmkKomOcenaPozytywna")
                PrzekreslZakladke(oDoc, "bmkKomOcenaNegatywna2")
                PrzekreslZakladke(oDoc, "bmkKomOcenaPozytywna2")
            End If
        End If
        
        WstawDoZakladki(oDoc, "bmkKomUzas", oResultSet.getString(25))
        WstawDoZakladki(oDoc, "bmkKomWniosek", oResultSet.getString(26))
        If oResultSet.getString(27) <> "" Then WstawDoZakladki(oDoc, "bmkKomData", Format(CDateFromIso(Left(oResultSet.getString(27), 10)), "DD.MM.YYYY"))
        
        ' =======================================================
        ' 7. ETAP III: ODWOŁANIE
        ' =======================================================
        Dim sOdwDecyzja As String
        sOdwDecyzja = oResultSet.getString(28) ' Pobieramy decyzję odwoławczą z bazy
        
        If sOdwDecyzja <> "" Then
            If sOdwDecyzja = "utrzymuje w mocy negatywną ocenę Komisji ds. Oceny Nauczycieli Akademickich" Then
                PrzekreslZakladke(oDoc, "bmkOdwDecyzja2")
                PrzekreslZakladke(oDoc, "bmkOdwDecyzja3")
                PrzekreslZakladke(oDoc, "bmkOdwDecyzja4")
                
            ElseIf sOdwDecyzja = "utrzymuje w mocy pozytywną warunkową ocenę Komisji ds. Oceny Nauczycieli Akademickich" Then
                PrzekreslZakladke(oDoc, "bmkOdwDecyzja1")
                PrzekreslZakladke(oDoc, "bmkOdwDecyzja3")
                PrzekreslZakladke(oDoc, "bmkOdwDecyzja4")
                
            ElseIf sOdwDecyzja = "zmienia ocenę na pozytywną warunkową" Then
                PrzekreslZakladke(oDoc, "bmkOdwDecyzja1")
                PrzekreslZakladke(oDoc, "bmkOdwDecyzja2")
                PrzekreslZakladke(oDoc, "bmkOdwDecyzja4")
                
            ElseIf sOdwDecyzja = "zmienia ocenę na pozytywną" Then
                PrzekreslZakladke(oDoc, "bmkOdwDecyzja1")
                PrzekreslZakladke(oDoc, "bmkOdwDecyzja2")
                PrzekreslZakladke(oDoc, "bmkOdwDecyzja3")
            End If
        End If
        
        WstawDoZakladki(oDoc, "bmkOdwUzas", oResultSet.getString(29))
        If oResultSet.getString(30) <> "" Then WstawDoZakladki(oDoc, "bmkOdwData", Format(CDateFromIso(Left(oResultSet.getString(30), 10)), "DD.MM.YYYY"))
        
    End If
    
    MsgBox "Dokument Oceny Okresowej został pomyślnie wygenerowany!", 64, "Sukces"
End Sub

' ---------------------------------------------------------
' FUNKCJE POMOCNICZE (BEZ ZMIAN)
' ---------------------------------------------------------

Sub WstawDoZakladki(oDoc As Object, sNazwaZakladki As String, sTekst As String)
    Dim oBookmarks As Object
    Dim oAnchor As Object
    
    ' Zabezpieczenie na wypadek próby wstawienia wartości Null z bazy
    If IsNull(sTekst) Then sTekst = "" 
    
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

Function CDateFromIso(sDate As String) As Date
    If sDate = "" Then Exit Function
    ' Zabezpieczenie na wypadek daty już sformatowanej lub pustej
    On Error Resume Next
    CDateFromIso = DateSerial(Left(sDate, 4), Mid(sDate, 6, 2), Right(sDate, 2))
End Function
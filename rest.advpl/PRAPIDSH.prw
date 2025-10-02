#include 'Protheus.ch'
#include 'Restful.ch'

WsRestful dashboard Description "Dashboard"

    WsMethod Post   FaPer   Description "Retorna o faturamento por período"     Path "/faturamento-x-periodo"
    WsMethod Post   HisFa   Description "Retorna o histórico de faturamento"    Path "/historico-faturamento"
    WsMethod Post   CatCl   Description "Categorias de Clientes"                Path "/categorias-clientes"

End WsRestful


WsMethod Post FaPer WsService dashboard

    Local jResponse         := JsonObject():New()
    Local jAno              := JsonObject():New()
    Local jBody             := JsonObject():New()
    Local cBody             := Self:GetContent()
    Local cQuery            := ""
    Local cAlias            := GetNextAlias()
    Local aAno              := {}
    Local cAno              := ""
    Local aAnos             := {}
    Local nPos              := 0
    Local lRet              := .T.
    
    jBody:fromJson(cBody)

    cQuery := QryFatXPer()

    MPSysOpenQuery(cQuery,cAlias)

    (cAlias)->(DbGoTop())

    While !(cAlias)->(Eof())
    
        cAno := AllTrim((cAlias)->ANO)
        aAno := Array(12)
    
        While !(cAlias)->(Eof()) .And. AllTrim((cAlias)->ANO) == cAno
           
            aAno[val((cAlias)->MES)] := Round((cAlias)->VALOR,2)
            (cAlias)->(DbSkip())

        EndDo

        For nPos := 1 To Len(aAno)

            If Empty(aAno[nPos])

                aAno[nPos] := 0

            EndIf
        
        Next

        jAno := JsonObject():New()

        jAno["ano"]     := cAno
        jAno["meses"]   := aAno

        AAdd(aAnos, jAno)

    EndDo

    jResponse["anos"] := aAnos

    Self:SetResponse(jResponse:toJson())

    (cAlias)->(DbCloseArea())

Return lRet


WsMethod Post HisFa WsService dashboard

    Local jResponse         := JsonObject():New()
    Local jBody             := JsonObject():New()
    Local cBody             := Self:GetContent()
    Local cQuery            := ""
    Local cAlias            := GetNextAlias()
    Local aAnos             := {}
    Local aValores          := {}
    Local lRet              := .T.
    
    jBody:fromJson(cBody)

    cQuery := QryHistFat()

    MPSysOpenQuery(cQuery,cAlias)

    (cAlias)->(DbGoTop())

    While !(cAlias)->(Eof())
    
        AAdd(aAnos,     AllTrim((cAlias)->ANO))
        AAdd(aValores,  Round((cAlias)->VALOR,2))

        (cAlias)->(DbSkip())

    EndDo

    jResponse["anos"]       := aAnos
    jResponse["valores"]    := aValores

    Self:SetResponse(jResponse:toJson())

    (cAlias)->(DbCloseArea())

Return lRet


WsMethod Post CatCl WsService dashboard

    Local jResponse         := JsonObject():New()
    Local jBody             := JsonObject():New()
    Local cBody             := Self:GetContent()
    Local cQuery            := ""
    Local cAlias            := GetNextAlias()
    Local aCategorias       := getCategorias()
    Local aPercentuais      := {}
    Local jCategoria        := JsonObject():New()
    Local lRet              := .T.
    
    jBody:fromJson(cBody)

    cQuery := QryCatCli()

    MPSysOpenQuery(cQuery,cAlias)

    (cAlias)->(DbGoTop())

    While !(cAlias)->(Eof())
    
        jCategoria := JsonObject():New()

        jCategoria["codigo"]        := AllTrim((cAlias)->CATEGORIA)
        jCategoria["categoria"]     := IIf(Empty(AllTrim((cAlias)->CATEGORIA)), "Sem Categoria", aCategorias[AScan(aCategorias, {|x| AllTrim(x[1]) == (cAlias)->CATEGORIA})][2])
        jCategoria["percentual"]    := (cAlias)->PERCENTUAL

        AAdd(aPercentuais, jCategoria)

        (cAlias)->(DbSkip())

    EndDo

    jResponse["categorias"] := aPercentuais

    Self:SetResponse(jResponse:toJson())

    (cAlias)->(DbCloseArea())

Return lRet


Static Function QryFatXPer()

    Local cQuery        := ""

    cQuery += " SELECT LEFT(D2_EMISSAO,4) AS ANO, SUBSTRING(D2_EMISSAO,5,2) AS MES, SUM(D2_TOTAL) AS VALOR
    cQuery += " FROM " + RetSQLName("SD2") + " SD2
    cQuery += " INNER JOIN " + RetSQLName("SC5") + " SC5 ON C5_FILIAL = D2_FILIAL AND C5_NUM = D2_PEDIDO AND SC5.D_E_L_E_T_ = ' '
    cQuery += " WHERE SD2.D_E_L_E_T_ = ' ' AND D2_EMISSAO BETWEEN 20230101 AND 20251231
    cQuery += " GROUP BY LEFT(D2_EMISSAO,4), SUBSTRING(D2_EMISSAO,5,2)
    cQuery += " ORDER BY ANO,MES

Return cQuery

Static Function QryHistFat()

    Local cQuery        := ""

    cQuery += " SELECT LEFT(D2_EMISSAO,4) AS ANO, SUM(D2_TOTAL) AS VALOR
    cQuery += " FROM " + RetSQLName("SD2") + " SD2
    cQuery += " INNER JOIN " + RetSQLName("SC5") + " SC5 ON C5_FILIAL = D2_FILIAL AND C5_NUM = D2_PEDIDO AND SC5.D_E_L_E_T_ = ' '
    cQuery += " WHERE SD2.D_E_L_E_T_ = ' ' AND D2_EMISSAO BETWEEN 20230101 AND 20251231
    cQuery += " GROUP BY LEFT(D2_EMISSAO,4)
    cQuery += " ORDER BY ANO

Return cQuery

Static Function QryCatCli()

    Local cQuery        := ""

    cQuery += " SELECT A1_YCATEGO AS CATEGORIA, CAST(SUM(D2_TOTAL) * 100.0 / SUM(SUM(D2_TOTAL)) OVER() AS DECIMAL(5,2)) AS PERCENTUAL
    cQuery += " FROM " + RetSQLName("SD2") + " SD2
    cQuery += " INNER JOIN " + RetSQLName("SC5") + " SC5 ON C5_FILIAL = D2_FILIAL AND C5_NUM = D2_PEDIDO AND SC5.D_E_L_E_T_ = ' '
    cQuery += " INNER JOIN " + RetSQLName("SA1") + " SA1 ON A1_COD = D2_CLIENTE AND A1_LOJA = D2_LOJA AND SA1.D_E_L_E_T_ = ' '
    cQuery += " WHERE SD2.D_E_L_E_T_ = ' ' AND D2_EMISSAO BETWEEN 20230101 AND 20251231
    cQuery += " GROUP BY A1_YCATEGO
    cQuery += " ORDER BY PERCENTUAL DESC

Return cQuery

Static Function getCategorias()

    Local aCategorias       := {}
    Local cCategorias       := AllTrim(u_zCategCli())
    Local nPos              := 0

    aCategorias := StrTokArr2(cCategorias,";")

    For nPos := 1 To Len(aCategorias)

        aCategorias[nPos] := StrTokArr2(aCategorias[nPos],"=")

        aCategorias[nPos][1] := AllTrim(aCategorias[nPos][1])
        aCategorias[nPos][2] := AllTrim(aCategorias[nPos][2])

    Next

Return aCategorias

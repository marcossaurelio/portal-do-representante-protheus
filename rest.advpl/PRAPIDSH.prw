#include 'Protheus.ch'
#include 'Restful.ch'

WsRestful dashboard Description "Dashboard"

    WsData value    AS Character

    WsMethod Post   FaPer   Description "Retorna o faturamento por período"     Path "/faturamento-x-periodo"
    WsMethod Post   HisFa   Description "Retorna o histórico de faturamento"    Path "/historico-faturamento"
    WsMethod Post   CatCl   Description "Categorias de Clientes"                Path "/categorias-clientes"
    WsMethod Post   CatPr   Description "Categorias de Produtos"                Path "/categorias-produtos"
    WsMethod Get    Anos    Description "Anos para filtro"                      Path "/filtros/anos"

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

    cQuery := QryFatXPer(jBody)

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

    cQuery := QryHistFat(jBody)

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

    cQuery := QryCatCli(jBody)

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


WsMethod Post CatPr WsService dashboard

    Local jResponse         := JsonObject():New()
    Local jAno              := JsonObject():New()
    Local jBody             := JsonObject():New()
    Local cBody             := Self:GetContent()
    Local cQuery            := ""
    Local cAlias            := GetNextAlias()
    Local aValores          := {}
    Local aProdutos         := {}
    Local cAno              := ""
    Local aAnos             := {}
    Local nPos              := 0
    Local lRet              := .T.
    
    jBody:fromJson(cBody)

    cQuery := QryCatProd(jBody)

    MPSysOpenQuery(cQuery,cAlias)

    (cAlias)->(DbGoTop())

    While !(cAlias)->(Eof())

        If AScan(aProdutos, AllTrim((cAlias)->DESCRICAO)) == 0

            AAdd(aProdutos, AllTrim((cAlias)->DESCRICAO))

        EndIf

        (cAlias)->(DbSkip())

    EndDo

    (cAlias)->(DbGoTop())

    While !(cAlias)->(Eof())
    
        cAno := AllTrim((cAlias)->ANO)
        aValores := Array(Len(aProdutos))
    
        While !(cAlias)->(Eof()) .And. AllTrim((cAlias)->ANO) == cAno
           
            aValores[AScan(aProdutos, AllTrim((cAlias)->DESCRICAO))] := Round((cAlias)->VALOR,2)
            (cAlias)->(DbSkip())

        EndDo

        For nPos := 1 To Len(aValores)

            If Empty(aValores[nPos])

                aValores[nPos] := 0

            EndIf
        
        Next

        jAno := JsonObject():New()

        jAno["ano"]         := cAno
        jAno["valores"]     := aValores

        AAdd(aAnos, jAno)

    EndDo

    JResponse["produtos"]   := aProdutos
    jResponse["anos"]       := aAnos

    Self:SetResponse(jResponse:toJson())

    (cAlias)->(DbCloseArea())

Return lRet


WsMethod Get Anos WsService dashboard

    Local jResponse         := JsonObject():New()
    Local jAno              := JsonObject():New()
    Local aAnos             := {}
    Local cAno              := ""
    Local nAnoAtual         := Year(Date())
    Local nQtdAnos          := 10
    Local nPos              := 0
    Local aAnosValue        := {}
    Local lRet              := .T.

    default self:value := ""

    aAnosValue := StrTokArr2(self:value,",")

    For nPos := 1 To nQtdAnos

        jAno := JsonObject():New()
        cAno := AllTrim(cValToChar(nAnoAtual - (nPos - 1)))

        If Empty(aAnosValue) .Or. AScan(aAnosValue, cAno) > 0

            jAno["value"]     := cAno
            jAno["label"]     := cAno

            AAdd(aAnos, jAno)
        
        EndIf

    Next

    jResponse["items"] := aAnos

    Self:SetResponse(jResponse:toJson())

Return lRet


Static Function QryFatXPer(jBody)

    Local cQuery        := ""
    Local jBodyInfo     := FormatBody(jBody)
    Local cAnos         := jBodyInfo:GetJsonObject("anos")
    Local cMeses        := jBodyInfo:GetJsonObject("meses")
    Local cFiliais      := jBodyInfo:GetJsonObject("filiais")
    Local cVendedores   := jBodyInfo:GetJsonObject("vendedores")
    Local cProdutos     := jBodyInfo:GetJsonObject("produtos")

    cQuery += " SELECT LEFT(D2_EMISSAO,4) AS ANO, SUBSTRING(D2_EMISSAO,5,2) AS MES, SUM(D2_TOTAL) AS VALOR
    cQuery += " FROM " + RetSQLName("SD2") + " SD2
    cQuery += " INNER JOIN " + RetSQLName("SC5") + " SC5 ON C5_FILIAL = D2_FILIAL AND C5_NUM = D2_PEDIDO AND SC5.D_E_L_E_T_ = ' '
    cQuery += " WHERE SD2.D_E_L_E_T_ = ' ' AND LEFT(D2_EMISSAO,4) IN " + cAnos + " AND SUBSTRING(D2_EMISSAO,5,2) IN " + cMeses
    cQuery += " AND D2_FILIAL IN " + cFiliais

    If !Empty(cVendedores)

        cQuery += " AND C5_VEND1 IN " + cVendedores
    
    EndIf

    If !Empty(cProdutos)

        cQuery += " AND D2_COD IN " + cProdutos

    EndIf

    cQuery += " GROUP BY LEFT(D2_EMISSAO,4), SUBSTRING(D2_EMISSAO,5,2)
    cQuery += " ORDER BY ANO,MES

Return cQuery

Static Function QryHistFat(jBody)

    Local cQuery        := ""
    Local jBodyInfo     := FormatBody(jBody)
    Local cAnos         := jBodyInfo:GetJsonObject("anos")
    Local cMeses        := jBodyInfo:GetJsonObject("meses")
    Local cFiliais      := jBodyInfo:GetJsonObject("filiais")
    Local cVendedores   := jBodyInfo:GetJsonObject("vendedores")
    Local cProdutos     := jBodyInfo:GetJsonObject("produtos")

    cQuery += " SELECT LEFT(D2_EMISSAO,4) AS ANO, SUM(D2_TOTAL) AS VALOR
    cQuery += " FROM " + RetSQLName("SD2") + " SD2
    cQuery += " INNER JOIN " + RetSQLName("SC5") + " SC5 ON C5_FILIAL = D2_FILIAL AND C5_NUM = D2_PEDIDO AND SC5.D_E_L_E_T_ = ' '
    cQuery += " WHERE SD2.D_E_L_E_T_ = ' ' AND LEFT(D2_EMISSAO,4) IN " + cAnos + " AND SUBSTRING(D2_EMISSAO,5,2) IN " + cMeses
    cQuery += " AND D2_FILIAL IN " + cFiliais

    If !Empty(cVendedores)

        cQuery += " AND C5_VEND1 IN " + cVendedores
    
    EndIf

    If !Empty(cProdutos)

        cQuery += " AND D2_COD IN " + cProdutos

    EndIf

    cQuery += " GROUP BY LEFT(D2_EMISSAO,4)
    cQuery += " ORDER BY ANO

Return cQuery

Static Function QryCatCli(jBody)

    Local cQuery        := ""
    Local jBodyInfo     := FormatBody(jBody)
    Local cAnos         := jBodyInfo:GetJsonObject("anos")
    Local cMeses        := jBodyInfo:GetJsonObject("meses")
    Local cFiliais      := jBodyInfo:GetJsonObject("filiais")
    Local cVendedores   := jBodyInfo:GetJsonObject("vendedores")
    Local cProdutos     := jBodyInfo:GetJsonObject("produtos")

    cQuery += " SELECT A1_YCATEGO AS CATEGORIA, CAST(SUM(D2_TOTAL) * 100.0 / SUM(SUM(D2_TOTAL)) OVER() AS DECIMAL(5,2)) AS PERCENTUAL
    cQuery += " FROM " + RetSQLName("SD2") + " SD2
    cQuery += " INNER JOIN " + RetSQLName("SC5") + " SC5 ON C5_FILIAL = D2_FILIAL AND C5_NUM = D2_PEDIDO AND SC5.D_E_L_E_T_ = ' '
    cQuery += " INNER JOIN " + RetSQLName("SA1") + " SA1 ON A1_COD = D2_CLIENTE AND A1_LOJA = D2_LOJA AND SA1.D_E_L_E_T_ = ' '
    cQuery += " WHERE SD2.D_E_L_E_T_ = ' ' AND LEFT(D2_EMISSAO,4) IN " + cAnos + " AND SUBSTRING(D2_EMISSAO,5,2) IN " + cMeses
    cQuery += " AND D2_FILIAL IN " + cFiliais

    If !Empty(cVendedores)

        cQuery += " AND C5_VEND1 IN " + cVendedores
    
    EndIf

    If !Empty(cProdutos)

        cQuery += " AND D2_COD IN " + cProdutos

    EndIf

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

Static Function QryCatProd(jBody)

    Local cQuery        := ""
    Local jBodyInfo     := FormatBody(jBody)
    Local cAnos         := jBodyInfo:GetJsonObject("anos")
    Local cMeses        := jBodyInfo:GetJsonObject("meses")
    Local cFiliais      := jBodyInfo:GetJsonObject("filiais")
    Local cVendedores   := jBodyInfo:GetJsonObject("vendedores")
    Local cProdutos     := jBodyInfo:GetJsonObject("produtos")
    Local aAnos         := jBody:GetJsonObject("anos")
    Local cMaiorAno     := GetMax(aAnos)

    cQuery += " WITH RANKING_ULT_ANO AS (
    cQuery += "     SELECT TOP 10
    cQuery += "         D2_COD,
    cQuery += "         SUM(D2_TOTAL) AS TOTAL
    cQuery += "     FROM " + RetSQLName("SD2") + " SD2
    cQuery += "     INNER JOIN " + RetSQLName("SC5") + " SC5
    cQuery += "         ON C5_FILIAL = D2_FILIAL 
    cQuery += "        AND C5_NUM = D2_PEDIDO 
    cQuery += "        AND SC5.D_E_L_E_T_ = ' '
    cQuery += "     WHERE SD2.D_E_L_E_T_ = ' ' 
    cQuery += "       AND LEFT(D2_EMISSAO,4) = '" + cMaiorAno + "'
    cQuery += "       AND D2_FILIAL IN " + cFiliais


    If !Empty(cVendedores)

        cQuery += " AND C5_VEND1 IN " + cVendedores
    
    EndIf

    If !Empty(cProdutos)

        cQuery += " AND D2_COD IN " + cProdutos

    EndIf

    cQuery += "     GROUP BY D2_COD
    cQuery += "     ORDER BY TOTAL DESC
    cQuery += " )
    cQuery += " SELECT
    cQuery += "     B1_DESC AS DESCRICAO,
    cQuery += "     LEFT(D2_EMISSAO, 4) AS ANO,
    cQuery += "     SUM(D2_TOTAL) AS VALOR,
    cQuery += "     T.TOTAL
    cQuery += " FROM " + RetSQLName("SD2") + " SD2
    cQuery += " INNER JOIN " + RetSQLName("SC5") + " SC5
    cQuery += "     ON C5_FILIAL = D2_FILIAL 
    cQuery += "    AND C5_NUM = D2_PEDIDO 
    cQuery += "    AND SC5.D_E_L_E_T_ = ' '
    cQuery += " INNER JOIN " + RetSQLName("SB1") + " SB1
    cQuery += "     ON B1_COD = D2_COD 
    cQuery += "    AND SB1.D_E_L_E_T_ = ' '
    cQuery += " INNER JOIN RANKING_ULT_ANO T 
    cQuery += "     ON T.D2_COD = SD2.D2_COD
    cQuery += " WHERE SD2.D_E_L_E_T_ = ' ' 
    cQuery += "   AND LEFT(D2_EMISSAO,4) IN " + cAnos + " AND SUBSTRING(D2_EMISSAO,5,2) IN " + cMeses
    cQuery += "   AND SD2.D2_FILIAL IN " + cFiliais

    If !Empty(cVendedores)

        cQuery += " AND SC5.C5_VEND1 IN " + cVendedores
    
    EndIf

    If !Empty(cProdutos)

        cQuery += " AND SD2.D2_COD IN " + cProdutos

    EndIf

    cQuery += " GROUP BY B1_DESC, LEFT(D2_EMISSAO, 4), T.TOTAL
    cQuery += " ORDER BY ANO DESC, T.TOTAL ASC

Return cQuery

Static Function FormatBody(jBody)

    Local jReturn       := JsonObject():New()
    Local aAnos         := jBody:GetJsonObject("anos")
    Local aMeses        := jBody:GetJsonObject("meses")
    Local aFiliais      := jBody:GetJsonObject("filiais")
    Local aVendedores   := jBody:GetJsonObject("vendedores")
    Local aProdutos     := jBody:GetJsonObject("produtos")

    jReturn["anos"]         := FormatIn(ArrTokStr(aAnos,","),",")
    jReturn["meses"]        := FormatIn(ArrTokStr(aMeses,","),",")
    jReturn["filiais"]      := FormatIn(ArrTokStr(aFiliais,","),",")
    jReturn["vendedores"]   := IIf(Empty(aVendedores),  "", FormatIn(ArrTokStr(aVendedores,","),",")    )
    jReturn["produtos"]     := IIf(Empty(aProdutos),    "", FormatIn(ArrTokStr(aProdutos,","),",")      )

Return jReturn

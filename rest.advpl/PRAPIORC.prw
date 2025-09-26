#include 'Protheus.ch'
#include 'Restful.ch'

WsRestful orcamentos Description "Orcamentos"

    WsData page             AS Character
    WsData pageSize         AS Character
    WsData filtro           AS Character
    WsData sellerId         AS Character
    WsData branchId         AS Character
    WsData budget           AS Character

    WsMethod Post   Orcs    Description "Retorna os orcamentos de um vendedor"      Path "/"
    WsMethod Get    OrcDt   Description "Retorna os dados de um orcamento"          Path "/dados"
    WsMethod Post   OrcIn   Description "Inclui um orcamento"                       Path "/incluir"
    WsMethod Put    OrcUp   Description "Altera um orcamento"                       Path "/alterar"
    WsMethod Post   Indic   Description "Retorna os indicadores de orcamentos"      Path "/indicadores"
    WsMethod Put    ApCot   Description "Aprova uma cotação"                        Path "/cotacao/aprovar"
    WsMethod Put    RjCot   Description "Rejeita uma cotação"                       Path "/cotacao/rejeitar"
    WsMethod Put    ApPPd   Description "Envia Pré Pedido para aprovação"           Path "/pre-pedido/aprovar"

End WsRestful


WsMethod Post Orcs WsService orcamentos

    local jResponse     := JsonObject():New()       as json
    local jBody         := JsonObject():new()       as json
    local cBody         := self:getContent()        as character
    local cVendedor     := ""                       as character
    local cPagina       := "1"                      as character
    local cFiltro       := ""                       as character
    local cQuery        := ""                       as character
    local cAlias        := ""                       as character
    local jRegistro                                 as json
    local lRet          := .T.

    default self:page               := "1"
    default self:pageSize           := "10"
    default self:filtro             := ""
    default self:sellerId           := ""
    default self:branchId           := ""
    default self:budget             := ""

    cVendedor := self:sellerId
    cPagina   := self:page
    
    jBody:fromJson(cBody)

    cFiltro := jBody:getJsonObject('filtro')

    cQuery := qryBrowse(cPagina,cVendedor,cFiltro)

    cAlias := getNextAlias()

    MPSysOpenQuery(cQuery,cAlias)

    dbSelectArea(cAlias)
    (cAlias)->(dbGoTop())

    jResponse['objects'] = {}

    while !(cAlias)->(eof())

        jRegistro := JsonObject():New()

        jRegistro['filial']                 := (cAlias)->CJ_FILIAL
        jRegistro['unidadeCarregamento']    := (cAlias)->CJ_YUNCARG
        jRegistro['orcamento']              := (cAlias)->CJ_NUM
        JRegistro['vendedor']               := (cAlias)->CJ_YVEND
        jRegistro['nomeVendedor']           := posicione("SA3",1,xFilial("SA3") + (cAlias)->CJ_YVEND,"A3_NREDUZ")
        jRegistro['dataEmissao']            := (cAlias)->CJ_EMISSAO
        jRegistro['cliente']                := (cAlias)->CJ_CLIENTE
        jRegistro['nomeCliente']            := posicione("SA1",1,xFilial("SA1") + (cAlias)->CJ_CLIENTE + (cAlias)->CJ_LOJA,"A1_NOME")
        jRegistro['situacao']               := iif( sToD((cAlias)->CJ_VALIDA) < date() .And. (cAlias)->CJ_YPRSITU $ "CP;PP", "EX", (cAlias)->CJ_YPRSITU )
        jRegistro['pedido']                 := (cAlias)->C5_NUM
        jRegistro['situacaoPedido']         := iif( !empty((cAlias)->C5_NUM), iif( !empty((cAlias)->C5_NOTA) .And. !("X" $ (cAlias)->C5_NOTA), "F", "C" ), nil)
        jRegistro['dataVencimento']         := (cAlias)->CJ_VALIDA
        jRegistro['dataAlteracao']          := (cAlias)->CJ_YDTALTE

        aAdd(jResponse['objects'],jRegistro)

        (cAlias)->(dbSkip())

    enddo

    self:setResponse(jResponse:toJson())

    (cAlias)->(DbCloseArea())

return lRet


WsMethod Get OrcDt WsService orcamentos

    local jResponse         := JsonObject():New()       as json
    local aQuery            := {}                       as array
    local cAliasCabecalho   := ""                       as character
    local cAliasItens       := ""                       as character
    local cFilialOrc        := ""                       as character
    local cOrcamento        := ""                       as character
    local cCliLoja          := ""                       as character
    local jItem                                         as json
    local lRet              := .T.

    default self:page               := "1"
    default self:pageSize           := "10"
    default self:filtro             := ""
    default self:sellerId           := ""
    default self:branchId           := ""
    default self:budget             := ""

    cFilialOrc := self:branchId
    cOrcamento := self:budget

    aQuery := qryDados(cFilialOrc,cOrcamento)

    cAliasCabecalho := getNextAlias()
    cAliasItens     := getNextAlias()

    MPSysOpenQuery(aQuery[1],cAliasCabecalho)

    dbSelectArea(cAliasCabecalho)
    (cAliasCabecalho)->(dbGoTop())

    cCliLoja := (cAliasCabecalho)->CJ_CLIENTE + (cAliasCabecalho)->CJ_LOJA

    jResponse['filial']                 := (cAliasCabecalho)->CJ_FILIAL
    jResponse['orcamento']              := (cAliasCabecalho)->CJ_NUM
    jResponse['unidadeCarregamento']    := AllTrim((cAliasCabecalho)->CJ_YUNCARG)
    jResponse['vendedor']               := (cAliasCabecalho)->CJ_YVEND
    jResponse['situacao']               := iif( sToD((cAliasCabecalho)->CJ_VALIDA) < date() .And. (cAliasCabecalho)->CJ_YPRSITU $ "CP;PP", "EX", (cAliasCabecalho)->CJ_YPRSITU )
    jResponse['cliente']                := (cAliasCabecalho)->CJ_CLIENTE
    jResponse['loja']                   := (cAliasCabecalho)->CJ_LOJA
    jResponse['nomeCliente']            := posicione("SA1",1,xFilial("SA1") + cCliLoja,"A1_NOME")
    jResponse['dataEmissao']            := (cAliasCabecalho)->CJ_EMISSAO
    jResponse['condPag']                := (cAliasCabecalho)->CJ_CONDPAG
    jResponse['observacao']             := (cAliasCabecalho)->CJ_YOBS
    jResponse['tipoFrete']              := (cAliasCabecalho)->CJ_TPFRETE
    jResponse['condPagFrete']           := (cAliasCabecalho)->CJ_YCPAGFR
    jResponse['valorFrete']             := (cAliasCabecalho)->CJ_FRETE
    jResponse['tipoCarga']              := (cAliasCabecalho)->CJ_YTPCARG
    jResponse['valorDescarga']          := (cAliasCabecalho)->CJ_YVDESCA
    jResponse['cargaMaxima']            := (cAliasCabecalho)->CJ_YCARMAX
    jResponse['paletizacao10x1']        := (cAliasCabecalho)->CJ_YPP10X1
    jResponse['paletizacao30x1']        := (cAliasCabecalho)->CJ_YPP30X1
    jResponse['paletizacao25kg']        := (cAliasCabecalho)->CJ_YPP25KG
    jResponse['tipoVeiculo']            := (cAliasCabecalho)->CJ_YTPVEIC
    jResponse['responsavelFrete']       := (cAliasCabecalho)->CJ_YRESPFR == "T"
    jResponse['estadoDestino']          := (cAliasCabecalho)->CJ_YUFDEST
    jResponse['cidadeDestino']          := (cAliasCabecalho)->CJ_YMUNDES
    jResponse['descontoFinanceiro']     := (cAliasCabecalho)->CJ_YDESCF
    jResponse['tipoDescarga']           := (cAliasCabecalho)->CJ_YDESCAR
    jResponse['veiculoProprio']         := iif( (cAliasCabecalho)->CJ_YVEIPRO == "S", .T., .F. )
    jResponse['devolucaoPalete']        := (cAliasCabecalho)->CJ_YDEVPAL == "S"
    jResponse['icmsPautaFrete']         := Posicione("SA1",1,xFilial("SA1")+cCliLoja,"A1_XVLRFRT") / 2 * (U_DefPort("ICMSPAUTFR",12)/100)
    jResponse['itens']                  := {}

    MPSysOpenQuery(aQuery[2],cAliasItens)

    dbSelectArea(cAliasItens)
    (cAliasItens)->(dbGoTop())
    
    while !(cAliasItens)->(eof())

        jItem := JsonObject():New()

        jItem['item']               := (cAliasItens)->CK_ITEM
        jItem['produto']            := (cAliasItens)->CK_PRODUTO
        jItem['descProduto']        := posicione("SB1",1,xFilial("SB1") + (cAliasItens)->CK_PRODUTO,"B1_DESC")
        jItem['quantidade']         := (cAliasItens)->CK_QTDVEN
        jItem['embalagem']          := (cAliasItens)->CK_UM
        jItem['precoFOB']           := (cAliasItens)->CK_YBASFOB
        jItem['valorUnitario']      := (cAliasItens)->CK_PRCVEN
        jItem['valorTotal']         := (cAliasItens)->CK_VALOR
        jItem['comissao']           := (cAliasItens)->CK_COMIS1
        jItem['tes']                := (cAliasItens)->CK_TES
        jItem['pesoNeto']           := posicione("SB1",1,xFilial("SB1")+(cAliasItens)->CK_PRODUTO,"B1_PESO")
        jItem['pesoBruto']          := posicione("SB1",1,xFilial("SB1")+(cAliasItens)->CK_PRODUTO,"B1_PESBRU")
        jItem['formatoEmbalagem']   := posicione("SB1",1,xFilial("SB1")+(cAliasItens)->CK_PRODUTO,"B1_YFORMAT")

        aAdd(jResponse['itens'],jItem)
        
        (cAliasItens)->(dbSkip())

    enddo

    self:setResponse(jResponse:toJson())

    (cAliasCabecalho)->(DbCloseArea())
    (cAliasItens)->(DbCloseArea())

Return lRet


WsMethod Post OrcIn WsService orcamentos

    local jResponse         := JsonObject():new()       as json
    local jBody             := JsonObject():new()       as json
    local cBody             := self:getContent()        as character
    local aCabecalho        := {}                       as array
    local aItens            := {}                       as array
    local lRet              := .T.

    Private lMsErroAuto       := .F.                      as logical

    jBody:fromJson(cBody)

    aCabecalho := arrayCabecalho(jBody)
    aItens     := arrayItens(jBody)
    
    if !empty(aCabecalho)

        begin transaction

            mata415(aCabecalho,aItens,3)

        end transaction

        if !lMsErroAuto

            jResponse["success"]    := .T.
            jResponse["message"]    := "Orçamento " + SCK->CK_NUM + " incluído com sucesso."
            jResponse["filial"]     := SCK->CK_FILIAL
            jResponse["orcamento"]  := SCK->CK_NUM

        else

            lRet := .F.

            jResponse["success"]    := .F.
            jResponse["message"]    := "Erro na inclusão do orçamento."
            jResponse["fix"]        := "Erro na rotina automática: " + MemoRead(Alltrim(NomeAutoLog()))
        
        endif
    
    else

        lRet := .F.

        jResponse["success"]    := .F.
        jResponse["message"]    := "Erro na inclusão do orçamento."
        jResponse["fix"]        := "Cabeçalho não informados no body da requisição."

    endif

    self:setResponse(jResponse:toJson())

Return lRet


WsMethod Put OrcUp WsService orcamentos

    local jResponse         := JsonObject():new()       as json
    local jBody             := JsonObject():new()       as json
    local cBody             := self:getContent()        as character
    local aCabecalho        := {}                       as array
    local aItens            := {}                       as array
    local lRet              := .T.

    Private lMsErroAuto       := .F.                      as logical

    jBody:fromJson(cBody)

    aCabecalho := arrayCabecalho(jBody)
    aItens     := arrayItens(jBody)

    if !empty(aCabecalho)

        begin transaction

            mata415(aCabecalho,aItens,4)

        end transaction

        if !lMsErroAuto

            jResponse["success"]    := .T.
            jResponse["message"]    := "Orçamento " + SCK->CK_NUM + " atualizado com sucesso."
            jResponse["filial"]     := SCK->CK_FILIAL
            jResponse["orcamento"]  := SCK->CK_NUM

        else

            lRet = .F.

            jResponse["success"]    := .F.
            jResponse["message"]    := "Erro na alteração do orçamento."
            jResponse["fix"]        := "Erro na rotina automática: " + MemoRead(Alltrim(NomeAutoLog()))
        
        endif
    
    else

        lRet = .F.

        jResponse["success"]    := .F.
        jResponse["message"]    := "Erro na alteração do orçamento."
        jResponse["fix"]        := "Cabeçalho não informados no body da requisição."

    endif

    self:setResponse(jResponse:toJson())

return lRet


WsMethod Post Indic WsService orcamentos

    local jResponse         := JsonObject():new()       as json
    local jItem             := JsonObject():new()       as json
    local jBody             := JsonObject():new()       as json
    local cBody             := self:getContent()        as character
    local cVendedor         := ""                       as character
    local aIndicadores      := {}                       as array
    local jIndicador        := JsonObject():new()       as json
    local nPos              := 0                        as numeric
    local cAlias            := ""                       as character
    local cQuery            := ""                       as character
    local cFiltro           := ""                       as character
    local lRet              := .T.

    cBody := oRest:getBodyRequest()
    
    jBody:fromJson(cBody)

    cVendedor := jBody:getJsonObject('vendedor')
    aIndicadores := jBody:getJsonObject('indicadores')

    jResponse['indicadores'] := {}
    jResponse['success'] := .T.

    for nPos := 1 to Len(aIndicadores)

        jIndicador := aIndicadores[nPos]

        cAlias := getNextAlias()
        cFiltro := jIndicador:getJsonObject('filtro')
        cQuery := qryIndicadores(cVendedor,cFiltro)

        MPSysOpenQuery(cQuery,cAlias)

        dbSelectArea(cAlias)
        (cAlias)->(dbGoTop())

        if !(cAlias)->(eof())

            jItem := JsonObject():new()

            jItem['success']    := .T.
            jItem['indicador']  := jIndicador:getJsonObject('ordem')
            jItem['descricao']  := jIndicador:getJsonObject('descricao')
            jItem['filtro']     := cFiltro
            jItem['quantidade'] := (cAlias)->TOTAL

            aAdd(jResponse['indicadores'],jItem)

        else

            jItem := JsonObject():new()

            jItem["success"]    := .F.
            jItem["message"]    := "Indicador não encontrado."
            jItem["fix"]        := "Verifique o filtro do indicador."

            aAdd(jResponse['indicadores'],jItem)

            jResponse['success'] := .F.

        endif

        (cAlias)->(DbCloseArea())

    next

    self:setResponse(jResponse:toJson())

return lRet


WsMethod Put ApCot WsService orcamentos

    local jResponse         := JsonObject():new()       as json
    local jBody             := JsonObject():new()       as json
    local cBody             := self:getContent()        as character
    local cFilialOrc        := ""                       as character
    local cOrcamento        := ""                       as character
    local cTamCampoOrc      := 6                        as numeric
    local aArea             := GetArea()                as array
    local lRet              := .T.

    jBody:fromJson(cBody)

    cFilialOrc := jBody:getJsonObject('filial')
    cOrcamento := jBody:getJsonObject('orcamento')

    cTamCampoOrc := tamSX3("CJ_NUM")[1]

    dbSelectArea("SCJ")
    SCJ->(dbSetOrder(1))
    SCJ->(dbGoTop())

    If SCJ->(dbSeek(cFilialOrc+PadR(cOrcamento,cTamCampoOrc," "))) .And. SCJ->CJ_YPRSITU == "CP"

        If recLock("SCJ",.F.)

            SCJ->CJ_YPRSITU := "PE"
            SCJ->CJ_YDTALTE := date()
            SCJ->(msUnlock())

            jResponse["success"]    := .T.
            jResponse["message"]    := "Cotação " + cOrcamento + " aprovada com sucesso."

        Else

            lRet := .F.

            jResponse["success"]    := .F.
            jResponse["message"]    := "Erro ao aprovar a cotação."
            jResponse["fix"]        := "Não foi possível aprovar a cotação, tente novamente mais tarde."

        EndIf

    else

        lRet := .F.

        jResponse["success"]    := .F.
        jResponse["message"]    := "Cotação não encontrada."
        jResponse["fix"]        := "Verifique os dados informados."

    endif
    
    self:setResponse(jResponse:toJson())

    RestArea(aArea)

return lRet


WsMethod Put RjCot WsService orcamentos

    local jResponse         := JsonObject():new()       as json
    local jBody             := JsonObject():new()       as json
    local cBody             := self:getContent()        as character
    local cFilialOrc        := ""                       as character
    local cOrcamento        := ""                       as character
    local cTamCampoOrc      := 6                        as numeric
    local aArea             := GetArea()                as array
    local lRet              := .T.

    jBody:fromJson(cBody)

    cFilialOrc := jBody:getJsonObject('filial')
    cOrcamento := jBody:getJsonObject('orcamento')

    cTamCampoOrc := tamSX3("CJ_NUM")[1]

    dbSelectArea("SCJ")
    SCJ->(dbSetOrder(1))
    SCJ->(dbGoTop())

    If SCJ->(dbSeek(cFilialOrc+PadR(cOrcamento,cTamCampoOrc," "))) .And. SCJ->CJ_YPRSITU == "CP"

        If recLock("SCJ",.F.)

            SCJ->CJ_YPRSITU := "CR"
            SCJ->CJ_YDTALTE := date()
            SCJ->(msUnlock())

            jResponse["success"]    := .T.
            jResponse["message"]    := "Cotação " + cOrcamento + " rejeitada com sucesso."

        Else

            lRet := .F.

            jResponse["success"]    := .F.
            jResponse["message"]    := "Erro ao rejeitar a cotação."
            jResponse["fix"]        := "Não foi possível rejeitar a cotação, tente novamente mais tarde."

        EndIf

    else

        lRet := .F.

        jResponse["success"]    := .F.
        jResponse["message"]    := "Cotação não encontrada."
        jResponse["fix"]        := "Verifique os dados informados."

    endif
    
    self:setResponse(jResponse:toJson())

    RestArea(aArea)

return lRet


WsMethod Put ApPPd WsService orcamentos

    local jResponse         := JsonObject():new()       as json
    local jBody             := JsonObject():new()       as json
    local cBody             := self:getContent()        as character
    local cFilialOrc        := ""                       as character
    local cOrcamento        := ""                       as character
    local cTamCampoOrc      := 6                        as numeric
    local aArea             := GetArea()                as array
    local lRet              := .T.

    jBody:fromJson(cBody)

    cFilialOrc := jBody:getJsonObject('filial')
    cOrcamento := jBody:getJsonObject('orcamento')

    cTamCampoOrc := tamSX3("CJ_NUM")[1]

    dbSelectArea("SCJ")
    SCJ->(dbSetOrder(1))
    SCJ->(dbGoTop())

    If SCJ->(dbSeek(cFilialOrc+PadR(cOrcamento,cTamCampoOrc," "))) .And. SCJ->CJ_YPRSITU == "PP"

        If recLock("SCJ",.F.)

            SCJ->CJ_YPRSITU := "AP"
            SCJ->CJ_YDTALTE := date()
            SCJ->(msUnlock())

            jResponse["success"]    := .T.
            jResponse["message"]    := "Pré Pedido " + cOrcamento + " enviado para aprovação com sucesso."

        Else

            lRet = .F.

            jResponse["success"]    := .F.
            jResponse["message"]    := "Erro ao enviar o Pré Pedido para aprovação."
            jResponse["fix"]        := "Não foi possível enviar o Pré Pedido, tente novamente mais tarde."

        EndIf

    else

        lRet = .F.

        jResponse["success"]    := .F.
        jResponse["message"]    := "Pré Pedido não encontrado."
        jResponse["fix"]        := "Verifique os dados informados."

    endif
    
    self:setResponse(jResponse:toJson())

    RestArea(aArea)

return lRet


static function qryBrowse(cPagina, cVendedor, cFiltro)

    local cQuery := ""
    //local cTamPagina := "20"

    cQuery += " SELECT *
    cQuery += " FROM " + retSQLName("SCJ") + " SCJ
    cQuery += " LEFT JOIN " + retSQLName("SC5") + " SC5 ON C5_FILIAL = CJ_FILIAL AND C5_YNUMORC = CJ_NUM AND SC5.D_E_L_E_T_ = ' '
    cQuery += " WHERE SCJ.D_E_L_E_T_ = ' '
    if Posicione("SA3",1,xFilial("SA3")+cVendedor,"A3_TIPO") != "I"
        cQuery += " AND CJ_YVEND = '"+cVendedor+"'
    endif
    if !empty(cFiltro)
        cQuery += " AND " + cFiltro
    endif
    cQuery += " ORDER BY CJ_FILIAL,CJ_NUM
    //cQuery += " OFFSET ("+cPagina+" - 1) * "+cTamPagina+" ROWS
    //cQuery += " FETCH NEXT "+cTamPagina+" ROWS ONLY;

return cQuery


static function qryIndicadores(cVendedor,cFiltro)

    local cQuery := ""

    cQuery += " SELECT COUNT(*) AS TOTAL
    cQuery += " FROM " + retSQLName("SCJ") + " SCJ
    cQuery += " LEFT JOIN " + retSQLName("SC5") + " SC5 ON C5_FILIAL = CJ_FILIAL AND C5_YNUMORC = CJ_NUM AND SC5.D_E_L_E_T_ = ' '
    cQuery += " WHERE SCJ.D_E_L_E_T_ = ' '
    if Posicione("SA3",1,xFilial("SA3")+cVendedor,"A3_TIPO") != "I"
        cQuery += " AND CJ_YVEND = '"+cVendedor+"'
    endif
    if !empty(cFiltro)
        cQuery += " AND " + cFiltro
    endif

return cQuery


static function qryDados(cFilialOrc, cOrcamento)

    local cQueryCabecalho   := ""   as character
    local cQueryItens       := ""   as character
    
    cQueryCabecalho += " SELECT TOP 1 *
    cQueryCabecalho += " FROM " + retSQLName("SCJ")
    cQueryCabecalho += " WHERE D_E_L_E_T_ = ' ' AND CJ_FILIAL = '"+cFilialOrc+"' AND CJ_NUM = '"+cOrcamento+"'

    cQueryItens     += " SELECT *
    cQueryItens     += " FROM " + retSQLName("SCK")
    cQueryItens     += " WHERE D_E_L_E_T_ = ' ' AND CK_FILIAL = '"+cFilialOrc+"' AND CK_NUM = '"+cOrcamento+"'

return {cQueryCabecalho,cQueryItens}


static function arrayCabecalho(jBody as json) as array

    local aCabecalho        := {} as array
    local nDiasVencimento   := U_DefPort("VENCORCAME",7)

    iif( !empty(jBody:getJsonObject('filial')),                 aAdd( aCabecalho, { "CJ_FILIAL",    jBody:getJsonObject('filial'),              nil } ) , nil )
    iif( !empty(jBody:getJsonObject('unidadeCarregamento')),    aAdd( aCabecalho, { "CJ_YUNCARG",   jBody:getJsonObject('unidadeCarregamento'), nil } ) , nil )
    iif( !empty(jBody:getJsonObject('orcamento')),              aAdd( aCabecalho, { "CJ_NUM",       jBody:getJsonObject('orcamento'),           nil } ) , nil )
    iif( !empty(jBody:getJsonObject('cliente')),                aAdd( aCabecalho, { "CJ_CLIENTE",   jBody:getJsonObject('cliente'),             nil } ) , nil )
    iif( !empty(jBody:getJsonObject('lojaCliente')),            aAdd( aCabecalho, { "CJ_LOJA",      jBody:getJsonObject('lojaCliente'),         nil } ) , nil )
    iif( !empty(jBody:getJsonObject('condPag')),                aAdd( aCabecalho, { "CJ_CONDPAG",   jBody:getJsonObject('condPag'),             nil } ) , nil )
    iif( !empty(jBody:getJsonObject('vendedor')),               aAdd( aCabecalho, { "CJ_YVEND",     jBody:getJsonObject('vendedor'),            nil } ) , nil )
    iif( !empty(jBody:getJsonObject('situacao')),               aAdd( aCabecalho, { "CJ_YPRSITU",   jBody:getJsonObject('situacao'),            nil } ) , nil )
    iif( !empty(jBody:getJsonObject('observacao')),             aAdd( aCabecalho, { "CJ_YOBS",      jBody:getJsonObject('observacao'),          nil } ) , nil )
    iif( !empty(jBody:getJsonObject('condPagFrete')),           aAdd( aCabecalho, { "CJ_YCPAGFR",   jBody:getJsonObject('condPagFrete'),        nil } ) , nil )
    iif( !empty(jBody:getJsonObject('valorFrete')),             aAdd( aCabecalho, { "CJ_FRETE",     jBody:getJsonObject('valorFrete'),          nil } ) , nil )
    iif( !empty(jBody:getJsonObject('tipoCarga')),              aAdd( aCabecalho, { "CJ_YTPCARG",   jBody:getJsonObject('tipoCarga'),           nil } ) , nil )
    iif( !empty(jBody:getJsonObject('valorDescarga')),          aAdd( aCabecalho, { "CJ_YVDESCA",   jBody:getJsonObject('valorDescarga'),       nil } ) , nil )
    iif( !empty(jBody:getJsonObject('tipoFrete')),              aAdd( aCabecalho, { "CJ_TPFRETE",   jBody:getJsonObject('tipoFrete'),           nil } ) , nil )
    iif( !empty(jBody:getJsonObject('cargaMaxima')),            aAdd( aCabecalho, { "CJ_YCARMAX",   jBody:getJsonObject('cargaMaxima'),         nil } ) , nil )
    iif( !empty(jBody:getJsonObject('paletizacao10x1')),        aAdd( aCabecalho, { "CJ_YPP10X1",   jBody:getJsonObject('paletizacao10x1'),     nil } ) , nil )
    iif( !empty(jBody:getJsonObject('paletizacao30x1')),        aAdd( aCabecalho, { "CJ_YPP30X1",   jBody:getJsonObject('paletizacao30x1'),     nil } ) , nil )
    iif( !empty(jBody:getJsonObject('paletizacao25kg')),        aAdd( aCabecalho, { "CJ_YPP25KG",   jBody:getJsonObject('paletizacao25kg'),     nil } ) , nil )
    iif( !empty(jBody:getJsonObject('tipoVeiculo')),            aAdd( aCabecalho, { "CJ_YTPVEIC",   jBody:getJsonObject('tipoVeiculo'),         nil } ) , nil )
    iif( !empty(jBody:getJsonObject('estadoDestino')),          aAdd( aCabecalho, { "CJ_YUFDEST",   jBody:getJsonObject('estadoDestino'),       nil } ) , nil )
    iif( !empty(jBody:getJsonObject('cidadeDestino')),          aAdd( aCabecalho, { "CJ_YMUNDES",   jBody:getJsonObject('cidadeDestino'),       nil } ) , nil )
    iif( !empty(jBody:getJsonObject('custoSobrepeso')),         aAdd( aCabecalho, { "CJ_YSBPORT",   jBody:getJsonObject('custoSobrepeso'),      nil } ) , nil )
    iif( !empty(jBody:getJsonObject('descontoFinanceiro')),     aAdd( aCabecalho, { "CJ_YDESCF",    jBody:getJsonObject('descontoFinanceiro'),  nil } ) , nil )
    iif( !empty(jBody:getJsonObject('tipoDescarga')),           aAdd( aCabecalho, { "CJ_YDESCAR",   jBody:getJsonObject('tipoDescarga'),        nil } ) , nil )
    iif( !empty(jBody:getJsonObject('veiculoProprio')),         aAdd( aCabecalho, { "CJ_YVEIPRO",   jBody:getJsonObject('veiculoProprio'),      nil } ) , nil )
    iif( !empty(jBody:getJsonObject('devolucaoPalete')),        aAdd( aCabecalho, { "CJ_YDEVPAL",   jBody:getJsonObject('devolucaoPalete'),     nil } ) , nil )
    iif( !empty(jBody:getJsonObject('responsavelFrete')),       aAdd( aCabecalho, { "CJ_YRESPFR",   jBody:getJsonObject('responsavelFrete')=="1",   nil } ) , nil )
    
    aAdd(aCabecalho, { "CJ_YDTALTE",    date(),                 nil })
    aAdd(aCabecalho, { "CJ_VALIDA",     date()+nDiasVencimento, nil })

return aCabecalho


static function arrayItens(jBody as json) as array

    local aItens        := {}                  as array
    local jItem         := JsonObject():new()  as json
    local aLinha        := {}                  as array
    local nPos          := 0                   as numeric
    local aItensJson    := {}              as array

    iif( !empty(jBody:getJsonObject('itens')), aItensJson := jBody:getJsonObject('itens'), nil)

    for nPos := 1 To len(aItensJson)

        jItem := aItensJson[nPos]

        aLinha := {}

        iif( !empty(jBody:getJsonObject('filial')),         aAdd( aLinha, { "CK_FILIAL",    jBody:getJsonObject('filial'),          nil } ) , nil )
        iif( !empty(jItem:getJsonObject('item')),           aAdd( aLinha, { "CK_ITEM",      jItem:getJsonObject('item'),            nil } ) , nil )
        iif( !empty(jItem:getJsonObject('produto')),        aAdd( aLinha, { "CK_PRODUTO",   jItem:getJsonObject('produto'),         nil } ) , nil )
        iif( !empty(jItem:getJsonObject('quantidade')),     aAdd( aLinha, { "CK_QTDVEN",    jItem:getJsonObject('quantidade'),      nil } ) , nil )
        iif( !empty(jItem:getJsonObject('precoFOB')),       aAdd( aLinha, { "CK_YBASFOB",   jItem:getJsonObject('precoFOB'),        nil } ) , nil )
        iif( !empty(jItem:getJsonObject('precoUnitario')),  aAdd( aLinha, { "CK_PRCVEN",    jItem:getJsonObject('precoUnitario'),   nil } ) , nil )
        iif( !empty(jItem:getJsonObject('comissao')),       aAdd( aLinha, { "CK_COMIS1",    jItem:getJsonObject('comissao'),        nil } ) , nil )
        iif( !empty(jItem:getJsonObject('tes')),            aAdd( aLinha, { "CK_TES",       jItem:getJsonObject('tes'),             nil } ) , aAdd( aLinha, { "CK_TES",       AllTrim(GetMV("MS_PRTESPD")),             nil } ) )
        iif( !empty(jBody:getJsonObject('cliente')),        aAdd( aLinha, { "CK_CLIENTE",   jBody:getJsonObject('cliente'),         nil } ) , nil )
        iif( !empty(jBody:getJsonObject('loja')),           aAdd( aLinha, { "CK_LOJA",      jBody:getJsonObject('loja'),            nil } ) , nil )

        aAdd(aItens,aLinha)

    next


return aItens

#include 'Protheus.ch'
#include 'Restful.ch'

WsRestful produtos Description "Produtos"

    WsData page         AS Character
    WsData pageSize     AS Character
    WsData filter       AS Character
    WsData location     AS Character

    WsMethod Get Prods   Description "Retorna os produtos disponíveis"  Path "/"
    WsMethod Get Prod    Description "Retorna um produto específico"    Path "/{codigo}"

End WsRestful


WsMethod Get Prods WsService produtos

    local jResponse     := JsonObject():New()       as json
    local cQuery        := ""                       as character
    local cAlias        := ""                       as character
    local cFiltro       := ""                       as character
    local cPagina       := ""                       as character
    local cTamPagina    := ""                       as character
    local cUndCarreg    := ""                       as character
    local nContador     := 0                        as numeric
    local jItem                                     as json
    local lRet          := .T.

    default self:page       := "1"
    default self:pageSize   := "10"
    default self:filter     := ""
    default self:location   := "SS"

    cPagina     := self:page
    cTamPagina  := self:pageSize
    cFiltro     := self:filter
    cUndCarreg  := self:location
    
    cQuery := getQueryProdutos(cFiltro,cPagina,cTamPagina,cUndCarreg)

    cAlias := getNextAlias()

    MPSysOpenQuery(cQuery,cAlias)

    dbSelectArea(cAlias)
    (cAlias)->(dbGoTop())

    jResponse['items'] = {}

    nContador := 0

    while !(cAlias)->(eof()) .and. iif(!empty(cTamPagina),nContador < val(cTamPagina),.T.)

        jItem := JsonObject():New()

        jItem['codigo']             := allTrim((cAlias)->B1_COD)
        jItem['descricao']          := allTrim((cAlias)->B1_DESC)
        jItem['unidade']            := (cAlias)->B1_UM
        jItem['tipo']               := (cAlias)->B1_TIPO
        jItem['formatoEmbalagem']   := (cAlias)->B1_YFORMAT
        jItem['pesoNeto']           := (cAlias)->B1_PESO
        jItem['pesoBruto']          := (cAlias)->B1_PESBRU
        jItem['tipoSal']            := (cAlias)->B1_YTPSAL
        jItem['marca']              := allTrim((cAlias)->B1_YMARCA)

        aAdd(jResponse['items'],jItem)

        (cAlias)->(dbSkip())

        nContador++

    enddo

    jResponse['hasNext'] = !(cAlias)->(eof())

    self:setResponse(jResponse:toJson())

    (cAlias)->(DbCloseArea())

Return lRet


WsMethod Get Prod WsService produtos

    local jResponse         := JsonObject():New()       as json
    local aAreaSB1          := {}                       as array
    local cCodigoProduto    := ""                       as character
    local lRet              := .T.
    
    cCodigoProduto  := self:aUrlParms[len(self:aUrlParms)]

    dbSelectArea("SB1")
    aAreaSB1 := SB1->(GetArea())
    SB1->(dbSetOrder(1))
    SB1->(dbGoTop())

    if SB1->(dbSeek(xFilial("SB1")+cCodigoProduto))

        jResponse['success']            := .T.
        jResponse['codigo']             := allTrim(SB1->B1_COD)
        jResponse['descricao']          := allTrim(SB1->B1_DESC)
        jResponse['unidade']            := SB1->B1_UM
        jResponse['tipo']               := SB1->B1_TIPO
        jResponse['formatoEmbalagem']   := SB1->B1_YFORMAT
        jResponse['pesoNeto']           := SB1->B1_PESO
        jResponse['pesoBruto']          := SB1->B1_PESBRU
        jResponse['tipoSal']            := SB1->B1_YTPSAL
        jResponse['marca']              := allTrim(SB1->B1_YMARCA)

    else

        lRet := .F.

        jResponse["success"]    := .F.
        jResponse["message"]    := "Produto não encontrado"
        jResponse["fix"]        := "Revise o código do produto e tente novamente"
        
    endif

    self:setResponse(jResponse:toJson())

    restArea(aAreaSB1)

return lRet


static function getQueryProdutos(cFiltro,cPagina,cTamPagina,cUndCarreg)

    local cQuery        := ""

    cQuery += " SELECT DISTINCT SB1.*
    cQuery += " FROM " + retSQLName("SB1") + " SB1
    cQuery += " WHERE D_E_L_E_T_ = ' ' AND B1_MSBLQL != '1'
    cQuery += " AND B1_COD IN (SELECT DISTINCT DA1_CODPRO FROM " + retSQLName("DA1") + " DA1
    cQuery += " INNER JOIN " + retSQLName("DA0") + " DA0 ON DA0.D_E_L_E_T_ = ' ' AND DA0_FILIAL = DA1_FILIAL AND DA0_CODTAB = DA1_CODTAB
    cQuery += " WHERE DA1.D_E_L_E_T_ = ' ' AND DA0_YPOREP = 'S' AND DA0_YUNCAR = '" + cUndCarreg + "')

    if !empty(cFiltro)
        cQuery += " AND (B1_COD LIKE '%" + upper(cFiltro) + "%' OR B1_DESC LIKE '%" + upper(cFiltro) + "%' OR B1_YMARCA LIKE '%" + upper(cFiltro) + "%')
    endif

    cQuery += " ORDER BY R_E_C_N_O_

    if !empty(cPagina) .and. !empty(cTamPagina)
        cQuery += " OFFSET ("+cPagina+" - 1) * "+cTamPagina+" ROWS
        cQuery += " FETCH NEXT "+str(val(cTamPagina)+1)+" ROWS ONLY
    endif

return cQuery

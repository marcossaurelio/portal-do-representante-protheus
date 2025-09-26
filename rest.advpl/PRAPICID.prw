#include 'Protheus.ch'
#include 'Restful.ch'

WsRestful cidades Description "Cidades"

    WsData page         AS Character
    WsData pageSize     AS Character
    WsData filter       AS Character
    WsData state        AS Character

    WsMethod Get Cids   Description "Retorna as cidades do estado"          Path "/"
    WsMethod Get Cid    Description "Retorna uma cidade específica"         Path "/{codigo}"

End WsRestful


WsMethod Get Cids WsService cidades

    local jResponse     := JsonObject():New()       as json
    local cQuery        := ""                       as character
    local cAlias        := ""                       as character
    local cFiltro       := ""                       as character
    local cPagina       := ""                       as character
    local cTamPagina    := ""                       as character
    local nContador     := 0                        as numeric
    local cEstado       := ""                       as character
    local jItem                                     as json
    local lRet          := .T.

    default self:page       := "1"
    default self:pageSize   := "10"
    default self:filter     := ""
    default self:state      := ""

    cPagina     := self:page
    cTamPagina  := self:pageSize
    cFiltro     := self:filter
    cEstado     := self:state
    
    cQuery := getQueryCidades(cFiltro,cPagina,cTamPagina,cEstado)

    cAlias := getNextAlias()

    MPSysOpenQuery(cQuery,cAlias)

    dbSelectArea(cAlias)
    (cAlias)->(dbGoTop())

    jResponse['items'] = {}

    nContador := 0

    while !(cAlias)->(eof()) .and. iif(!empty(cTamPagina),nContador < val(cTamPagina),.T.)

        jItem := JsonObject():New()

        jItem['success']    := .T.
        jItem['codigo']     := (cAlias)->CC2_CODMUN
        jItem['cidade']     := allTrim((cAlias)->CC2_MUN)
        jItem['estado']     := (cAlias)->CC2_EST

        aAdd(jResponse['items'],jItem)

        (cAlias)->(dbSkip())

        nContador++

    enddo

    jResponse['hasNext'] = !(cAlias)->(eof())

    self:setResponse(jResponse:toJson())

    (cAlias)->(DbCloseArea())

Return lRet


WsMethod Get Cid WsService cidades

    local jResponse         := JsonObject():New()       as json
    local aAreaCC2          := {}                       as array
    local cCodigoCidade     := ""                       as character
    local nTamCampo         := 0                        as numeric
    local lRet              := .T.
    
    cCodigoCidade  := self:aUrlParms[len(self:aUrlParms)]

    dbSelectArea("CC2")
    aAreaCC2 := CC2->(GetArea())

    CC2->(dbSetOrder(1))
    CC2->(dbGoTop())

    nTamCampo := tamSX3("CC2_EST")[1] + tamSX3("CC2_CODMUN")[1] // Tamanho do campo A1_COD

    if CC2->(dbSeek(xFilial("CC2")+padL(cCodigoCidade, nTamCampo, " ")))

        jResponse['success']    := .T.
        jResponse['codigo']     := CC2->CC2_CODMUN
        jResponse['cidade']     := allTrim(CC2->CC2_MUN)
        jResponse['estado']     := CC2->CC2_EST

    else

        jResponse['success']    := .F.
        jResponse["message"]    := "Cidade não encontrada"
        jResponse["fix"]        := "Informe um código de cidade válido para o estado de destino."
        jResponse['codigo']     := ""
        jResponse['cidade']     := ""
        jResponse['estado']     := ""
        
    endif

    self:setResponse(jResponse:toJson())

    restArea(aAreaCC2)

return lRet


static function getQueryCidades(cFiltro,cPagina,cTamPagina,cEstado)

    local cQuery        := ""

    cQuery += " SELECT *
    cQuery += " FROM " + retSQLName("CC2")
    cQuery += " WHERE D_E_L_E_T_ = ' ' AND CC2_EST = '" + cEstado + "'

    if !empty(cFiltro)
        cQuery += " AND (CC2_CODMUN LIKE '%" + upper(cFiltro) + "%' OR CC2_MUN LIKE '%" + upper(cFiltro) + "%')
    endif

    cQuery += " ORDER BY CC2_MUN

    if !empty(cPagina) .and. !empty(cTamPagina)
        cQuery += " OFFSET ("+cPagina+" - 1) * "+cTamPagina+" ROWS
        cQuery += " FETCH NEXT "+cValToChar(val(cTamPagina)+1)+" ROWS ONLY
    endif


return cQuery

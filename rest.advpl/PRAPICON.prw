#include 'Protheus.ch'
#include 'Restful.ch'

WsRestful condicoes Description "Condicoes de pagamento"

    WsData page     AS Character
    WsData pageSize AS Character
    WsData filter   AS Character

    WsMethod Get Conds   Description "Retorna as condições de pagamento" Path "/"
    WsMethod Get Cond    Description "Retorna uma condição de pagamento específica" Path "/{codigo}"

End WsRestful


WsMethod Get Conds WsService condicoes

    local jResponse     := JsonObject():New()       as json
    local cQuery        := ""                       as character
    local cAlias        := ""                       as character
    local cFiltro       := ""                       as character
    local cPagina       := ""                       as character
    local cTamPagina    := ""                       as character
    local nContador     := 0                        as numeric
    local jItem                                     as json
    local lRet          := .T.

    default self:page       := "1"
    default self:pageSize   := "10"
    default self:filter     := ""

    cPagina     := self:page
    cTamPagina  := self:pageSize
    cFiltro     := self:filter
    
    cQuery := getQueryCondicoes(cFiltro,cPagina,cTamPagina)

    cAlias := getNextAlias()

    MPSysOpenQuery(cQuery,cAlias)

    dbSelectArea(cAlias)
    (cAlias)->(dbGoTop())

    jResponse['items'] = {}

    nContador := 0

    while !(cAlias)->(eof()) .and. iif(!empty(cTamPagina),nContador < val(cTamPagina),.T.)

        jItem := JsonObject():New()

        jItem['codigo']         := (cAlias)->E4_CODIGO
        jItem['descricao']      := allTrim((cAlias)->E4_DESCRI)

        aAdd(jResponse['items'],jItem)

        (cAlias)->(dbSkip())

        nContador++

    enddo

    jResponse['hasNext'] = !(cAlias)->(eof())

    self:setContentType('application/json')
    self:setResponse(jResponse:toJson())

    (cAlias)->(DbCloseArea())

Return lRet


WsMethod Get Cond WsService condicoes

    local jResponse         := JsonObject():New()       as json
    local aAreaSE4          := {}                       as array
    local cCodCond          := ""                       as character
    local cFiltro           := ""                       as character
    local lRet              := .T.
    
    aAreaSE4 := SE4->(getArea())

    cCodCond  := self:aUrlParms[1]

    aAreaSE4 := SE4->(GetArea())
    cFiltro := "SE4->E4_YPRUSAD == 'S' .and. SE4->E4_MSBLQL != '1'"
    
    dbSelectArea("SE4")
    SE4->(dbSetFilter( {|| &(cFiltro)}, cFiltro ))
    SE4->(dbSetOrder(1))
    SE4->(dbGoTop())

    if SE4->(dbSeek(xFilial("SE4")+cCodCond, .T.))

        jResponse['success']        := lRet
        jResponse['message']        := "Condição de pagamento encontrada com sucesso"
        jResponse['codigo']         := SE4->E4_CODIGO
        jResponse['descricao']      := allTrim(SE4->E4_DESCRI)

    else

        lRet = .F.

        jResponse['success']        := lRet
        jResponse["message"]        := "Condição de pagamento não encontrada na base de dados"
        
    endif

    self:setContentType('application/json')
    self:setResponse(jResponse:toJson())

    SE4->(dbClearFilter())
    restArea(aAreaSE4)

return lRet


static function getQueryCondicoes(cFiltro,cPagina,cTamPagina)

    local cQuery        := ""

    cQuery += " SELECT *
    cQuery += " FROM " + retSQLName("SE4")
    cQuery += " WHERE D_E_L_E_T_ = ' ' AND E4_MSBLQL != '1' AND E4_YPRUSAD = 'S'

    if !empty(cFiltro)
        cQuery += " AND (E4_DESCRI LIKE '%" + upper(cFiltro) + "%')
    endif

    cQuery += " ORDER BY E4_COND

    if !empty(cPagina) .and. !empty(cTamPagina)
        cQuery += " OFFSET ("+cPagina+" - 1) * "+cTamPagina+" ROWS
        cQuery += " FETCH NEXT "+str(val(cTamPagina)+1)+" ROWS ONLY
    endif


return cQuery

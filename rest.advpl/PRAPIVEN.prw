#include 'Protheus.ch'
#include 'Restful.ch'

WsRestful vendedores Description "Vendedores"

    WsData page     AS Character
    WsData pageSize AS Character
    WsData filter   AS Character

    WsMethod Get Vends   Description "Retorna a lista de vendedores" Path "/"
    WsMethod Get Vend    Description "Retorna um vendedor específico" Path "/{codigo}"

End WsRestful


WsMethod Get Vends WsService vendedores

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
    
    cQuery := getQueryVendedores(cFiltro,cPagina,cTamPagina)

    cAlias := getNextAlias()

    MPSysOpenQuery(cQuery,cAlias)

    dbSelectArea(cAlias)
    (cAlias)->(dbGoTop())

    jResponse['items'] = {}

    nContador := 0

    while !(cAlias)->(eof()) .and. iif(!empty(cTamPagina),nContador < val(cTamPagina),.T.)

        jItem := JsonObject():New()

        jItem['codigo']         := (cAlias)->A3_COD
        jItem['cgc']            := allTrim((cAlias)->A3_CGC)
        jItem['nome']           := allTrim((cAlias)->A3_NREDUZ)
        jItem['tipo']           := allTrim((cAlias)->A3_TIPO)

        aAdd(jResponse['items'],jItem)

        (cAlias)->(dbSkip())

        nContador++

    enddo

    jResponse['hasNext'] = !(cAlias)->(eof())

    self:setContentType('application/json')
    self:setResponse(jResponse:toJson())

    (cAlias)->(DbCloseArea())

Return lRet


WsMethod Get Vend WsService vendedores

    local jResponse         := JsonObject():New()       as json
    local aAreaSA3          := {}                       as array
    local cCodVend          := ""                       as character
    local cFiltro           := ""                       as character
    local lRet              := .T.
    
    aAreaSA3 := SA3->(getArea())

    cCodVend  := self:aUrlParms[1]

    aAreaSA3 := SA3->(GetArea())
    cFiltro := "SA3->A3_MSBLQL != '1'"
    
    dbSelectArea("SA3")
    SA3->(dbSetFilter( {|| &(cFiltro)}, cFiltro ))
    SA3->(dbSetOrder(1))
    SA3->(dbGoTop())

    if SA3->(dbSeek(xFilial("SA3")+padR(cCodVend, TamSX3("A3_COD")[1], " "), .T.))

        jResponse['success']        := lRet
        jResponse['message']        := "Vendedor encontrado com sucesso"
        jResponse['codigo']         := SA3->A3_COD
        jResponse['nome']           := allTrim(SA3->A3_NREDUZ)
        jResponse['cgc']            := allTrim(SA3->A3_CGC)
        jResponse['tipo']           := allTrim(SA3->A3_TIPO)

    else

        lRet = .F.

        jResponse['success']        := lRet
        jResponse["message"]        := "Vendedor não encontrado na base de dados"
        jResponse['codigo']         := ""
        jResponse['nome']           := ""
        jResponse['cgc']            := ""
        jResponse['tipo']           := ""
        
    endif

    self:setContentType('application/json')
    self:setResponse(jResponse:toJson())

    SA3->(dbClearFilter())
    restArea(aAreaSA3)

return lRet


static function getQueryVendedores(cFiltro,cPagina,cTamPagina)

    local cQuery        := ""

    cQuery += " SELECT *
    cQuery += " FROM " + retSQLName("SA3")
    cQuery += " WHERE D_E_L_E_T_ = ' ' AND A3_MSBLQL != '1'

    if !empty(cFiltro)
        cQuery += " AND (A3_NREDUZ LIKE '%" + upper(cFiltro) + "%' OR A3_COD LIKE '%" + upper(cFiltro) + "%' OR A3_CGC LIKE '%" + upper(cFiltro) + "%' OR A3_NOME LIKE '%" + upper(cFiltro) + "%')"
    endif

    cQuery += " ORDER BY A3_COD

    if !empty(cPagina) .and. !empty(cTamPagina)
        cQuery += " OFFSET ("+cPagina+" - 1) * "+cTamPagina+" ROWS
        cQuery += " FETCH NEXT "+str(val(cTamPagina)+1)+" ROWS ONLY
    endif


return cQuery

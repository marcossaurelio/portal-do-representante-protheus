#include 'Protheus.ch'
#include 'Restful.ch'

WsRestful precificacao Description "Precificacao"

    WsData page     AS Character
    WsData pageSize AS Character
    WsData search   AS Character

    WsMethod Post   PrPrd   Description "Consulta precificacao de produto"  Path "/produto"
    WsMethod Get    TabPr   Description "Consulta tabelas de precificacao"  Path "/tabelas"
    WsMethod Get    DlTab   Description "Download tabela de precificacao"   Path "/tabelas/download/{tabela}"

End WsRestful


WsMethod Post PrPrd WsService precificacao

    local jResponse     := JsonObject():new()       as json
    local jBody         := JsonObject():new()       as json
    local cBody         := self:getContent()        as character
    local oPreco        := nil                      as object
    local cCondPg       := ""                       as character
    local cCondPgFrete  := ""                       as character
    local cProduto      := ""                       as character
    local lRet          := .T.
    
    jBody:fromJson(cBody)

    cCondPg          := jBody:getJsonObject('condPagamento')
    cCondPgFrete     := jBody:getJsonObject('condPagFrete')

    if getDiasPorCondPag( AllTrim(cCondPg) ) != nil .and. !Empty(AllTrim(cCondPg))

        jBody['prazoPagtoFrete']    := getDiasPorCondPag( AllTrim(cCondPgFrete) )
        jBody['prazoPagtoProduto']  := getDiasPorCondPag( AllTrim(cCondPg) )
        
        oPreco = U_GetPrcTb( jBody )

        if !empty(oPreco)

            jResponse["success"]            := .T.
            jResponse["message"]            := "Preço encontrado com sucesso."
            jResponse["filial"]             := oPreco:cFilialPreco
            jResponse["produto"]            := oPreco:cProduto
            jResponse["precoBase"]          := oPreco:nPrecoBase
            jResponse["precoUnitario"]      := oPreco:nPreco
            jResponse["maxDiasPagamento"]   := oPreco:nMaxDiasPgto
            jResponse["volumeMinimo"]       := oPreco:nVolumeMinimo
            jResponse["faturamentoMinimo"]  := oPreco:nFatMinimo
            jResponse["comissao"]           := oPreco:nComissao
            jResponse["categorias"]         := oPreco:aCategorias
            jResponse["tipoPreco"]          := oPreco:cTipoPreco
            jResponse["chave"]              := oPreco:cChave
            jResponse["dadosPreco"]         := aDadosPreco
            
        else

            lRet := .F.

            jResponse["success"]    := .F.
            jResponse["message"]    := "Preço não encontrado para o produto " + cProduto + " nas condições informadas."
            jResponse["fix"]        := "Verifique o cadastro do produto e as condições de precificação nas tabelas de preço."

        endif

    else

        lRet := .F.

        jResponse["success"]    := .F.
        jResponse["message"]    := "Condição de pagamento do orçamento inválida ou não encontrada."
        jResponse["fix"]        := "Informe uma condição de pagamento válida."
    
    endif

    self:setResponse(jResponse:toJson())

return lRet


WsMethod Get TabPr WsService precificacao

    local aArea         := GetArea()
    local aAreaZ03      := Z03->(GetArea())
    local jResponse     := JsonObject():New()
    local jItem         := JsonObject():New()
    local cPagina       := ""
    local cTamPagina    := ""
    local cFiltro       := ""
    local cFiltroZ03    := ""   
    local nContador     := 0
    local lRet          := .T.

    default self:page       := "1"
    default self:pageSize   := "10"
    default self:search     := ""

    cPagina     := self:page
    cTamPagina  := self:pageSize
    cFiltro     := self:search
    
    dbSelectArea("Z03")

    If !Empty(cFiltro)

        cFiltro := Upper(cFiltro)

        cFiltroZ03 := "'" + cFiltro + "' $ UPPER(Z03->Z03_COD) .or. " + ;
                      "'" + cFiltro + "' $ UPPER(Z03->Z03_DESCRI) .or. " + ;
                      "'" + cFiltro + "' $ UPPER(Z03->Z03_UNCARG) .or. " + ;
                      "'" + cFiltro + "' $ UPPER(Z03->Z03_FILIAL)"

        Z03->(dbSetFilter( {|| &(cFiltroZ03)}, cFiltroZ03 ))
    
    EndIf

    Z03->(dbGoTop())
    Z03->(dbSetOrder(2))
    
    nContador := 0

    While !Z03->(eof()) .And. nContador < (val(cPagina) - 1) * val(cTamPagina)

        nContador++
        Z03->(dbSkip())

    EndDo

    jResponse['items'] = {}

    nContador := 0

    while !Z03->(eof()) .And. nContador < val(cTamPagina)

        jItem := JsonObject():New()

        jItem['branchId']           := Z03->Z03_FILIAL
        jItem['branchName']         := Upper(NomeFilial(Z03->Z03_FILIAL))
        jItem['tableId']            := Z03->Z03_COD
        jItem['locationId']         := Z03->Z03_UNCARG
        jItem['locationName']       := Upper(NomeUndCar(Z03->Z03_UNCARG))
        jItem['description']        := AllTrim(Z03->Z03_DESCRI)
        jItem['lastUpdate']         := Z03->Z03_DTALTE
        jItem['id']                 := Z03->(Recno())
        jItem['hasFile']            := !Empty(Z03->Z03_ARQUIV)

        aAdd(jResponse['items'],jItem)

        Z03->(dbSkip())

        nContador++

    enddo

    Z03->(dbSkip())

    jResponse['hasNext'] = !Z03->(eof())

    self:setResponse(jResponse:toJson())

    Z03->(DbClearFilter())

    RestArea(aAreaZ03)
    RestArea(aArea)

Return lRet


WsMethod Get DlTab WsService precificacao

    Local cTabela       := ""
    Local cArquivo      := ""
    Local cArqDownl     := ""
    Local oArquivo      := Nil
    Local lRet          := .T.

    cTabela     := self:aUrlParms[Len(self:aUrlParms)]

    dbSelectArea("Z03")
    Z03->(dbSetOrder(1))
    Z03->(dbGoTop())
    
    If Z03->(dbSeek(AllTrim(cTabela)))

        cArquivo := Z03->Z03_ARQUIV

    EndIf

    oArquivo    := FwFileReader():New(cArquivo)

    If oArquivo:Open()

        cArqDownl := oArquivo:FullRead()

        Self:SetHeader("Content-Disposition", "attachment; filename=" + ExtractFile(cArquivo))

        Self:SetResponse(cArqDownl)

    Else

        SetRestFault(404, "Arquivo não encontrado.")
        lRet := .F.

    EndIf

return lRet


static function getDiasPorCondPag(cCondPg as character)

    local nDias     := 0                        as numeric
    local aDias     := {}                       as array
    local nSoma     := 0                        as numeric
    local aArea     := GetArea()                as array
    local cFiltro   := ""                       as character
    local nPos      := 0                        as numeric
    local nTamCampo := tamSX3("E4_COND")[1]     as numeric

    cFiltro := "SE4->E4_YPRUSAD == 'S' .and. SE4->E4_MSBLQL != '1'"

    dbSelectArea("SE4")
    SE4->(dbSetFilter( {|| &(cFiltro)}, cFiltro ))
    SE4->(dbSetOrder(1))
    SE4->(dbGoTop())

    if !SE4->(dbSeek(xFilial("SE4")+padR(cCondPg,nTamCampo), .T.))

        return nil

    endif

    aDias := strTokArr2(allTrim(SE4->E4_COND), ",", .F.)

    for nPos := 1 to len(aDias)

        nSoma += val(AllTrim(aDias[nPos]))

    next

    nDias := nSoma / len(aDias)

    RestArea(aArea)

return nDias


Static Function NomeFilial(cCodFilial)

    Do Case
        Case cCodFilial == "01010001"
            Return "Matriz"
        Case cCodFilial == "01010003"
            Return "Sao Camilo"
        Case cCodFilial == "01020009"
            Return "Sao Paulo"
        Case cCodFilial == "01030010"
            Return "Rio de Janeiro
    EndCase

Return cCodFilial


Static Function NomeUndCar(cCodUndCar)

    Do Case
        Case cCodUndCar == "SS"
            Return "Serv Sal"
        Case cCodUndCar == "FS"
            Return "F Souto"
        Case cCodUndCar == "JS"
            Return "Jassal"
        Case cCodUndCar == "SP"
            Return "Sao Paulo"
        Case cCodUndCar == "RJ"
            Return "Rio de Janeiro"
    EndCase

Return cCodUndCar

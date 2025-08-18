#include 'Protheus.ch'
#include 'Restful.ch'

WsRestful precificacao Description "Precificacao"

    WsMethod Post   PrPrd   Description "Consulta precificacao de produto"  Path "/produto"

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

        nDiasPagto := getDiasPorCondPag( AllTrim(cCondPg) )

        jBody['diasPagamento'] := nDiasPagto
        jBody['prazoPagtoFrete'] := getDiasPorCondPag( AllTrim(cCondPgFrete) )
        
        oPreco = U_GetPrcTb( jBody )

        if !empty(oPreco)

            jResponse["success"]            := .T.
            jResponse["message"]            := "Pre�o encontrado com sucesso."
            jResponse["filial"]             := oPreco:cFilialPreco
            jResponse["produto"]            := oPreco:cProduto
            jResponse["precoUnitario"]      := oPreco:nPreco
            jResponse["maxDiasPagamento"]   := oPreco:nMaxDiasPgto
            jResponse["volumeMinimo"]       := oPreco:nVolumeMinimo
            jResponse["faturamentoMinimo"]  := oPreco:nFatMinimo
            jResponse["comissao"]           := oPreco:nComissao
            jResponse["categorias"]         := oPreco:aCategorias
            jResponse["chave"]              := oPreco:cChave
            
        else

            lRet := .F.

            jResponse["success"]    := .F.
            jResponse["message"]    := "Pre�o n�o encontrado para o produto " + cProduto + " nas condi��es informadas."
            jResponse["fix"]        := "Verifique o cadastro do produto e as condi��es de precifica��o nas tabelas de pre�o."

        endif

    else

        lRet := .F.

        jResponse["success"]    := .F.
        jResponse["message"]    := "Condi��o de pagamento do or�amento inv�lida ou n�o encontrada."
        jResponse["fix"]        := "Informe uma condi��o de pagamento v�lida."
    
    endif

    self:setResponse(jResponse:toJson())

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

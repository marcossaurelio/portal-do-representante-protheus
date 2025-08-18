#include 'Protheus.ch'
#include 'Restful.ch'

WsRestful frete Description "Frete"

    WsMethod Post   FrRod   Description "Consulta valor de frete rodovi�rio"    Path "/valor/rodoviario"
    WsMethod Post   FrMar   Description "Consulta valor de frete mar�timo"      Path "/valor/maritimo"

End WsRestful


WsMethod Post FrRod WsService frete

    local jResponse             := JsonObject():New()       as json
    local jBody                 := JsonObject():new()       as json
    local cBody                 := self:getContent()        as character
    local cQuery                := ""                       as character
    local cAlias                := ""                       as character
    local cFilialOrigem         := ""                       as character
    local cEstadoDestino        := ""                       as character
    local cCidadeDestino        := ""                       as character
    local nValorFrete           := 0                        as numeric
    local cNomeCidadeDestino    := ""                       as character
    local lRet          := .T.
    
    jBody:fromJson(cBody)

    cFilialOrigem   := jBody:getJsonObject('filialOrigem')
    cEstadoDestino  := jBody:getJsonObject('estadoDestino')
    cCidadeDestino  := jBody:getJsonObject('cidadeDestino')
    
    cQuery := getQueryFrete(cFilialOrigem,cEstadoDestino,cCidadeDestino)

    cAlias := getNextAlias()

    MPSysOpenQuery(cQuery,cAlias)

    dbSelectArea(cAlias)
    (cAlias)->(dbGoTop())

    if !(cAlias)->(eof())

        nValorFrete         := (cAlias)->Z02_VLFRET
        cEstadoDestino      := (cAlias)->Z02_UFDEST
        cNomeCidadeDestino  := (cAlias)->CC2_MUN

        jResponse['success']            := .T.
        jResponse['filialOrigem']       := cFilialOrigem
        jResponse['estadoDestino']      := cEstadoDestino
        jResponse['cidadeDestino']      := cCidadeDestino
        jResponse['nomeCidadeDestino']  := cNomeCidadeDestino
        jResponse['valorFrete']         := nValorFrete

    else

        lRet := .F.

        jResponse['success']        := .F.
        jResponse['message']        := "Valor de frete n�o encontrado para a filial e cidade informadas."

    endif

    self:setResponse(jResponse:toJson())

    (cAlias)->(DbCloseArea())

return lRet


WsMethod Post FrMar WsService frete

    local jResponse             := JsonObject():New()       as json
    local jBody                 := JsonObject():new()       as json
    local cBody                 := self:getContent()        as character
    local cFilialOrigem         := ""                       as character
    local cEstadoDestino        := ""                       as character
    local cCidadeDestino        := ""                       as character
    local nValorFrete           := 0                        as numeric
    local cNomeCidadeDestino    := ""                       as character
    local nPesoCarga            := 0                        as numeric
    local cTipoContainer        := ""                       as character
    local nPayloadUtilizado     := 0                        as numeric

    local nPrcC20Geral  := GetNewPar("MS_PRFGE20",194.80)   as numeric
    local nPyldC20Geral := GetNewPar("MS_PLFGE20",28.2)     as numeric
    local nPrcC40Geral  := GetNewPar("MS_PRFGE40",194.80)   as numeric
    local nPyldC40Geral := GetNewPar("MS_PLFGE40",28.2)     as numeric

    local nPrcC20RJ     := GetNewPar("MS_PRFRJ20",276.26)   as numeric
    local nPyldC20RJ    := GetNewPar("MS_PLFRJ20",28.2)     as numeric
    local nPrcC40RJ     := GetNewPar("MS_PRFRJ40",306.00)   as numeric
    local nPyldC40RJ    := GetNewPar("MS_PLFRJ40",28.2)     as numeric

    local nPrcC20SP     := GetNewPar("MS_PRFSP20",280.44)   as numeric
    local nPyldC20SP    := GetNewPar("MS_PLFSP20",27.0)     as numeric
    local nPrcC40SP     := GetNewPar("MS_PRFSP40",293.49)   as numeric
    local nPyldC40SP    := GetNewPar("MS_PLFSP40",27.5)     as numeric

    local lRet          := .T.

    jBody:fromJson(cBody)

    cFilialOrigem   := jBody:getJsonObject('filialOrigem')
    cEstadoDestino  := jBody:getJsonObject('estadoDestino')
    cCidadeDestino  := jBody:getJsonObject('cidadeDestino')
    nPesoCarga      := jBody:getJsonObject('pesoTotal')

    if cEstadoDestino == "RJ"

        if nPesoCarga <= nPyldC20RJ*1000 .Or. nPyldC20RJ == nPyldC40RJ

            nValorFrete := nPrcC20RJ
            cTipoContainer := "C20"
            nPayloadUtilizado := nPyldC20RJ

        else

            nValorFrete := nPrcC40RJ
            cTipoContainer := "C40"
            nPayloadUtilizado := nPyldC40RJ

        endif

    elseif cEstadoDestino == "SP"

        if nPesoCarga <= nPyldC20SP*1000 .Or. nPyldC20SP == nPyldC40SP

            nValorFrete := nPrcC20SP
            cTipoContainer := "C20"
            nPayloadUtilizado := nPyldC20SP

        else

            nValorFrete := nPrcC40SP
            cTipoContainer := "C40"
            nPayloadUtilizado := nPyldC40SP

        endif

    else // Considerando frete geral para outros estados

        if nPesoCarga <= nPyldC20Geral*1000 .Or. nPyldC20Geral == nPyldC40Geral

            nValorFrete := nPrcC20Geral
            cTipoContainer := "C20"
            nPayloadUtilizado := nPyldC20Geral

        else

            nValorFrete := nPrcC40Geral
            cTipoContainer := "C40"
            nPayloadUtilizado := nPyldC40Geral

        endif

    endif

    if !empty(cEstadoDestino) .and. !empty(cCidadeDestino)

        cNomeCidadeDestino  := posicione("CC2",1,xFilial("CC2")+cEstadoDestino+cCidadeDestino,"CC2_MUN")

    endif

    jResponse['success']            := .T.
    jResponse['filialOrigem']       := cFilialOrigem
    jResponse['estadoDestino']      := cEstadoDestino
    jResponse['cidadeDestino']      := cCidadeDestino
    jResponse['nomeCidadeDestino']  := cNomeCidadeDestino
    jResponse['valorFrete']         := nValorFrete
    jResponse['tipoContainer']      := cTipoContainer
    jResponse['pesoMaximo']         := nPayloadUtilizado*1000

    self:setResponse(jResponse:toJson())

Return lRet


static function getQueryFrete(cFilialOrigem,cEstadoDestino,cCidadeDestino)

    local cQuery := "" as character

    cQuery += " SELECT *
    cQuery += " FROM "+retSQLName("Z02")+" Z02
    cQuery += " INNER JOIN "+retSQLName("CC2")+" CC2 ON CC2_YREGIA = Z02_RGDEST AND CC2_EST = Z02_UFDEST AND CC2.D_E_L_E_T_ = ' '
    cQuery += " WHERE Z02_FILIAL = '" + cFilialOrigem + "' AND CC2_CODMUN = '" + cCidadeDestino + "' AND CC2_EST = '" + cEstadoDestino + "'
    cQuery += " AND Z02.D_E_L_E_T_ = ' '
    cQuery += " ORDER BY Z02.R_E_C_N_O_

return cQuery

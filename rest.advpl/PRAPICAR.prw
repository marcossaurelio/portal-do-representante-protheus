#include 'Protheus.ch'
#include 'Restful.ch'

WsRestful contasareceber Description "Contas a Receber"

    WsMethod Post TitRe     Description "Retorna os títulos a receber"  Path "/"

End WsRestful


WsMethod Post TitRe WsService contasareceber

    local jResponse     := JsonObject():New()       as json
    local jBody         := JsonObject():new()       as json
    local cBody         := self:getContent()        as character
    local cQuery        := ""                       as character
    local cAlias        := ""                       as character
    local nTamPagina    := 10                       as numeric
    local nContador     := 0                        as numeric
    local jRegistro                                 as json
    local lRet          := .T.
    
    jBody:fromJson(cBody)

    nTamPagina := jBody:getJsonObject('pageSize')

    cQuery := qryBrowse(jBody)

    cAlias := getNextAlias()

    MPSysOpenQuery(cQuery,cAlias)

    dbSelectArea(cAlias)
    (cAlias)->(dbGoTop())

    nContador := 0

    jResponse['items'] = {}

    while !(cAlias)->(eof()) .and. iif(!empty(nTamPagina),nContador < nTamPagina,.T.)

        jRegistro := JsonObject():New()

        jRegistro['id']                     := (cAlias)->RECNO
        jRegistro['branch']                 := (cAlias)->E1_FILIAL
        jRegistro['budgetId']               := (cAlias)->C5_YNUMORC
        jRegistro['orderId']                := (cAlias)->E1_PEDIDO
        jRegistro['sellerId']               := (cAlias)->A3_COD
        jRegistro['sellerName']             := allTrim((cAlias)->A3_NREDUZ)
        jRegistro['clientId']               := Posicione("SA1",1,xFilial("SA1")+(cAlias)->E1_CLIENTE,"A1_CGC")
        jRegistro['clientName']             := allTrim((cAlias)->E1_NOMCLI)
        jRegistro['prefix']                 := (cAlias)->E1_PREFIXO
        jRegistro['document']               := (cAlias)->E1_NUM
        jRegistro['installment']            := (cAlias)->E1_PARCELA
        jRegistro['issueDate']              := SToD((cAlias)->E1_EMISSAO)
        jRegistro['dueDate']                := SToD((cAlias)->E1_VENCREA)
        jRegistro['paymentDate']            := SToD((cAlias)->E1_BAIXA)
        jRegistro['value']                  := (cAlias)->E1_VALOR
        jRegistro['paidValue']              := (cAlias)->E1_VALOR - (cAlias)->E1_SALDO
        jRegistro['balance']                := (cAlias)->E1_SALDO
        jRegistro['daysOverdue']            := IIF( Date() > SToD((cAlias)->E1_VENCREA) .And. (cAlias)->E1_SALDO > 0, Date() - SToD((cAlias)->E1_VENCREA), 0)
        jRegistro['status']                 := StatusTitu(cAlias)

        aAdd(jResponse['items'],jRegistro)

        (cAlias)->(dbSkip())

        nContador++

    enddo

    jResponse['hasNext'] = !(cAlias)->(eof())

    self:setResponse(jResponse:toJson())

    (cAlias)->(DbCloseArea())

return lRet


static function qryBrowse(jBody)

    local cQuery        := ""

    local nPagina       := jBody:getJsonObject('page')
    local nTamPagina    := jBody:getJsonObject('pageSize')
    local aStatus       := jBody:getJsonObject('status')
    local aFiliais      := jBody:getJsonObject('branch')
    local cOrcamento    := jBody:getJsonObject('budgetId')
    local cPedido       := jBody:getJsonObject('orderId')
    local aVendedores   := jBody:getJsonObject('sellerId')
    local aClientes     := jBody:getJsonObject('clientId')
    local cTitulo       := jBody:getJsonObject('document')
    local oDtEmissao    := jBody:getJsonObject('issueDate')
    local oDtVencto     := jBody:getJsonObject('dueDate')
    local nValorDe      := jBody:getJsonObject('valueFrom')
    local nValorAte     := jBody:getJsonObject('valueTo')
    local nSaldoDe      := jBody:getJsonObject('balanceFrom')
    local nSaldoAte     := jBody:getJsonObject('balanceTo')

    local dDtEmisDe
    local dDtEmisAte
    local dDtVencDe
    local dDtVencAte

    if oDtEmissao != Nil
        dDtEmisDe   := StrTran(oDtEmissao:getJsonObject('start'),"-","")
        dDtEmisAte  := StrTran(oDtEmissao:getJsonObject('end'),"-","")
    endif

    if oDtVencto != Nil
        dDtVencDe   := StrTran(oDtVencto:getJsonObject('start'),"-","")
        dDtVencAte  := StrTran(oDtVencto:getJsonObject('end'),"-","")
    endif

    SE1->(DbSetOrder(1))

    /*
    SELECT SE1.R_E_C_N_O_ AS RECNO,*
    FROM SE1100 SE1
    INNER JOIN SC5100 SC5 ON C5_FILIAL = E1_FILIAL AND C5_NUM = E1_PEDIDO AND SC5.D_E_L_E_T_ = ' '
    LEFT JOIN  SA3100 SA3 ON A3_COD = C5_VEND1 AND SA3.D_E_L_E_T_ = ' '
    WHERE SE1.D_E_L_E_T_ = ' ' AND E1_FILIAL IN ('01010003','01020009','01030010')
    ORDER BY E1_FILIAL,E1_PREFIXO,E1_NUM,E1_PARCELA,E1_TIPO
    OFFSET (1 - 1) * 10 ROWS FETCH NEXT 11 ROWS ONLY 
    */

    cQuery += " SELECT SE1.R_E_C_N_O_ AS RECNO,*
    cQuery += " FROM " + RetSQLName("SE1") + " SE1
    cQuery += " INNER JOIN " + RetSQLName("SC5") + " SC5 ON C5_FILIAL = E1_FILIAL AND C5_NUM = E1_PEDIDO AND SC5.D_E_L_E_T_ = ' '
    cQuery += " LEFT JOIN " + RetSQLName("SA3") + " SA3 ON A3_COD = C5_VEND1 AND SA3.D_E_L_E_T_ = ' '
    cQuery += " WHERE SE1.D_E_L_E_T_ = ' ' AND E1_FILIAL IN ('01010003','01020009','01030010')

    if !empty(aFiliais)
        cQuery += " AND E1_FILIAL IN " + FormatIn(ArrTokStr(aFiliais,","),",")
    endif

    if !empty(cOrcamento)
        cQuery += " AND C5_YNUMORC LIKE '%" + cOrcamento + "%'
    endif

    if !empty(cPedido)
        cQuery += " AND E1_PEDIDO LIKE '%" + cPedido + "%'
    endif

    if !empty(aVendedores)
        cQuery += " AND C5_VEND1 IN " + FormatIn(ArrTokStr(aVendedores,","),",")
    endif

    if !empty(aClientes)
        cQuery += " AND E1_CLIENTE+E1_LOJA IN " + FormatIn(ArrTokStr(aClientes,","),",")
    endif

    if !empty(cTitulo)
        cQuery += " AND E1_NUM LIKE '%" + cTitulo + "%'
    endif
    
    if !empty(dDtEmisDe)
        cQuery += " AND E1_EMISSAO >= " + dDtEmisDe
    endif

    if !empty(dDtEmisAte)
        cQuery += " AND E1_EMISSAO <= " + dDtEmisAte
    endif

    if !empty(dDtVencDe)
        cQuery += " AND E1_VENCREA >= " + dDtVencDe
    endif

    if !empty(dDtVencAte)
        cQuery += " AND E1_VENCREA <= " + dDtVencAte
    endif

    if !empty(nValorDe) .Or. nValorDe == 0
        cQuery += " AND E1_VALOR >= " + cValToChar(nValorDe)
    endif

    if !empty(nValorAte) .Or. nValorAte == 0
        cQuery += " AND E1_VALOR <= " + cValToChar(nValorAte)
    endif

    if !empty(nSaldoDe) .Or. nSaldoDe == 0
        cQuery += " AND E1_SALDO >= " + cValToChar(nSaldoDe)
    endif

    if !empty(nSaldoAte) .Or. nSaldoAte == 0
        cQuery += " AND E1_SALDO <= " + cValToChar(nSaldoAte)
    endif

    if !empty(aStatus)

        cQuery += " AND ((1=0)

        if AScan(aStatus,"PG") > 0
            cQuery += " OR (E1_SALDO <= 0)
        endif

        if AScan(aStatus,"AT") > 0
            cQuery += " OR (E1_SALDO > 0 AND E1_VENCREA < " + DToS(Date()) + ")
        endif

        if AScan(aStatus,"PP") > 0
            cQuery += " OR (E1_SALDO > 0 AND E1_SALDO < E1_VALOR AND E1_VENCREA >= " + DToS(Date()) + ")
        endif

        if AScan(aStatus,"PE") > 0
            cQuery += " OR (E1_SALDO = E1_VALOR AND E1_VENCREA >= " + DToS(Date()) + ")
        endif

        cQuery += " )
        
    endif

    cQuery += " ORDER BY " + StrTran(SE1->(IndexKey(IndexOrd())),"+",",")

    if !empty(nPagina) .and. !empty(nTamPagina)
        cQuery += " OFFSET ("+cValToChar(nPagina)+" - 1) * "+cValToChar(nTamPagina)+" ROWS
        cQuery += " FETCH NEXT "+cValToChar(nTamPagina+1)+" ROWS ONLY
    endif

return cQuery


Static Function StatusTitu(cAlias)

    Do Case
        Case (cAlias)->E1_SALDO <= 0
            Return "PG" // Pago
        Case Date() > SToD((cAlias)->E1_VENCREA)
            Return "AT" // Atrasado
        Case (cAlias)->E1_SALDO < (cAlias)->E1_VALOR
            Return "PP" // Parcialmente Pago
        Case Date() <= SToD((cAlias)->E1_VENCREA)
            Return "PE" // Pendente
    EndCase

Return ""

#include 'Protheus.ch'
#include 'Restful.ch'

WsRestful clientes Description "Clientes"

    WsData page         AS Character
    WsData pageSize     AS Character
    WsData filter       AS Character
    WsData sellerId     AS Character

    WsMethod Get Clnts  Description "Retorna os clientes disponiveis"                  Path "/"
    WsMethod Get Clnt   Description "Retorna um cliente especifico"                    Path "/{codigo}"
    WsMethod Get ClPub  Description "Retorna os dados publicos de um CNPJ"             Path "/dados-publicos/{cnpj}"
    WsMethod Post CrCli Description "Cadastra um cliente no Protheus"                  Path "/incluir"

End WsRestful


WsMethod Get Clnts WsService clientes

    local jResponse     := JsonObject():New()       as json
    local cQuery        := ""                       as character
    local cAlias        := ""                       as character
    local cFiltro       := ""                       as character
    local cPagina       := ""                       as character
    local cTamPagina    := ""                       as character
    local nContador     := 0                        as numeric
    local cCodVended    := ""                       as character
    local jItem                                     as json
    local lRet          := .T.

    default self:page       := "1"
    default self:pageSize   := "10"
    default self:filter     := ""
    default self:sellerId   := ""

    cPagina     := self:page
    cTamPagina  := self:pageSize
    cFiltro     := self:filter
    cCodVended  := self:sellerId
    
    cQuery := getQueryClientes(cFiltro,cPagina,cTamPagina,cCodVended)

    cAlias := getNextAlias()

    MPSysOpenQuery(cQuery,cAlias)

    dbSelectArea(cAlias)
    (cAlias)->(dbGoTop())

    jResponse['items'] = {}

    nContador := 0

    while !(cAlias)->(eof()) .and. iif(!empty(cTamPagina),nContador < val(cTamPagina),.T.)

        jItem := JsonObject():New()

        jItem['success']        := .T.
        jItem['codigo']         := (cAlias)->A1_COD
        jItem['loja']           := (cAlias)->A1_LOJA
        jItem['codigoLoja']     := (cAlias)->A1_COD+(cAlias)->A1_LOJA
        jItem['cgc']            := allTrim((cAlias)->A1_CGC)
        jItem['razaoSocial']    := allTrim((cAlias)->A1_NOME)
        jItem['nomeFantasia']   := allTrim((cAlias)->A1_NREDUZ)
        jItem['estado']         := (cAlias)->A1_EST
        jItem['ie']             := (cAlias)->A1_INSCR
        jItem['categoria']      := allTrim((cAlias)->A1_YCATEGO)
        jItem['tipo']           := (cAlias)->A1_PESSOA

        aAdd(jResponse['items'],jItem)

        (cAlias)->(dbSkip())

        nContador++

    enddo

    jResponse['hasNext'] = !(cAlias)->(eof())

    self:setResponse(jResponse:toJson())

    (cAlias)->(DbCloseArea())

Return lRet


WsMethod Get Clnt WsService clientes

    local jResponse         := JsonObject():New()       as json
    local aAreaSA1          := {}                       as array
    local cCodigoCliente    := ""                       as character
    local nTamCampo         := 0                        as numeric
    local cCodVendedor      := ""                       as character
    local lRet              := .T.

    default self:sellerId   := ""
    
    cCodigoCliente  := self:aUrlParms[len(self:aUrlParms)]
    cCodVendedor    := self:sellerId

    dbSelectArea("SA1")
    aAreaSA1 := SA1->(GetArea())

    if len(cCodigoCliente) <= 8 // Se o codigo enviado na requisicao tiver tamanho atÃ© 8, pesquisa por A1_COD

        SA1->(dbSetOrder(1))
        nTamCampo := tamSX3("A1_COD")[1] + tamSX3("A1_LOJA")[1] // Tamanho do campo A1_COD

    else // Se o codigo enviado na requisicao tiver tamanho maior que 8, pesquisa por A1_CGC

        SA1->(dbSetOrder(3))
        nTamCampo := tamSX3("A1_CGC")[1] // Tamanho do campo A1_CGC

    endif

    SA1->(dbGoTop())

    if SA1->(dbSeek(xFilial("SA1")+padR(cCodigoCliente, nTamCampo, " "))) .And. (AllTrim(SA1->A1_COD + SA1->A1_LOJA) == cCodigoCliente .Or. AllTrim(SA1->A1_CGC) == cCodigoCliente)

        if validaCliente(SA1->A1_COD,SA1->A1_LOJA,cCodVendedor) .or. SA1->A1_VEND == cCodVendedor

            jResponse['success']        := .T.
            jResponse['codigo']         := SA1->A1_COD
            jResponse['loja']           := SA1->A1_LOJA
            jResponse['codigoLoja']     := SA1->A1_COD+SA1->A1_LOJA
            jResponse['cgc']            := allTrim(SA1->A1_CGC)
            jResponse['razaoSocial']    := allTrim(SA1->A1_NOME)
            jResponse['nomeFantasia']   := allTrim(SA1->A1_NREDUZ)
            jResponse['estado']         := SA1->A1_EST
            jResponse['cidade']         := SA1->A1_COD_MUN
            jResponse['ie']             := AllTrim(SA1->A1_INSCR)
            jResponse['categoria']      := allTrim(SA1->A1_YCATEGO)
            jResponse['tipo']           := SA1->A1_PESSOA
            jResponse['municipio']      := SA1->A1_COD_MUN
            jResponse['icmsPautaFrete'] := SA1->A1_XVLRFRT / 2 * (U_DefPort("ICMSPAUTFR",12)/100)

        else

            lRet := .F.

            jResponse['success']        := .F.
            jResponse["message"]        := "Cliente não disponível, já em atendimento por outro vendedor"
            jResponse["fix"]            := "Selecione um cliente disponível para atendimento"
            jResponse["codigo"]         := ""
            jResponse["loja"]           := ""
            jResponse["codigoLoja"]     := ""
            jResponse["cgc"]            := ""
            jResponse["razaoSocial"]    := ""
            jResponse["nomeFantasia"]   := ""

        endif

    else

        lRet := .F.

        jResponse['success']            := .F.
        jResponse["message"]            := "Cliente não cadastrado ou não encontrado"
        jResponse["fix"]                := "Selecione um cliente válido"
        jResponse["codigo"]             := ""
        jResponse["loja"]               := ""
        jResponse["codigoLoja"]         := ""
        jResponse["cgc"]                := ""
        jResponse["razaoSocial"]        := ""
        jResponse["nomeFantasia"]       := ""
        
    endif

    self:setResponse(jResponse:toJson())

    restArea(aAreaSA1)

return lRet


WsMethod Get ClPub WsService clientes

    local jResponse     := JsonObject():New()                                       as json
    local aHeader       := {}                                                       as array
    local oRestClient   := FWRest():New("https://www.receitaws.com.br/v1/cnpj/")    as object
    local cCNPJ         := ""                                                       as character
    local jResult       := JsonObject():New()                                       as json
    local cNomeCidade   := ""                                                       as character
    local lRet          := .T.
    
    cCNPJ := self:aUrlParms[len(self:aUrlParms)]

    //Adiciona os headers que serão enviados via WS
    aAdd(aHeader,'User-Agent: Mozilla/4.0 (compatible; Protheus '+GetBuild()+')')
    aAdd(aHeader,'Content-Type: application/json; charset=utf-8')
  
    oRestClient:setPath(cCNPJ)

    if oRestClient:Get(aHeader)

        jResult:fromJson(oRestClient:GetResult())

        if jResult:getJsonObject('status') == "OK"

            cNomeCidade := converterUTF8(jResult:getJsonObject('municipio'))

            jResponse['success']            := jResult:getJsonObject('status') == "OK"
            jResponse['cnpj']               := converterUTF8(jResult:getJsonObject('cnpj'))
            jResponse['razaoSocial']        := converterUTF8(jResult:getJsonObject('nome'))
            jResponse['nomeFantasia']       := converterUTF8(jResult:getJsonObject('fantasia'))
            jResponse['abertura']           := converterUTF8(jResult:getJsonObject('abertura'))
            jResponse['situacao']           := converterUTF8(jResult:getJsonObject('situacao'))
            jResponse['endereco']           := converterUTF8(jResult:getJsonObject('logradouro') + ", " + jResult:getJsonObject('numero'))
            jResponse['complemento']        := converterUTF8(jResult:getJsonObject('complemento'))
            jResponse['bairro']             := converterUTF8(jResult:getJsonObject('bairro'))
            jResponse['cep']                := formatCEP(converterUTF8(jResult:getJsonObject('cep')))
            jResponse['municipio']          := Posicione("CC2",2,xFilial("CC2")+padR(cNomeCidade,tamSX3("CC2_MUN")[1]),"CC2_CODMUN") // Busca o nome do municÃ­pio na tabela CC2
            jResponse['uf']                 := converterUTF8(jResult:getJsonObject('uf'))
            jResponse['ddd']                := formatTelefone(converterUTF8(jResult:getJsonObject('telefone')))[1]
            jResponse['telefone']           := formatTelefone(converterUTF8(jResult:getJsonObject('telefone')))[2]
            jResponse['email']              := converterUTF8(jResult:getJsonObject('email'))
            jResponse['simplesNacional']    := jResult:getJsonObject('simples'):getJsonObject('optante')
            jResponse['jaCadastrado']       := !empty(posicione("SA1",3,xFilial("SA1")+padR(cCNPJ,tamSX3("A1_CGC")[1]),"A1_COD")) // Indica se o cliente já está cadastrado no Protheus

        else

            lRet := .F.

            jResponse['success']        := .F.
            jResponse['status']         := converterUTF8(jResult:getJsonObject('status'))
            jResponse['message']        := iif(left(converterUTF8(jResult:getJsonObject('message')),8) == "CNPJ inv", "CNPJ inválido", converterUTF8(jResult:getJsonObject('message')))
            jResponse['cnpj']           := cCNPJ

        endif
         
    else

        lRet := .F.

        jResponse['success']        := .F.
        jResponse['message']        := converterUTF8(oRestClient:GetResult())
        jResponse['error']          := converterUTF8(oRestClient:GetLastError())

    endif

    self:setResponse(jResponse:toJson())

return lRet


WsMethod Post CrCli WsService clientes

    local jResponse         := JsonObject():new()       as json
    local jBody             := JsonObject():new()       as json
    local cBody             := self:getContent()        as character
    local aDadosSA1         := {}                       as array
    local cNomeMunicipio    := ""                       as character
    local lRet              := .T.

    private lMsErroAuto     := .F.                      as logical
    
    jBody:fromJson(cBody)

    cNomeMunicipio := posicione("CC2",1,xFilial("CC2")+jBody:getJsonObject('estado')+jBody:getJsonObject('municipio'),"CC2_MUN")

    aAdd(aDadosSA1, { "A1_NOME",    formataCampo(jBody:getJsonObject('razaoSocial'),        "A1_NOME"),     nil })
    aAdd(aDadosSA1, { "A1_NREDUZ",  formataCampo(jBody:getJsonObject('nomeFantasia'),       "A1_NREDUZ"),   nil })
    aAdd(aDadosSA1, { "A1_CGC",     jBody:getJsonObject('cnpj'),                                            nil })
    aAdd(aDadosSA1, { "A1_PESSOA",  "J",                                                                    nil })
    aAdd(aDadosSA1, { "A1_TIPO",    jBody:getJsonObject('tipo'),                                            nil })
    aAdd(aDadosSA1, { "A1_EST",     jBody:getJsonObject('estado'),                                          nil })
    aAdd(aDadosSA1, { "A1_CONTRIB", jBody:getJsonObject('contribuinte'),                                    nil })
    aAdd(aDadosSA1, { "A1_INSCR",   formataCampo(jBody:getJsonObject('ie'),                 "A1_INSCR"),    nil })
    aAdd(aDadosSA1, { "A1_SIMPNAC", jBody:getJsonObject('simplesNacional'),                                 nil })
    aAdd(aDadosSA1, { "A1_YCATEGO", jBody:getJsonObject('categoria'),                                       nil })
    aAdd(aDadosSA1, { "A1_END",     formataCampo(jBody:getJsonObject('endereco'),           "A1_END"),      nil })
    aAdd(aDadosSA1, { "A1_BAIRRO",  formataCampo(jBody:getJsonObject('bairro'),             "A1_BAIRRO"),   nil })
    aAdd(aDadosSA1, { "A1_CEP",     formataCampo(jBody:getJsonObject('cep'),                "A1_CEP"),      nil })
    aAdd(aDadosSA1, { "A1_COD_MUN", formataCampo(jBody:getJsonObject('municipio'),          "A1_COD_MUN"),  nil })
    aAdd(aDadosSA1, { "A1_DDD",     jBody:getJsonObject('ddd'),                                             nil })
    aAdd(aDadosSA1, { "A1_TEL",     jBody:getJsonObject('telefone'),                                        nil })
    aAdd(aDadosSA1, { "A1_EMAIL",   formataCampo(jBody:getJsonObject('email'),              "A1_EMAIL"),    nil })
    aAdd(aDadosSA1, { "A1_YMAILXM", formataCampo(jBody:getJsonObject('email'),              "A1_YMAILXM"),  nil })
    aAdd(aDadosSA1, { "A1_YVENINC", jBody:getJsonObject('vendedor'),                                        nil })
    aAdd(aDadosSA1, { "A1_YPENREV", "S",                                                                    nil })
    aAdd(aDadosSA1, { "A1_YOBS",    formataCampo(jBody:getJsonObject('observacao'),         "A1_YOBS"),     nil })
    aAdd(aDadosSA1, { "A1_ENDCOB",  formataCampo(jBody:getJsonObject('endereco'),           "A1_ENDCOB"),   nil })
    aAdd(aDadosSA1, { "A1_BAIRROC", formataCampo(jBody:getJsonObject('bairro'),             "A1_BAIRROC"),  nil })
    aAdd(aDadosSA1, { "A1_CEPC",    formataCampo(jBody:getJsonObject('cep'),                "A1_CEPC"),     nil })
    aAdd(aDadosSA1, { "A1_MUNC",    formataCampo(cNomeMunicipio,                            "A1_MUNC"),     nil })
    aAdd(aDadosSA1, { "A1_ESTC",    jBody:getJsonObject('estado'),                                          nil })
    aAdd(aDadosSA1, { "A1_ENDREC",  formataCampo(jBody:getJsonObject('endereco'),           "A1_ENDREC"),   nil })
    aAdd(aDadosSA1, { "A1_ENDENT",  formataCampo(jBody:getJsonObject('endereco'),           "A1_ENDENT"),   nil })
    aAdd(aDadosSA1, { "A1_BAIRROE", formataCampo(jBody:getJsonObject('bairro'),             "A1_BAIRROE"),  nil })
    aAdd(aDadosSA1, { "A1_CEPE",    formataCampo(jBody:getJsonObject('cep'),                "A1_CEPE"),     nil })
    aAdd(aDadosSA1, { "A1_MUNE",    formataCampo(cNomeMunicipio,                            "A1_MUNE"),     nil })
    aAdd(aDadosSA1, { "A1_ESTE",    jBody:getJsonObject('estado'),                                          nil })
    aAdd(aDadosSA1, { "A1_REGIAO",  formataCampo(getRegiao(jBody:getJsonObject('estado')),  "A1_REGIAO"),   nil })

    MSExecAuto({|a,b| CRMA980(a,b)}, aDadosSA1,3)

    if !lMsErroAuto

        jResponse["success"]    := .T.
        jResponse["message"]    := "Cliente " + SA1->A1_COD + " cadastrado com sucesso."
        jResponse["codigo"]     := SA1->A1_COD
        jResponse["cnpj"]       := SA1->A1_CGC

    else

        lRet := .F.

        jResponse["success"]    := .F.
        jResponse["message"]    := "Erro ao cadastrar o cliente"
        jResponse["fix"]        := MemoRead(Alltrim(NomeAutoLog()))
    
    endif        

    self:setResponse(jResponse:toJson())

return lRet


static function getQueryClientes(cFiltro,cPagina,cTamPagina,cCodVendedor)

    local cQuery        := ""

    cQuery += " SELECT DISTINCT A1_COD, A1_LOJA, A1_CGC, A1_NOME, A1_NREDUZ, A1_EST, A1_INSCR, A1_YCATEGO, A1_PESSOA
    cQuery += " FROM " + retSQLName("SA1") + " SA1

    if Posicione("SA3",1,xFilial("SA3")+cCodVendedor,"A3_TIPO") != 'I'
        cQuery += " INNER JOIN " + retSQLName("SCJ") + " SCJ ON CJ_CLIENTE = A1_COD AND CJ_LOJA = A1_LOJA AND SCJ.D_E_L_E_T_ = ' '
    endif

    cQuery += " WHERE SA1.D_E_L_E_T_ = ' ' AND A1_MSBLQL != '1'

    if Posicione("SA3",1,xFilial("SA3")+cCodVendedor,"A3_TIPO") != 'I'
        cQuery += " AND CJ_EMISSAO >= '" + dToS(Date()-90) + "' AND CJ_YVEND = '" + cCodVendedor + "'
    endif

    if !empty(cFiltro)
        cQuery += " AND (A1_CGC LIKE '%" + upper(cFiltro) + "%' OR A1_COD+A1_LOJA LIKE '%" + upper(cFiltro) + "%' OR A1_NOME LIKE '%" + upper(cFiltro) + "%')
    endif

    cQuery += " ORDER BY A1_COD, A1_LOJA

    if !empty(cPagina) .and. !empty(cTamPagina)
        cQuery += " OFFSET ("+cPagina+" - 1) * "+cTamPagina+" ROWS
        cQuery += " FETCH NEXT "+cValToChar(val(cTamPagina)+1)+" ROWS ONLY
    endif


return cQuery


static function validaCliente(cCodCliente,cLojaCliente,cCodVendedor)

    local aArea             := getArea()
    local lRetorno          := .T.
    local cFiltroSCJ        := "SCJ->CJ_CLIENTE == '" + cCodCliente + "' .and. SCJ->CJ_LOJA == '" + cLojaCliente + "' .and. dToS(SCJ->CJ_EMISSAO) >= '" + dToS(Date()-90) + "'
    local cVendedorAtual    := ""

    if Posicione("SA3",1,xFilial("SA3")+cCodVendedor,"A3_TIPO") == 'I' // Se o vendedor for interno, libera o cliente
        lRetorno := .T.
        return lRetorno
    endif
    
    dbSelectArea("SCJ")
    SCJ->(dbSetOrder(3)) // CJ_FILIAL + CJ_CLIENTE + CJ_LOJA + DTOS(CJ_EMISSAO)
    SCJ->(DbSetFilter({|| &(cFiltroSCJ)}, cFiltroSCJ))
    SCJ->(dbGoTop())

    while !SCJ->(eof())

        if SCJ->CJ_YVEND == cCodVendedor

            lRetorno := .T.
            Exit

        else

            if SCJ->CJ_YVEND != cCodVendedor .and. !empty(SCJ->CJ_YVEND) .and. !empty(posicione("SA3",1,xFilial("SA3")+SCJ->CJ_YVEND,"A3_COD"))

                cVendedorAtual := SA3->A3_NOME
                lRetorno := .F.

            endif

        endif

        SCJ->(dbSkip())

    enddo

    SCJ->(dbClearFilter())
    restArea(aArea)

return lRetorno


static function converterUTF8(xTexto)

    if Type("xTexto") == "C"

        return decodeUTF8(cTexto)

    endif

return xTexto


static function formatCEP(cCEP)

return strTran(strTran(cCEP, ".", ""), "-","")


static function formatTelefone(cTelefone)

    local cTelFormatado     := StrTokArr2(cTelefone,"/",.T.)[1]
    local cDDD              := ""
    local cNumero           := ""

    cTelFormatado   := strTran(cTelFormatado, "(", "")
    cTelFormatado   := strTran(cTelFormatado, ")", "")
    cTelFormatado   := strTran(cTelFormatado, "-", "")
    cTelFormatado   := strTran(cTelFormatado, " ", "")

    if !Empty(allTrim(cTelFormatado))

        cDDD            := left(cTelFormatado, 2)
        cNumero         := right(cTelFormatado, len(cTelFormatado) - 2)

        if len(cNumero) == 8 .And. left(cNumero, 1) >= "6"

            cNumero := "9" + cNumero

        endif

    endif

return {cDDD, cNumero}


static function getRegiao(cEstado)

    local cRegiao       := ""
    local aRegioes      := {}
    local nPosRegiao    := 0

    aRegioes := {;
        {"001", {"AC", "AP", "AM", "PA", "RO", "RR", "TO"}},;
        {"002", {"AL", "BA", "CE", "MA", "PB", "PE", "PI", "RN", "SE"}},;
        {"003", {"DF", "GO", "MT", "MS"}},;
        {"004", {"ES", "MG", "RJ", "SP"}},;
        {"005", {"PR", "RS", "SC"}};
    }

    nPosRegiao  := aScan(aRegioes, {|x| aScan(x[2], {|y| y == cEstado}) > 0})
    cRegiao     := aRegioes[nPosRegiao][1]

return cRegiao

static function formataCampo(cConteudo,cCampo)

    Local cNovoConteudo := ""

    cNovoConteudo := allTrim(padR(cConteudo, tamSX3(cCampo)[1]))

return cNovoConteudo

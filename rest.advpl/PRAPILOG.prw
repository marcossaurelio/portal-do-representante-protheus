#include 'Protheus.ch'
#include 'Restful.ch'

WsRestful login Description "Login"

    WsMethod Post Login   Description "Valida os dados de login no portal" Path "/"

End WsRestful


WsMethod Post Login WsService login

    local jResponse     := JsonObject():new()       As Json
    local cBody         := self:getContent()        As Character
    local jBody         := JsonObject():new()       As Json
    local cUser         := ""                       As Character
    local cPassword     := ""                       As Character
    local nTamUser      := 0                        As Numeric
    local lRet          := .T.
    
    if (!empty(cBody))

        // Transforma em JSON
        jBody := JsonObject():new()
        jBody:fromJson(cBody)

        if jBody != Nil

            if !empty(jBody:getJsonObject('user'))
                cUser := AllTrim(jBody:getJsonObject('user'))
            endif

            if !empty(jBody:getJsonObject('password'))
                cPassword := AllTrim(jBody:getJsonObject('password'))
            endif

        endif

    endif

    if !empty(cUser) .and. !empty(cPassword)

        DbSelectArea("SA3")

        nTamUser := len(cUser)

        if nTamUser > 6
            SA3->(DbSetOrder(3)) // Indice: A3_FILIAL + A3_CGC
        else
            SA3->(DbSetOrder(1)) // Indice: A3_FILIAL + A3_COD
        endif
        
        SA3->(DbGoTop())
        SA3->(DbSeek(xFilial("SA3")+cUser))

        if !SA3->(eof()) .and. AllTrim(SA3->A3_YPRPSW) == cPassword .and. AllTrim(SA3->A3_MSBLQL) != '1'

            jResponse["auth"]                   := .T.
            jResponse["authToken"]              := encode64(cUser+cPassword)
            jResponse["authTokenExpiration"]    := dToS(date()+6)
            jResponse["message"]                := "Usuário autenticado com sucesso!"
            jResponse["sellerId"]               := SA3->A3_COD
            jResponse["userName"]               := SA3->A3_NREDUZ

        else

            lRet := .F.

            jResponse["auth"] := lRet
            jResponse["message"] := "Usuário ou senha inválidos"

        endif

    else

        lRet := .F.

        jResponse["auth"] := lRet
        jResponse["message"] := "Usuário ou senha inválidos"

    endif

    self:setContentType('application/json')
    self:setResponse(jResponse:toJson())

    SA3->(DbCloseArea())

Return lRet

Static Function null()

Return Nil

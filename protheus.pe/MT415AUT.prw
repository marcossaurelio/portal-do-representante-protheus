#include 'protheus.ch'
 
User Function MT415AUT()
 
    Local lRet          := .T.
    Local cCliente      := SCJ->CJ_CLIENTE
    Local cLoja         := SCJ->CJ_LOJA
    Local cNomeCli      := Posicione("SA1", 1, xFilial("SA1") + cCliente + cLoja, "A1_NOME")
    Local lPendRevis    := Posicione("SA1", 1, xFilial("SA1") + cCliente + cLoja, "A1_YPENREV") == "S"

    If lPendRevis

        lRet := .F.
        MsgStop("O cliente " + cCliente + " - " + cNomeCli + " est� pendente de revis�o, n�o � poss�vel realizar a aprova��o do or�amento at� que a revis�o do cadastro seja realizada.", "Aten��o")

    EndIf

Return lRet

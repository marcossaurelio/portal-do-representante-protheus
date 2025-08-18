#include 'protheus.ch'
 
User Function MT415AUT()
 
    Local lRet          := .T.
    Local cCliente      := SCJ->CJ_CLIENTE
    Local cLoja         := SCJ->CJ_LOJA
    Local cNomeCli      := Posicione("SA1", 1, xFilial("SA1") + cCliente + cLoja, "A1_NOME")
    Local lPendRevis    := Posicione("SA1", 1, xFilial("SA1") + cCliente + cLoja, "A1_YPENREV") == "S"

    If lPendRevis

        lRet := .F.
        MsgStop("O cliente " + cCliente + " - " + cNomeCli + " está pendente de revisão, não é possível realizar a aprovação do orçamento até que a revisão do cadastro seja realizada.", "Atenção")

    EndIf

Return lRet

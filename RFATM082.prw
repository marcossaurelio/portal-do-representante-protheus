#include 'protheus.ch'

User Function RFATM082()
 
    Local aArea         := GetArea()
    Local cOrcamento    := SCJ->CJ_NUM
     
    nOpcao  := 0

    If SCJ->CJ_YPRSITU != "PE"

        MsgAlert("Só é permitida a rejeição de orçamentos com situação 'Pré-pedido em aprovação'.", "Rejeição não permitida")
        Return Nil
    
    EndIf

    If MsgYesNo("Confirma a rejeição o orçamento " + cOrcamento + "?", "Rejeitar Orçamento")

        If RecLock("SCJ", .F.)

            SCJ->CJ_YPRSITU := "PR" //Marca o orçamento como rejeitado
            SCJ->(MsUnlock())
            FwAlertSuccess("Orçamento " + cOrcamento + " rejeitado com sucesso.", "Sucesso")

        Else

            FWAlertError("Não foi possível concluir a rejeição do orçamento " + cOrcamento + "." + CRLF + "Erro no RecLock().", "Erro ao rejeitar orçamento")

        EndIf
    
    EndIf
 
    RestArea(aArea) //Restaura o ambiente ativo no início da chamada

Return Nil

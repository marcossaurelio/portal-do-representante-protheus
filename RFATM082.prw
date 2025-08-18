#include 'protheus.ch'

User Function RFATM082()
 
    Local aArea         := GetArea()
    Local cOrcamento    := SCJ->CJ_NUM
     
    nOpcao  := 0

    If SCJ->CJ_YPRSITU != "PE"

        MsgAlert("S� � permitida a rejei��o de or�amentos com situa��o 'Pr�-pedido em aprova��o'.", "Rejei��o n�o permitida")
        Return Nil
    
    EndIf

    If MsgYesNo("Confirma a rejei��o o or�amento " + cOrcamento + "?", "Rejeitar Or�amento")

        If RecLock("SCJ", .F.)

            SCJ->CJ_YPRSITU := "PR" //Marca o or�amento como rejeitado
            SCJ->(MsUnlock())
            FwAlertSuccess("Or�amento " + cOrcamento + " rejeitado com sucesso.", "Sucesso")

        Else

            FWAlertError("N�o foi poss�vel concluir a rejei��o do or�amento " + cOrcamento + "." + CRLF + "Erro no RecLock().", "Erro ao rejeitar or�amento")

        EndIf
    
    EndIf
 
    RestArea(aArea) //Restaura o ambiente ativo no in�cio da chamada

Return Nil

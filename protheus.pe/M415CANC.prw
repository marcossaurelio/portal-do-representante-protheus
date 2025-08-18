#INCLUDE 'PROTHEUS.CH'
 
User Function M415CANC()
 
    Local aArea         := GetArea()
    Local nOpcao        := PARAMIXB
    Local cOrcamento    := SCJ->CJ_NUM
     
    nOpcao  := 0

    If IsInCallStack("MATA415")

        If !IsBlind() //Valida se processo esta sendo executado em tela
    
            FWAlertInfo("Não é possível realizar o cancelamento de orçamentos." + CRLF + "Ao invés do cancelamento, realize a exclusão.", "Cancelamento não permitido")
    
        Else

            Conout("Não é possível realizar o cancelamento de orçamentos.")
            Conout("Ao invés do cancelamento, realize a exclusão.")

        EndIf

    Else

        If SCJ->CJ_YPRSITU == "PE"

            If RecLock("SCJ", .F.)

                SCJ->CJ_YPRSITU := "PR" //Marca o orçamento como rejeitado
                SCJ->(MsUnlock())
                FwAlertSuccess("Orçamento " + cOrcamento + " rejeitado com sucesso.", "Rejeição de Orçamento")

            Else

                FWAlertError("Não foi possível concluir a rejeição do orçamento " + cOrcamento + "." + CRLF + "Erro no RecLock().", "Erro ao rejeitar orçamento")

            EndIf  

        Else

            MsgAlert("Só é permitida a rejeição de orçamentos com situação 'Pré-pedido em aprovação'.", "Rejeição não permitida")
        
        EndIf

    EndIf
 
    RestArea(aArea) //Restaura o ambiente ativo no início da chamada

Return nOpcao

#INCLUDE 'PROTHEUS.CH'
 
User Function M415CANC()
 
    Local aArea         := GetArea()
    Local nOpcao        := PARAMIXB
    Local cOrcamento    := SCJ->CJ_NUM
     
    nOpcao  := 0

    If IsInCallStack("MATA415")

        If !IsBlind() //Valida se processo esta sendo executado em tela
    
            FWAlertInfo("N�o � poss�vel realizar o cancelamento de or�amentos." + CRLF + "Ao inv�s do cancelamento, realize a exclus�o.", "Cancelamento n�o permitido")
    
        Else

            Conout("N�o � poss�vel realizar o cancelamento de or�amentos.")
            Conout("Ao inv�s do cancelamento, realize a exclus�o.")

        EndIf

    Else

        If SCJ->CJ_YPRSITU == "PE"

            If RecLock("SCJ", .F.)

                SCJ->CJ_YPRSITU := "PR" //Marca o or�amento como rejeitado
                SCJ->(MsUnlock())
                FwAlertSuccess("Or�amento " + cOrcamento + " rejeitado com sucesso.", "Rejei��o de Or�amento")

            Else

                FWAlertError("N�o foi poss�vel concluir a rejei��o do or�amento " + cOrcamento + "." + CRLF + "Erro no RecLock().", "Erro ao rejeitar or�amento")

            EndIf  

        Else

            MsgAlert("S� � permitida a rejei��o de or�amentos com situa��o 'Pr�-pedido em aprova��o'.", "Rejei��o n�o permitida")
        
        EndIf

    EndIf
 
    RestArea(aArea) //Restaura o ambiente ativo no in�cio da chamada

Return nOpcao

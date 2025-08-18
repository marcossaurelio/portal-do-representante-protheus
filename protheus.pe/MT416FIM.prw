#include "protheus.ch"

User Function MT416FIM()
 
    Local aArea         := GetArea()
    Local cFilialOrc    := CJ_FILIAL
    Local cOrcamento    := CJ_NUM
 
    DbSelectArea("SCJ")
    SCJ->(DbSetOrder(1))
    SCJ->(DbGoTop())

    If SCJ->(DbSeek(cFilialOrc + cOrcamento))
        
        If RecLock("SCJ", .F.)
            SCJ->CJ_YPRSITU := "PA"
            SCJ->CJ_YDTALTE := Date()
            SCJ->(msUnlock())
        EndIf

    EndIf

    If SCJ->CJ_YPRSITU != "PA"

        FWAlertInfo("Ocorreu um erro ao atualizar o situação do orçamento " + cOrcamento + " para 'Aprovado'.", "Atenção")

    EndIf

    RestArea(aArea)
 
Return

#include "protheus.ch"

User Function RFATM080()

    AxCadastro( "Z01", "Cadastro de Regioes", "U_RFATM80C()", "U_RFATM80B()")

Return


User Function RFATM80B()

Return ExistChav("Z01", M->Z01_UF+M->Z01_COD, 2)


User Function RFATM80C()

    Local lRet          := .T.
    Local aArea         := GetArea()
    Local cFiltroCC2    := "CC2->CC2_YREGIA == '"+Z01->Z01_COD+"'"
    Local cFiltroZ02    := "Z02->Z02_RGDEST == '"+Z01->Z01_COD+"'"

    DbSelectArea("CC2")
    CC2->(DbSetOrder(2))
    CC2->(DbSetFilter({|| &(cFiltroCC2)}, cFiltroCC2))
    CC2->(DbGoTop())

    If !CC2->(EoF())

        If MsgYesNo("Existem cidades vinculadas a esta regiao." + CRLF + "Deseja seguir com a exclusao e desvincular a regiao dessas cidades?")

            While !CC2->(EoF())

                If RecLock('CC2',.F.)
                    
                    CC2->CC2_YREGIA := ""
                    CC2->(MsUnlock())

                EndIf

                CC2->(DbSkip())

            EndDo

            lRet := .T.

        Else

            lRet := .F.

        EndIf 
    
    EndIf

    If lRet

        DbSelectArea("Z02")
        Z02->(DbSetOrder(1))
        Z02->(DbSetFilter({|| &(cFiltroZ02)}, cFiltroZ02))
        Z02->(DbGoTop())

        While !Z02->(EoF())

            If RecLock('Z02',.F.)

                DbDelete()
                Z02->(MsUnlock())

            EndIf

            Z02->(DbSkip())

        EndDo

    EndIf

    RestArea(aArea)

Return lRet


User Function RFATM80A()

    Local aArea     := GetArea()
    Local cEstado   := M->Z01_UF
    Local nNumero   := 1
    Local cCodRet   := ""
    Local cQuery    := ""
    Local cAlias    := GetNextAlias()

    cQuery += " SELECT MAX(Z01_COD) AS MAXCOD FROM "+RetSQLName("Z01")+" WHERE Z01_FILIAL = '"+xFilial("Z01")+"' AND Z01_UF = '"+cEstado+"' AND Z01_COD LIKE '"+cEstado+"%' "

    DbUseArea(.T., "TOPCONN", TCGenQry( , , cQuery), (cAlias), .F., .T.)

    If !(cAlias)->(EoF())

        nNumero := Val(Right((cAlias)->MAXCOD,4)) + 1

    Else

        nNumero := 1

    EndIf

    cCodRet := cEstado + StrZero(nNumero, 4)

    RestArea(aArea)

Return cCodRet

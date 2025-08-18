#include "protheus.ch"

User Function RFATM081()

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

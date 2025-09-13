#include "protheus.ch"

User Function RFATM083()

    AxCadastro( "Z04", "Definicoes Portal", ".T.", "U_RFATM83A() .And. U_RFATM83B()")

Return


User Function RFATM83A()

Return ExistChav("Z04", M->Z04_COD, 1)


User Function RFATM83B()

    Local cTipo     := M->Z04_TIPO
    Local cConteudo := AllTrim(M->Z04_CONTEU)
    Local lRet      := .T.
    Local nPos      := 1

    If Empty(cConteudo) .Or. Empty(cTipo)

        lRet := .T.
        Return lRet        

    EndIf

    Do Case

        Case cTipo == "C"

            lRet := .T.

        Case cTipo == "N"

            For nPos := 1 To Len(cConteudo)

                If !IsDigit(SubStr(cConteudo,nPos,1)) .And. SubStr(cConteudo,nPos,1) != "." 

                    lRet := .F.
                    Exit

                EndIf

            Next

        Case cTipo == "D"

            lRet := CToD(cConteudo) != CToD("")

        Case cTipo == "L"

            lRet := cConteudo == "S" .Or. cConteudo == "N"

    EndCase

    If !lRet

        FWAlertWarning("Conteúdo inválido para o tipo selecionado.","Definições Portal")

    EndIf

Return lRet


User Function DefPort(cDefinicao, xContPad)

    Local aAreaZ04  := Z04->(GetArea())
    Local cTipo     := ""
    Local xRet      := ""

    Default cDefinicao  := ""
    Default xContPad    := ""

    If Empty(cDefinicao)

        Return xContPad        

    EndIf

    DbSelectArea("Z04")
    Z04->(dbSetOrder(1))
    Z04->(dbGoTop())

    If !Z04->(dbSeek( xFilial("Z04") + PadR(cDefinicao,TamSX3("Z04_COD")[1]," ") ))

        RestArea(aAreaZ04)
        Return xContPad

    EndIf

    cTipo := Z04->Z04_TIPO

    Do Case

        Case cTipo == "C"

            xRet := AllTrim(Z04->Z04_CONTEU)

        Case cTipo == "N"

            xRet := Val(AllTrim(Z04->Z04_CONTEU))

        Case cTipo == "D"

            xRet := CToD(AllTrim(Z04->Z04_CONTEU))

        Case cTipo == "L"

            xRet := AllTrim(Z04->Z04_CONTEU) == "S"

    EndCase

    RestArea(aAreaZ04)

Return xRet

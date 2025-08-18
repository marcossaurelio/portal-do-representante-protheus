#Include 'Protheus.ch'

User Function AutoDA1()

    Local cCampo        := Substr(__READVAR, 4) // Campo que disparou a funcao
    Local nPosCampo     := 0                    // Posicao do campo em aCols
    Local xRet          := &(cCampo)            // Valor para preencher o campo 
    Local xRetPadrao    := &(cCampo)            // Valor padrão do campo
    Local nUltimoReg    := Len(aCols)           // Índice do último registro da inserido na tabela

    If nUltimoReg == 0
        Return xRetPadrao
    EndIf

    nPosCampo := AScan(aHeader,{|x| AllTrim(x[2]) == cCampo})

    If nPosCampo == 0
        Return xRetPadrao
    EndIf

    xRet := aCols[nUltimoReg][nPosCampo]

Return xRet

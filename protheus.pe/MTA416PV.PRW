#Include "PROTHEUS.CH"  
 
User Function MTA416PV()
 
    Local aArea         := GetArea()
    Local nItem         := PARAMIXB
    Local cProduto      := _aCols[nItem][PosCampo("C6_PRODUTO")]
    Local cFormaProd    := Posicione("SB1",1,xFilial("SB1")+cProduto,"B1_YFORMAT")
    Local cPadPallet    := "0"

    Do Case
        Case cFormaProd == "10X1"
            cPadPallet := cValToChar(CJ_YPP10X1)
        Case cFormaProd == "30X1"
            cPadPallet := cValToChar(CJ_YPP30X1)
        Case cFormaProd == "25KG"
            cPadPallet := cValToChar(CJ_YPP25KG)
    EndCase

    C5_VEND1    := CJ_YVEND
    C5_TPFRETE  := CJ_TPFRETE
    C5_YVFTONM  := CJ_FRETE
    C5_YCPGFRT  := CJ_YCPAGFR
    C5_YTPEMBQ  := CJ_YTPVEIC
    C5_YVFTONC  := CJ_FRETE + CJ_YSBPORT
    C5_YNUMORC  := CJ_NUM
    C5_DESCFI   := CJ_YDESCF
    C5_YOBSEMB  := CJ_YOBS
    C5_YDESCVT  := CJ_YVDESCA
    C5_YDESCAR  := CJ_YDESCAR

    _aCols[nItem][PosCampo("C6_YTPCARG")] := CJ_YTPCARG
    _aCols[nItem][PosCampo("C6_YPADPLT")] := cPadPallet

    RestArea(aArea)

Return Nil


Static Function PosCampo(cCampo)

Return AScan(_aHeader, {|x| AllTrim(x[2]) == cCampo})

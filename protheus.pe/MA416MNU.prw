#INCLUDE 'PROTHEUS.CH'
 
User Function MA416MNU()
 
    Local aArea         := GetArea()
    Local nPosCanc      := aScan(aRotina, {|x| AllTrim(Upper(x[2])) == "A415CANCEL"})
    Local nPosAuto      := aScan(aRotina, {|x| AllTrim(Upper(x[2])) == "MA416AUTO"})

    aRotina[nPosCanc][1]    := "Rejeitar"
    aRotina[nPosCanc][2]    := "U_RFATM082"

    ADel(aRotina,   nPosAuto)
    ASize(aRotina,  Len(aRotina)-1)

    RestArea(aArea) //Restaura o ambiente ativo no início da chamada

Return Nil

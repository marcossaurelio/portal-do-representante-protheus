#INCLUDE 'PROTHEUS.CH'
 
User Function MA415MNU()
 
    Local aArea         := GetArea()
    Local nPosCanc      := aScan(aRotina, {|x| AllTrim(Upper(x[2])) == "A415CANCEL"})

    ADel(aRotina,   nPosCanc)
    ASize(aRotina,  Len(aRotina)-1)

    RestArea(aArea) //Restaura o ambiente ativo no início da chamada

Return Nil

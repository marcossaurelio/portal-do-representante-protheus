#include 'protheus.ch'

User Function OM010MNU()

    Local nPosReajus := AScan(aRotina, {|x| AllTrim(x[1]) == "Reajuste"})
    Local cFunReajus := "U_REAJUTAB"

    aRotina[nPosReajus][1] += " #"
    aRotina[nPosReajus][2] := cFunReajus

    aAdd(aRotina, {"Get Preco Tabela", "u_GetPrcTb", 0, 6, 32, Nil})

Return Nil

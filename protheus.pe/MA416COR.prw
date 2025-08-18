#INCLUDE 'PROTHEUS.CH'
 
User Function MA416COR()
 
    Local aArea         := GetArea()
    // Local aCores        := PARAMIXB
    Local aCoresNew     := {}

    AAdd(aCoresNew, { "SCJ->CJ_VALIDA < Date() .And. SCJ->CJ_YPRSITU $ 'CP;PP;PE'", "BR_PRETO"      })
    AAdd(aCoresNew, { "SCJ->CJ_YPRSITU == 'CP'",                                    "BR_AMARELO"    })
    AAdd(aCoresNew, { "SCJ->CJ_YPRSITU == 'CR'",                                    "BR_CINZA"      })
    AAdd(aCoresNew, { "SCJ->CJ_YPRSITU == 'PP'",                                    "BR_LARANJA"    })
    AAdd(aCoresNew, { "SCJ->CJ_YPRSITU == 'PE'",                                    "BR_AZUL"       })
    AAdd(aCoresNew, { "SCJ->CJ_YPRSITU == 'PR'",                                    "BR_VERMELHO"   })
    AAdd(aCoresNew, { "SCJ->CJ_YPRSITU == 'PA'",                                    "BR_VERDE"      })
    AAdd(aCoresNew, { "Empty(SCJ->CJ_YPRSITU)",                                     "BR_BRANCO"     })

    RestArea(aArea) //Restaura o ambiente ativo no início da chamada

Return aCoresNew

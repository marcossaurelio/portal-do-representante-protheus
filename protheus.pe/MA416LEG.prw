#INCLUDE 'PROTHEUS.CH'
 
User Function MA416LEG()
 
    Local aArea         := GetArea()
    // Local aLegenda      := PARAMIXB
    Local aLegendNew    := {}

    AAdd(aLegendNew,    { "BR_PRETO",       "Or�amento Expirado"        })
    AAdd(aLegendNew,    { "BR_AMARELO",     "Cota��o Pendente"          })
    AAdd(aLegendNew,    { "BR_CINZA",       "Cota��o Rejeitada"         })
    AAdd(aLegendNew,    { "BR_LARANJA",     "Pr�-pedido Pendente"       })
    AAdd(aLegendNew,    { "BR_AZUL",        "Pr�-pedido Em Aprova��o"   })
    AAdd(aLegendNew,    { "BR_VERMELHO",    "Pr�-pedido Rejeitado"      })
    AAdd(aLegendNew,    { "BR_VERDE",       "Pr�-pedido Aprovado"       })
    AAdd(aLegendNew,    { "BR_BRANCO",      "Status N�o Informado"      })

    RestArea(aArea) //Restaura o ambiente ativo no in�cio da chamada

Return aLegendNew

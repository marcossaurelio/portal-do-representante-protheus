#INCLUDE 'PROTHEUS.CH'
 
User Function MA416LEG()
 
    Local aArea         := GetArea()
    // Local aLegenda      := PARAMIXB
    Local aLegendNew    := {}

    AAdd(aLegendNew,    { "BR_PRETO",       "Orçamento Expirado"        })
    AAdd(aLegendNew,    { "BR_AMARELO",     "Cotação Pendente"          })
    AAdd(aLegendNew,    { "BR_CINZA",       "Cotação Rejeitada"         })
    AAdd(aLegendNew,    { "BR_LARANJA",     "Pré-pedido Pendente"       })
    AAdd(aLegendNew,    { "BR_AZUL",        "Pré-pedido Em Aprovação"   })
    AAdd(aLegendNew,    { "BR_VERMELHO",    "Pré-pedido Rejeitado"      })
    AAdd(aLegendNew,    { "BR_VERDE",       "Pré-pedido Aprovado"       })
    AAdd(aLegendNew,    { "BR_BRANCO",      "Status Não Informado"      })

    RestArea(aArea) //Restaura o ambiente ativo no início da chamada

Return aLegendNew

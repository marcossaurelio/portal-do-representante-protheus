#INCLUDE "PROTHEUS.CH"

User Function CRM980BLabel()

    Local aRet      := {}

    aAdd(aRet,  { "SA1->A1_YPENREV=='S'",   "YELLOW", "Pendente de Revis�o"  })
    aAdd(aRet,  { "SA1->A1_MSBLQL!='1'",    "GREEN",  "Ativo"                })
    aAdd(aRet,  { "SA1->A1_MSBLQL=='1'",    "RED",    "Inativo"              })
    
Return aRet

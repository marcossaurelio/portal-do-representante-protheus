#include "protheus.ch"
#INCLUDE "FWMBROWSE.CH"
#INCLUDE "FWMVCDEF.CH"

/*/{Protheus.doc} RFATM084
Rotina de manutenção de arquivos de tabelas de preço do portal do representante
@type function
@author Marcos Aurélio (MConsult)
@since 21/11/2025
/*/
User Function RFATM084()

	Local oBrowse
	oBrowse := FWMBrowse():New()
	oBrowse:SetAlias('Z03')
	oBrowse:SetDescription('Arquivos de Tabelas de Preço')
	oBrowse:DisableDetails()

	oBrowse:SetMenuDef( 'RFATM084' )
	oBrowse:Activate()

Return


Static Function MenuDef()

	Local aRotina := {}

	ADD OPTION aRotina TITLE "Visualizar" 		ACTION "VIEWDEF.RFATM084"	OPERATION 2 ACCESS 0
	ADD OPTION aRotina TITLE "Incluir"    		ACTION "VIEWDEF.RFATM084"	OPERATION 3 ACCESS 0
	ADD OPTION aRotina TITLE "Alterar"    		ACTION "VIEWDEF.RFATM084"	OPERATION 4 ACCESS 0
	ADD OPTION aRotina TITLE "Excluir"    		ACTION "VIEWDEF.RFATM084"	OPERATION 5 ACCESS 0
	ADD OPTION aRotina TITLE "Copiar"			ACTION "VIEWDEF.RFATM084"	OPERATION 9 ACCESS 0
	ADD OPTION aRotina TITLE "Upload Arquivo"	ACTION "U_RFATM84A"			OPERATION 4 ACCESS 0
	ADD OPTION aRotina TITLE "Download Arquivo"	ACTION "U_RFATM84B"			OPERATION 4 ACCESS 0
	ADD OPTION aRotina TITLE "Excluir Arquivo"	ACTION "U_RFATM84C"			OPERATION 4 ACCESS 0

Return aRotina


Static Function ModelDef()

	Local oStructZ03 := Nil
	Local oModel := ""

	oStructZ03 := FWFormStruct(1,"Z03")

	oModel:= MPFormModel():New("YCADZ03",/*Pre-Validacao*/,/*Pos-Validacao*/,/*Commit*/,/*Cancel*/)

	oModel:AddFields("Z03MASTER",/*cOwner*/, oStructZ03 ,/*Pre-Validacao*/,/*Pos-Validacao*/,/*Carga*/)

	oModel:SetPrimaryKey({"Z03_COD"})

Return (oModel)


Static Function ViewDef()

	Local oStructZ03	:= FWFormStruct( 2, 'Z03' )
	Local oModel		:= FWLoadModel( 'RFATM084' )

	Local oView

	oView	:= FWFormView():New()

	oView:SetModel(oModel)
	oView:EnableControlBar(.T.)

	oView:AddField( "Z03MASTER",oStructZ03 )

Return oView

User Function RFATM84A()

	Local cArqAtual		:= Z03->Z03_ARQUIV
	Local cNovoArq		:= ""
	Local cDirDest		:= "/tabelas-portal/"
	Local cTipoArq		:= "Todas extensões (*.*) | Arquivos PDF (*.pdf)"
	Local cTituloDlg	:= "Selecione o arquivo para upload"
	Local lSalvar		:= .F.
	Local lSucesso		:= .F.

	If !Empty(cArqAtual)

		FErase(cArqAtual)

	EndIf

	cNovoArq := TFileDialog(cTipoArq,cTituloDlg,,,lSalvar)

	If Empty(cNovoArq)

		Return

	EndIf

	lSucesso := __CopyFile(cNovoArq, cDirDest + ExtractFile(cNovoArq))

	If !lSucesso

		FwAlertError("Não foi possível realizar o upload do arquivo.", "Erro no upload")
		Return

	EndIf

	RecLock("Z03", .F.)
	Z03->Z03_ARQUIV := cDirDest + ExtractFile(cNovoArq)
	Z03->Z03_DTALTE := Date()
	Z03->(MsUnlock())

	FwAlertSuccess("Upload do arquivo realizado com sucesso.", "Sucesso")

Return


User Function RFATM84B()

	Local cArqServ		:= Z03->Z03_ARQUIV
	Local cArqClient	:= ""
	Local cTipoArq		:= "Todas extensões (*.*) | Arquivos PDF (*.pdf)"
	Local cTituloDlg	:= "Selecione o local para download do arquivo"
	Local lSalvar		:= .F.
	Local nOpcoes		:= GETF_RETDIRECTORY
	Local cDirClient	:= ""
	Local lSucesso		:= .F.

	If Empty(cArqServ)

		FwAlertInfo("Não há arquivo vinculado à tabela.", "Arquivo inexistente")
		Return

	EndIf

	If !File(cArqServ)

		FwAlertError("Arquivo vinculado à tabela não encontrado no servidor.", "Erro no download")
		Return

	EndIf

	cDirClient := TFileDialog(cTipoArq,cTituloDlg,,,lSalvar,nOpcoes)

	If Empty(cDirClient)

		Return

	EndIf

	cArqClient := cDirClient + "\" + ExtractFile(cArqServ)

	lSucesso := __CopyFile(cArqServ, cArqClient)

	If !lSucesso

		FwAlertError("Não foi possível realizar o download do arquivo.", "Erro no download")
		Return

	EndIf

	FwAlertSuccess("Download do arquivo realizado com sucesso." + CRLF;
					+ "Caminho: " + cArqClient;
					, "Sucesso")

Return


User Function RFATM84C()

	Local cArqAtual		:= Z03->Z03_ARQUIV

	If Empty(cArqAtual)

		FwAlertInfo("Não há arquivo vinculado à tabela.", "Arquivo inexistente")
		Return

	EndIf

	FErase(cArqAtual)

	If File(cArqAtual)

		FwAlertError("Não foi possível excluir o arquivo vinculado à tabela.", "Erro na exclusão")
		Return

	EndIf

	RecLock("Z03", .F.)
	Z03->Z03_ARQUIV := ""
	Z03->Z03_DTALTE := Date()
	Z03->(MsUnlock())

	FwAlertSuccess("Arquivo vinculado à tabela excluído com sucesso.", "Sucesso")

Return

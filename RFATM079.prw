#INCLUDE 'Protheus.ch'
#INCLUDE 'FwMvcDef.ch'

/*/{Protheus.doc} RFATM079
    Rotina de pedidos de compra customizado em MVC
    @author Leonardo Bilar
    @since 22/02/2024
    /*/
User Function RFATM079()

    Local oBrowse := FWMBrowse():New()
    Local aRotina := Nil
    
    aRotina := MenuDef()

    oBrowse:SetAlias('Z00')
    oBrowse:SetDescription('Tabelas de Frete')

    oBrowse:Activate()

Return

/*/{Protheus.doc} MenuDef
    Menu que serù apresentado na tela inicial da rotina (Browse)
    @author Leonardo Bilar
    @since 22/02/2024
    @return aRotina, Array, Array com as opùùes do menu
    /*/
Static Function MenuDef()

    Local aRotina := {}

    ADD OPTION aRotina TITLE 'Incluir'      ACTION 'VIEWDEF.RFATM079' OPERATION MODEL_OPERATION_INSERT   ACCESS 0
    ADD OPTION aRotina TITLE 'Visualizar'   ACTION 'VIEWDEF.RFATM079' OPERATION MODEL_OPERATION_VIEW     ACCESS 0
    ADD OPTION aRotina TITLE 'Alterar'      ACTION 'VIEWDEF.RFATM079' OPERATION MODEL_OPERATION_UPDATE   ACCESS 0
    ADD OPTION aRotina TITLE 'Excluir'      ACTION 'VIEWDEF.RFATM079' OPERATION MODEL_OPERATION_DELETE   ACCESS 0

Return aRotina


/*/{Protheus.doc} ModelDef
    Define o Modelo de dados
    @author Leonardo Bilar
    @since 22/02/2024
    @return oModel, Object, Modelo de dados
    /*/
Static Function ModelDef()

    Local oModel    := Nil

    // Estrutura para os campos das tabela Z00 - Model
    Local oStruZ00  :=  FWFormStruct(1, 'Z00')

    // Estrutura para os campos das tabela Z02 - Model
    Local oStruZ02  :=  FWFormStruct(1, 'Z02')

    // Inicia a criaùùo do Model
    oModel := MPFormModel():New('MRFATM079')

    // Adiciona ao Model os campos da Z00 em formato Field
    oModel:AddFields('Z00_MASTER', /*cOwner*/, oStruZ00)

    // Adiciona ao Model os campos da Z02 em formato Grid
    oModel:AddGrid('Z02_ITENS', 'Z00_MASTER', oStruZ02)

    // Define o relacionamento entra as tabelas Z02 (filho) e Z00 (pai)
    oModel:SetRelation('Z02_ITENS', {{'Z02_FILIAL', 'xFilial("Z02")'}, {'Z02_UFDEST', 'Z00_UFDEST'}}, Z02->(IndexKey(1)))

    // Define a chave primùria
    oModel:SetPrimaryKey({'Z00_FILIAL', 'Z00_UFDEST'})

    // Descriùùes do Model
    oModel:SetDescription('Tabelas de Frete')

Return oModel

/*/{Protheus.doc} ViewDef
    Define a View
    @author Leonardo Bilar
    @since 22/02/2024
    @return oView, Object, View para ser exibida ao usuùrio
    /*/
Static Function ViewDef()

    Local oView     := Nil

    // Recebe o Model para atribuir a View
    Local oModel    := ModelDef()

    // Estrutura para os campos das tabela Z00 - View
    Local oStruZ00  := FWFormStruct(2, 'Z00')

    // Estrutura para os campos das tabela Z02 - View
    Local oStruZ02  := FWFormStruct(2, 'Z02')
    
    // Inicia a criaùùo do Model
    oView := FWFormView():New()

    // Define o model que serù utilizado na View
    oView:SetModel(oModel)

    // Adiciona a View os campos definidos no Model Z00_MASTER
    oView:AddField('Z00_VIEW', oStruZ00, 'Z00_MASTER')

    // Adiciona a View os campos definidos no Model Z02_ITENS
    oView:AddGrid('Z02_VIEW', oStruZ02, 'Z02_ITENS')

    // Define um campo da tabela que serù preenchido automaticamente de forma incremental
    oView:AddIncrementalField('Z02_VIEW', 'Z02_ITEM')

    // Cria na tela 2 caixas na horizontal sendo 25% para cabeùalho e 75% para o grid de itens
    oView:CreateHorizontalBox('CABEC', 25)
    oView:CreateHorizontalBox('ITENS', 75)

    // Atribui cada view a sua caixa para apresentar os dados na tela
    oView:SetOwnerView('Z00_VIEW', 'CABEC')
    oView:SetOwnerView('Z02_VIEW', 'ITENS')

Return oView

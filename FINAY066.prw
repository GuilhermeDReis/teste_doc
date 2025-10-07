#INCLUDE "Protheus.ch"
#INCLUDE "RWMAKE.CH"
#INCLUDE "TBICONN.CH"

 
User Function FINAY066(aTit, aNcc) //{xFilial("SL1"), SF2->F2_SERIE, SF2->F2_DOC}, {SE1->E1_FILIAL, SE1->E1_PREFIXO, SE1->E1_NUM}


Local lRet := .T.
Local aArea  := GetArea()
Local nTaxaCM := 0
Local aTxMoeda := {}
Local nSaldoComp:= 0
Local dDtComp := CTOD("  /  /    ")
Local nDesc1 := 0
Local nDesc2 := 0

Private nRecnoNDF
Private nRecnoE1
  
    dbSelectArea("SE1")
    dbSetOrder(1) // E1_FILIAL, E1_CLIENTE, E1_LOJA, E1_PREFIXO, E1_NUM, E1_PARCELA, E1_TIPO, R_E_C_N_O_, D_E_L_E_T_
    IF dbSeek(aNcc[1]+aNcc[2]+aNcc[3])
        nRecnoNcc := RECNO()
        dDtComp := SE1->E1_EMISSAO
        nSaldoComp := SE1->E1_VALOR
        IF dbSeek(aTit[1]+aTit[2]+aTit[3])
            nRecnoE1 := RECNO()
            nDesc1 := SE1->E1_DESCFIN
            nDesc2 := SE1->E1_DIADESC

            //limpa o desconto para não sobrar saldo 
            Reclock("SE1",.F.)
                SE1->E1_DESCFIN := 0
                SE1->E1_DIADESC := 0                
            SE1->(MsUnlock())

            If SE1->E1_VALOR <> SE1->E1_SALDO
                MsgInfo("Titulo possui baixa parcial, Ncc não será compensada!","FINAY066")
                Return lRet
            EndIf
            PERGUNTE("FIN330",.F.)
            lContabiliza    := (MV_PAR09 == 1) // Contabiliza On Line ?
            lDigita         := (MV_PAR07 == 1) // Mostra Lanc Contab ?
            lAglutina       := .F.
 
            SE1->(dbSetOrder(1)) //E1_FILIAL+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO+E1_FORNECE+E1_LOJA
 
            //NF X RA
            aRecNcc := { nRecnoNcc }
            aRecSE1 := { nRecnoE1 }

            nTaxaCM := RecMoeda(dDataBase,SE1->E1_MOEDA)
            aAdd(aTxMoeda, {1, 1} )
            aAdd(aTxMoeda, {2, nTaxaCM} )
            /*
            //RA X NF
            aRecRA := { nRecnoE1 }
            aRecSE1 := { nRecnoRA }
            */
 
            //Data a ser considerada na compensação
            dDataBase := dDtComp
 
            If !MaIntBxCR(3, aRecSE1,,aRecNcc,,{lContabiliza,lAglutina,lDigita,.F.,.F.,.F.},,,,,nSaldoComp,,,,,)
                Help("XAFCMPAD",1,"HELP","XAFCMPAD","Não foi possível a compensação"+CRLF+" do titulo!",1,0)
                lRet := .F.
                //Volta o desconto para o titulo
                Reclock("SE1",.F.)
                    SE1->E1_DESCFIN := nDesc1
                    SE1->E1_DIADESC := nDesc2              
                SE1->(MsUnlock())
            EndIf
            //Volta o desconto para o titulo
            Reclock("SE1",.F.)
                SE1->E1_DESCFIN := nDesc1
                SE1->E1_DIADESC := nDesc2                
            SE1->(MsUnlock())

        EndIf
    EndIf
 
    RestArea(aArea)
 
Return lRet

;-----------------------------------------------------------------------------
;
;  FILE NAME   :  LIB_VOSSP_SM4.ASM 
;  TARGET MCU  :  C8051F020 
;  

;-----------------------------------------------------------------------------
$include (c8051f020.inc)               ; Include register definition file. 
;-----------------------------------------------------------------------------
;******************************************************************************
;Declaration des variables et fonctions publiques
;******************************************************************************
PUBLIC   _Read_code
PUBLIC   _Read_Park_IN
PUBLIC   _Read_Park_OUT
PUBLIC   _Decod_BIN_to_BCD
PUBLIC   _Display
PUBLIC   _Test_Code
PUBLIC   _Stockage_Code

;-----------------------------------------------------------------------------
; EQUATES
;-----------------------------------------------------------------------------
GREEN_LED      	equ   	P1.6             ; Port I/O pin connected to Green LED.

;-----------------------------------------------------------------------------
; CODE SEGMENT
;-----------------------------------------------------------------------------
ProgSP_base      segment  CODE

               rseg     ProgSP_base      ; Switch to this code segment.
               using    0              ; Specify register bank for the following
                                       ; program code.
;------------------------------------------------------------------------------
;******************************************************************************                
; _Read_code
;
; Description: 
;
; Param�tres d'entr�e:  R6 (MSB)- R7 (LSB) � Adresse du p�riph�rique d�entr�e
; Valeur retourn�e: R7 : contient la valeur du code lu (sur les 6 bits de poids faible). 
; Registres modifi�s: aucun
;******************************************************************************    

_Read_code:	
			Push ACC
			mov DPH,R6
			mov DPL, R7
			movx A,@DPTR
			RR A
			Clr C
			mov ACC.6,C
			mov ACC.7,C
			mov R7,A
			Pop ACC
			RET
;******************************************************************************    			  
			  
;******************************************************************************                
; _Read_Park_IN
;
; Description: 
;
; Param�tres d'entr�e:  R6 (MSB)- R7 (LSB) � Adresse du p�riph�rique d�entr�e
; Valeur retourn�e: Bit Carry  0: pas de d�tection / 1: v�hicule d�tect� 
; Registres modifi�s: aucun
;******************************************************************************    

_Read_Park_IN:	
				Push ACC
				mov DPH,R6
				mov DPL, R7
				movx A,@DPTR
				mov C,ACC.0
				Pop ACC
				RET
;******************************************************************************    						  
			  
;******************************************************************************                
; _Read_Park_OUT
;
; Description: 
;
; Param�tres d'entr�e:  R6 (MSB)- R7 (LSB) � Adresse du p�riph�rique d�entr�e
; Valeur retourn�e: Bit Carry  0: pas de d�tection / 1: v�hicule d�tect� 
; Registres modifi�s: aucun
;******************************************************************************    

_Read_Park_OUT:
				Push ACC
				mov DPH,R6
				mov DPL, R7
				movx A,@DPTR
				mov C,ACC.7
				pop Acc
				RET
;****************************************************************************** 

;******************************************************************************                
; _Decod_BIN_to_BCD 
;
; Description: 
;
; Param�tres d'entr�e:  R6 (MSB)- R7 (LSB) � Adresse CODE de la table de conversion
;                                            "Display_7S"
; Param�tres d'entr�e:  R5  � Valeur 4 bits � convertir (4bits de poids faible)
; Valeur retourn�e: R7 - Code 7 segments (Bit 0-Segment a __ Bit6-Segment g)
; Registres modifi�s: aucun
;******************************************************************************    

_Decod_BIN_to_BCD:	
					Push ACC
					;recuperation adresse
					mov DPH,R6
					mov DPL,R7
					; on mets � 0 les 4 bits de poids forts pour garder que ceux de poids faibles
					; ACC de 00h a 0FH
					mov A,R5
					CLR C
					mov ACC.7,C
					mov ACC.6,C
					mov ACC.5,C
					mov ACC.4,C
					;on cherche l'adresse du code coresspondant � la valeur dans display
					;on ajoute a la valeur de DPTR la valeur des bits de poids faibles
					ADD A,DPL
					mov DPL,A
					mov A,DPH
					ADDC A,#0
					mov DPH,A
					;on recupere l'information contenu dans display
					mov A,#0
					movc A,@A+DPTR
					mov R7,A
					Pop ACC
					RET

;****************************************************************************** 

;******************************************************************************                
; _Display  
;
; Description: 
;
; Param�tres d'entr�e:  R6 (MSB)- R7 (LSB) � Adresse du p�riph�rique de sortie
; Param�tre d�entr�e :  R5 � Code 7 segments (les 7 bits de poids faible)
; Param�tre d�entr�e :  R3 � Code LED : si 0, LED �teinte, si non nul : LED allum�e
; Valeur retourn�e: R7 : contient une recopie de la valeur envoy�e au p�riph�rique de sortie. 
; Registres modifi�s: aucun
;******************************************************************************    

_Display:
			Push ACC
			;recuperation adresse
			mov DPH,R6
			mov DPL,R7
			;Verif LED allumee ou pas
			mov A,R5
			CJNE R3,#0,LED_Allumee
			CLR C
			Jmp Sortie
			LED_Allumee: 
				SETB C	
			Sortie:	
			;ajout de valeur LED
			mov ACC.7,C
			;sauvegarde interne et sur X_DATA
			mov R7,A
			movx @DPTR,A
			;retour
			Pop Acc
            RET
;****************************************************************************** 

;******************************************************************************                
; _Test_Code  
;
; Description: 
;
; Param�tres d'entr�e:  R6 (MSB)- R7 (LSB) � Adresse de Tab_code
; Param�tre d�entr�e :  R5  � Code � v�rifier (sur 6 bits)
; Valeur retourn�e: R7 : non nul, il retourne la position du code trouv� dans la table,
;                        nul, il indique que le code n�a pas �t� trouv� dans la table.
; Registres modifi�s: aucun
;******************************************************************************    

_Test_Code:
			;sauvegarde Data
			Push ACC
			mov A,R0
			Push ACC
			mov A,R1
			Push ACC
			
			;initialise DPTR avec la premi�re adresse de Tab_code
			mov DPH,R6
			mov DPL,R7
			;on recupere l'info sur le nombre de code contenu par Tab_code
			mov A,#0
			movc A,@A+DPTR
			mov R0,A ; R0 contient nb data dans Tab_code
			mov R1,#0 ;permet de savoir si on a tt parcouru ou pas 
			Verif_code_in:
				INC DPTR
				INC R1
				;on verifie qu'on est tjs dans Tab_code
				mov A,R0
				ADD A,#1h
				SUBB A,R1
				JZ Code_non_trouve ; si on est sortie, alors notre code 
				;n'existe pas dans nos donnees
				;recupere donnes et sauvegarde dans R7
				mov A,#0
				movc A,@A+DPTR
				mov R7,A
				;on verifie si c'est le bon sinon on continue de chercher
				SUBB A,R5 
				JNZ Verif_code_in 
				Jmp By
				Code_non_trouve:
					mov R7,#0 ;enregistrement de l'erreur
			By:
			;recup Data
			Pop ACC
			mov R1,A
			Pop ACC
			mov R0,A
			Pop ACC
            RET
;****************************************************************************** 

;******************************************************************************                
; _Stockage_Code 
;
; Description: 
;
; Param�tres d'entr�e:  R6 (MSB)- R7 (LSB) � Adresse de Tab_histo
; Param�tre d�entr�e :  R5 � Code � enregistrer
; Valeur retourn�e: R7 : R7 : non nul, il retourne le nombre d�enregistrements,
;                             nul, il indique que la table est pleine (100 enregistrements). 
; Registres modifi�s: aucun
;******************************************************************************    

_Stockage_Code:
				;sauvegarde
				Push ACC
				mov A,R0
				Push ACC
				
				;recup donnees
				mov DPH,R6
				mov DPL,R7
				movx A,@DPTR
				mov R0,A ;R0 contient l'index
				
				;erreur table ?
				SUBB A,#64h
				JZ Trop_plein ; si table est pleine, on renvoie l'ereur
				
				;incrementation index et envoie dans XDATA
				INC R0 
				mov A,R0
				movx @DPTR,A
				
				;on ajoute � DPTR la valeur de l'index pour ranger 
				;le code apres la derniere entree
				mov A,R0
				ADD A,DPL
				mov DPL,A
				mov A,#0
				ADDC A,DPH
				mov DPH,A
				
				;envoie des donnes dans X_DATA
				mov A,R5
				movx @DPTR,A
				
				;renvoie de l'index
				mov A,R0
				mov R7,A
				Jmp Tschuss
				
				Trop_plein: 
					mov R7,#0
				
				Tschuss:
				;recup donees
				Pop ACC
				mov R0,A
				Pop ACC
				RET
;****************************************************************************** 


END




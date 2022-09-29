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
; Paramètres d'entrée:  R6 (MSB)- R7 (LSB) – Adresse du périphérique d’entrée
; Valeur retournée: R7 : contient la valeur du code lu (sur les 6 bits de poids faible). 
; Registres modifiés: aucun
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
; Paramètres d'entrée:  R6 (MSB)- R7 (LSB) – Adresse du périphérique d’entrée
; Valeur retournée: Bit Carry  0: pas de détection / 1: véhicule détecté 
; Registres modifiés: aucun
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
; Paramètres d'entrée:  R6 (MSB)- R7 (LSB) – Adresse du périphérique d’entrée
; Valeur retournée: Bit Carry  0: pas de détection / 1: véhicule détecté 
; Registres modifiés: aucun
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
; Paramètres d'entrée:  R6 (MSB)- R7 (LSB) – Adresse CODE de la table de conversion
;                                            "Display_7S"
; Paramètres d'entrée:  R5  – Valeur 4 bits à convertir (4bits de poids faible)
; Valeur retournée: R7 - Code 7 segments (Bit 0-Segment a __ Bit6-Segment g)
; Registres modifiés: aucun
;******************************************************************************    

_Decod_BIN_to_BCD:	
					Push ACC
					;recuperation adresse
					mov DPH,R6
					mov DPL,R7
					; on mets à 0 les 4 bits de poids forts pour garder que ceux de poids faibles
					; ACC de 00h a 0FH
					mov A,R5
					CLR C
					mov ACC.7,C
					mov ACC.6,C
					mov ACC.5,C
					mov ACC.4,C
					;on cherche l'adresse du code coresspondant à la valeur dans display
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
; Paramètres d'entrée:  R6 (MSB)- R7 (LSB) – Adresse du périphérique de sortie
; Paramètre d’entrée :  R5 – Code 7 segments (les 7 bits de poids faible)
; Paramètre d’entrée :  R3 – Code LED : si 0, LED éteinte, si non nul : LED allumée
; Valeur retournée: R7 : contient une recopie de la valeur envoyée au périphérique de sortie. 
; Registres modifiés: aucun
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
; Paramètres d'entrée:  R6 (MSB)- R7 (LSB) – Adresse de Tab_code
; Paramètre d’entrée :  R5  – Code à vérifier (sur 6 bits)
; Valeur retournée: R7 : non nul, il retourne la position du code trouvé dans la table,
;                        nul, il indique que le code n’a pas été trouvé dans la table.
; Registres modifiés: aucun
;******************************************************************************    

_Test_Code:
			;sauvegarde Data
			Push ACC
			mov A,R0
			Push ACC
			mov A,R1
			Push ACC
			
			;initialise DPTR avec la première adresse de Tab_code
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
; Paramètres d'entrée:  R6 (MSB)- R7 (LSB) – Adresse de Tab_histo
; Paramètre d’entrée :  R5 – Code à enregistrer
; Valeur retournée: R7 : R7 : non nul, il retourne le nombre d’enregistrements,
;                             nul, il indique que la table est pleine (100 enregistrements). 
; Registres modifiés: aucun
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
				
				;on ajoute à DPTR la valeur de l'index pour ranger 
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




;-----------------------------------------------------------------------------
;
;  FILE NAME   :  MAIN_SM4.ASM 
;  TARGET MCU  :  C8051F020 
;  

;-----------------------------------------------------------------------------
$include (c8051f020.inc)               ; Include register definition file. 
;-----------------------------------------------------------------------------
;Declarations Externes
EXTRN code (__tempo,Config_Timer3_BT,Init_pgm)
EXTRN code ( _Read_code,_Read_Park_IN,_Read_Park_OUT,_Decod_BIN_to_BCD,_Display,_Test_Code,_Stockage_Code)

;-----------------------------------------------------------------------------
; EQUATES
;-----------------------------------------------------------------------------
GREEN_LED      	equ   	P1.6             ; Port I/O pin connected to Green LED.

; Put the STACK segment in the main module.
;------------------------------------------------------------------------------
?STACK          SEGMENT IDATA           ; ?STACK goes into IDATA RAM.
                RSEG    ?STACK          ; switch to ?STACK segment.
                DS      30              ; reserve your stack space
                                        ; 30 bytes in this example.
;-----------------------------------------------------------------------------
; XDATA SEGMENT
;-----------------------------------------------------------------------------
Ram_externe    SEGMENT XDATA     ; Reservation de 50 octets en XRAM
               RSEG    Ram_externe  
Tab_histo:     DS      150
;-----------------------------------------------------------------------------
; RESET and INTERRUPT VECTORS
;-----------------------------------------------------------------------------
               ; Reset Vector
               cseg AT 0          ; SEGMENT Absolu
               ljmp Start_pgm     ; Locate a jump to the start of code at 
                                  ; the reset vector.
								  
								  ; Timer3 Interrupt Vector
               cseg AT 073H         ; SEGMENT Absolu
               ljmp ISR_Timer3     ; Locate a jump to the start of code at 
                                  ; the reset vector.
								; INT7 Interrupt Vector					  
			   cseg AT 0B9h 
			   ljmp ISR_INT7
;----------------------
;-------------------------------------------------------
; CODE SEGMENT
;-----------------------------------------------------------------------------
Prog_base      segment  CODE

               rseg     Prog_base      ; Switch to this code segment.
               using    0              ; Specify register bank for the following
                                       ; program code.
									   
Tab_code: DB 0Ah,01h,02h,04h,08h,10h,20h,03h,06h,0CH,18H,30H,07h,0Eh,1CH,38H									   
Display_7S: DB 040h,079h,024h,030h,019h,012h,002h,078h,000h,010h,008h,003h,046h,021h,006h,00Eh
;******************************************************************************
;Initialisations de périphériques - Fonctionnalités Microcontroleur
;******************************************************************************
Start_pgm:
        mov   sp,#?STACK-1   ; Initialisation de la pile
        call Init_pgm        ; Appel SP de configuration du processeur
		mov  R6,#0B7H        ; Passage des paramètres pour l'appel de  Config_Timer3_BT
		mov  R7,#0EDH;       ; Valeur passée: 0B7EDH pour un période timer3 de 10mS 
		CALL Config_Timer3_BT ; Configuration du timer 3
		CALL Config_INT7 ; Configuration de INT7
		
        clr   GREEN_LED       ; Initialize LED to OFF
		setb EA               ; Validation globale des interruptions
		Nb_Place: DS 1
		Code_en_cours: DS 1
			
		
;******************************************************************************
; Programme Principal
;******************************************************************************
Main:
		;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
		;on verifie s'il y a une interruption INT7
		SETB C
		mov A,R2
		ANL C,ACC.0
		JC Main_INT7
		
		;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
		;on verifie s'il y a une voiture entrante ou sortante pour la premiere detection
		SETB C
		mov A,R2
		ANL C,ACC.1
		JC _Voiture_presente_1
		;on verifie si voiture entrante ou pas
		SETB C
		ANL C,ACC.2
		JC Affichage_entrante
		;on affiche dans tous les autres cas
		Jmp Affichage
		
		;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
		;execution de l'interruption
		Main_INT7:
			CALL _Read_Code
			SUBB A,R7
			JNZ Main_INT7 ;on ne sort pas tant que le code n'est pas 0
			Jmp Main
				
		;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
		;Il y a une voiture pour la premiere fois
		; voiture entrante ?
		_Voiture_presente_1:
			;on remet à 0 la présence de la premiere fois R2.1
			CLR C
			mov A,R2
			ANL C,ACC.1
			;on verifie si voiture entrante ou pas
			SETB C
			ANL C,ACC.2
			JC _Voiture_entrante
			;on a donc une voiture sortante 
			;on signal à Timer qu'on a une car_IN
			mov A,R2
			SETB ACC.3
			mov R2,A
			;on décrémente l'affichage des places
			mov DPTR,#Nb_Place
			movx A,@DPTR
			DEC A
			movx @DPTR,A
			
			;redirection verrs l'affichage
			Jmp Affichage
		
		_Voiture_entrante:
					mov R6,#40h
					mov R7,#0h
					CALL _Read_Code
					;enregistre le code
					mov DPTR,#Code_en_cours
					mov A,R7
					movx @DPTR,A
					;initialisation _Test_Code
					mov R5,A ; on met le code dans R5
					mov DPTR,#Tab_code
					mov R6,DPH
					mov R7,DPL
					CALL _Test_Code
					CLR A
					SUBB A,R7
					JZ _Init_Clignotement
					;recup nombre de place
					mov DPTR,#Nb_place
					movx A,@DPTR
					CJNE A,#08h,Entrante_ok
					
					_Init_Clignotement:
						;initialisation compteur 5 secondes
						mov R4,#0F3h ; compteur pour 244
						mov R1,#0FFh ; compteur pour 256
						;SETB R2.5
						mov A,R2
						SETB ACC.5
						mov R2,A

					Entrante_ok:
						;on modifie nb place
						INC A
						movx @DPTR,A
						;initialisation compteur 4 secondes
						mov R4,#8Fh ; compteur pour 144
						mov R1,#0FFh ; compteur pour 256
						;initailisation _Stockage_Code
						mov DPTR,#Tab_histo
						mov R6,DPH
						mov R7,DPL
						mov DPTR,#Code_en_cours
						movx A,@DPTR
						mov R5,A
						CALL _Stockage_Code
						;SETB R2.4
						mov A,R2
						SETB ACC.4
						mov R2,A
						mov R3,#1h
						;SETB R2.4
						mov A,R2
						SETB ACC.4
						mov R2,A
						
		;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
		;Affichage
		;Pour voiture entrante
		Affichage_entrante:
					;on verfie si elle doit clignoter
					SETB C
					mov A,R2
					ANL C,ACC.5
					JC LED_Clignotte
					Jmp Affichage ; sinon on afficher direct, LED deja allumee avant lors de la premiere lecture
					
					LED_Clignotte:
						CLR A 
						SUBB A,R3
						JZ Allume
						mov R3,#0
						Jmp Affichage  
						
						Allume:
							mov R3,#1h	
				
		Affichage:	
			;initialisation _Decod_BIN_to_BCD
			mov DPTR,#NB_Place
			movx A,@DPTR
			mov R5,A
			mov DPTR,#Display_7S
			mov R6,DPH
			mov R7,DPL
			CALL _Decod_BIN_to_BCD
			;initialisation _Display
			mov A,R7
			mov R5,A
			mov R6,#60h
			mov R7,#0h
			CALL _Display

End_Main:		
jmp   	Main

;******************************************************************************
; Programme d'interruption Timer3
;******************************************************************************
ISR_Timer3:
		PUSH PSW
		PUSH ACC
		MOV A,TMR3CN
		CLR ACC.7
		MOV TMR3CN,A
	    
		;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
		;on verifie si on est entrain de compter pour les LED
		SETB C
		mov A,R2
		ANL C,ACC.4
		JC LED
		SETB C
		ANL C,ACC.5
		JC LED
		
		;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
		;on est pas entrain de compter
		;on verifie s'il y a une voiture
		
		;initialisation _Read_Park_IN
		mov R6,#40h
		mov R7,#00h
		CALL _Read_Park_IN
		mov A,#1h
		ANL C,ACC.0  ;verification voiture presente
		JC _Car_IN
		;initialisation _Read_Park_OUT
		mov R6,#60h
		CALL _Read_Park_OUT
		mov A,#0
		SETB Acc.0
		ANL C,Acc.0 ;verification voiture presente
		JC _Car_OUT
		Jmp End_Timer3
		
		;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
		;On regarde pour voiture entrante ou sortante
		_Car_IN:
				; on annonce qu'on a une voiture entrante
				;SETB R2.2
				mov A,R2
				SETB ACC.2
				mov R2,A
				Jmp _Commun_IN_OUT
				
		_Car_OUT:
				; on annonce qu'on a une voiture sortante
				;SETB R2.3
				mov A,R2
				SETB ACC.3
				mov R2,A
				Jmp _Commun_IN_OUT	
				mov R0,#0 ; si aucune voiture entrante ou sortante on reinitailise R0
		
		_Commun_IN_OUT:
				;on verfie qu'on ne la lit qu'une fois
				;SETB R0.0
				mov A,R0
				SETB ACC.0
				;on verifie R0.0 = 1 et R0.1 =0 (premiere lecture )
				SETB C
				ANL C,/ACC.1
				RL A
				mov R0,A
				JC _Premiere_Lecture
				Jmp End_Timer3
				
				_Premiere_Lecture:
					;je dis qu'il y a une voiture 
					mov A,R2
					SETB ACC.1
					mov R2,A
					Jmp End_Timer3
		
		
		;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
		;si on est entrain de compter
		;Organisation Compteur : R4 = valeurs les plus hautes, R1 = valeurs les plus basses
		; exemple : on compte 4 sec soit 400ms soit 400 timer3 donc R4 = 144 et R1 = 256
		LED: 
			;on verifie si R4 est vide
			CLR A
			SUBB A,R4
			JZ _R1_Compte
			DEC R4
			Jmp End_Timer3

			_R1_Compte:
				CLR A
				SUBB A,R1
				JNZ _Fin_Comptage
				DEC R1
				Jmp End_Timer3
											
		
		_Fin_Comptage:
				;reinitialisation et sauvegarde du bit R2.0, bit de INT7 
				mov A,R2
				mov C,ACC.0
				mov A,#0
				mov ACC.0,C
				mov R2,A
				;LED OFF
				mov R3,#0h
											
		
		;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
		;fin de Timer3
		End_Timer3:
		POP ACC
		POP PSW
		reti


;******************************************************************************
; Programme d'interruption INT7
;******************************************************************************
Config_INT7:
		ORL P3IF,#10000000B ; CLR IE7
		ORL EIE2,#00100000B ; SETB EX7
		ORL EIP2,#00100000B; priorite
		SETB EA
		RET
		
ISR_INT7:
       PUSH PSW
	   PUSH ACC
	   
	   ;on met le bit 0 de R2 à 1 pour signaler une interruption au main
	   mov A,R2
	   SETB ACC.0
	   mov R2,A	
	   
	   POP ACC
	   POP PSW
	   reti
;-----------------------------------------------------------------------------
; End of file.

END




# Parking_access_management


*--Français--*

## Cahier des charges
*Remarque préliminaire : Ce cahier des charges est volontairement simplifié. Une application réelle serait un tout petit peu plus complexe….  Néanmoins le principe de conception reste le même.*

On souhaite utiliser un système à microprocesseur basé sur le 8051F020 pour surveiller l’accès à un parking privé. Les caractéristiques et le
fonctionnement du parking sont les suivants :
  - Au maximum 32 personnes peuvent disposer du droit à utiliser le parking.
  - Les personnes ayant le droit d’accès au parking disposent chacune d’un code d’accès unique compris entre 1 et 63.
  - Le nombre de codes autorisés et la valeur de ces codes sont stockés dans la mémoire non volatile du système.
  - Le parking dispose de 8 places uniquement.
  - Le nombre de places occupées est continuellement affiché sur un afficheur 7 segments devant l’entrée du parking.
  - L’entrée du parking est équipée d’une LED chargée d’indiquer l’autorisation d’accès ou pas.

### Entrée Parking

L’entrée au parking se fait selon la séquence suivante :
Une voiture arrive devant l’entrée :
  - Le conducteur s’identifie en rentrant son code en binaire (sur un boitier contenant des interrupteurs) ; en pratique : 6 interrupteurs seront utilisés pour simuler la  demande.
  
  - Une fois le code saisi, la voiture avance alors légèrement pour déclencher un détecteur de présence. Ce dernier fait passer à 1 une entrée logique du système (nommée       DCT_Park_IN). **En pratique : un interrupteur permettra de simuler la détection de passage.**
  
  - Le système vient périodiquement lire l’état de cette entrée. **En pratique : le système scrutera l’état de cette entrée durant une interruption Timer 3 déclenchée par le débordement du Timer (code fourni). Attention, le véhicule ne devra être détecté qu’une fois….**

    - Si elle est à 1, et si l’identifiant a saisi un des codes autorisés et si le nombre de véhicules dans le parking est inférieur à 8 :
      - Le portail d’entrée s’ouvre,  

      - La LED est allumée pendant 4 secondes pour indiquer l’autorisation d’accès au parking,  

      - L’afficheur est mis à jour (il indique le nombre de véhicules dans le parking),

      - Le code identifiant le conducteur autorisé est enregistré en mémoire (mémorisation de tous les accès).

    - Si elle est à 1 et que l’identifiant n’a pas saisi un des codes autorisés ou et le nombre de véhicules dans le parking est égal à 8, le portail d’entrée reste fermé et la LED clignote (Fcligno = 4Hz environ) pendant 5 secondes pour indiquer le refus d’accès.

### Sortie Parking 
 
La sortie du parking se fait selon la séquence suivante :

  - Une voiture arrive devant la sortie ;

  - Un détecteur détecte sa présence et fait passer à 1 une entrée logique du système (nommée DCT_Park_OUT). **En pratique : un interrupteur permettra de simuler la détection de passage.**

  - Le système vient périodiquement lire l’état de cette entrée ; en pratique : le système scrutera l’état de cette entrée durant une interruption Timer 3 déclenchée par le débordement de ce Timer. Attention, le véhicule ne devra être détecté qu’une fois…

  - Si elle est à 1, on suppose qu’un véhicule vient de quitter le parking, l’afficheur (affichage du nombre de véhicules dans le parking) est alors mis à jour.

### Arrêt d’urgence

A tout moment, l’accès au parking pourra être invalidé. Cette interdiction d’accès sera assurée par action sur un bouton poussoir. L’accès sera de nouveau autorisé après avoir entré le code de réarmement du système (valeur 00) sur le boitier de saisie du code d’entrée. **En pratique : c’est l’interruption externe INT7 (reliée à un bouton poussoir sur la carte d’évaluation) qui provoquera l’arrêt d’urgence.**

## Lecture du Projet

Vous pouvez exécuter le projet avec le fichier Proj_TP4_SM4.uproj sous mircoVision. Sinon vous pouvez ouvrir les programmes assembleur en fichier texte.

*--English--*

## Terms of reference
*Preliminary remark: This specification is deliberately simplified. A real application would be a little bit more complex....  Nevertheless, the design principle remains the same*.

A microprocessor-based system based on the 8051F020 is to be used to monitor access to a private car park. The characteristics and operation of the
The characteristics and operation of the car park are as follows:
  - A maximum of 32 people can have the right to use the car park.
  - The persons entitled to access the car park each have a unique access code between 1 and 63.
  - The number of authorised codes and their values are stored in the system's non-volatile memory.
  - The car park has only 8 spaces.
  - The number of occupied spaces is continuously displayed on a 7-segment display in front of the car park entrance.
  - The entrance to the car park is equipped with an LED to indicate whether or not access is allowed.

### Parking entrance

The entry to the car park is done according to the following sequence:
A car arrives at the entrance:
  - The driver identifies himself by entering his code in binary (on a box containing switches); in practice: 6 switches will be used to simulate the request.
  
  - Once the code has been entered, the car then moves forward slightly to trigger a presence detector. The latter sets a logic input of the system (named DCT_Park_IN) to 1. **In practice: a switch will be used to simulate the detection of passage.
  
  - The system periodically reads the status of this input. **In practice: the system will scan the state of this input during a Timer 3 interrupt triggered by the Timer overflow (code provided). Note that the vehicle will only have to be detected once....**

    - If it is set to 1, and if the user has entered one of the authorised codes and if the number of vehicles in the car park is less than 8:
      - The entrance gate opens,  

      - The LED is lit for 4 seconds to indicate access authorisation to the car park,  

      - The display is updated (showing the number of vehicles in the car park),

      - The code identifying the authorised driver is stored in memory (all accesses are stored).

    - If it is set to 1 and the identifier has not entered one of the authorised codes or and the number of vehicles in the car park is equal to 8, the entrance gate remains closed and the LED flashes (Fcligno = approx. 4Hz) for 5 seconds to indicate access refusal.

### Parking exit 
 
Exit from the car park takes place in the following sequence:

  - A car arrives at the exit;

  - A detector detects its presence and sets a logic input of the system (named DCT_Park_OUT) to 1. **In practice: a switch will allow to simulate the detection of passage.

  - The system periodically reads the state of this input; in practice: the system will check the state of this input during a Timer 3 interrupt triggered by the overflow of this Timer. Be careful, the vehicle will only have to be detected once...

  - If it is at 1, it is assumed that a vehicle has just left the car park, the display (display of the number of vehicles in the car park) is then updated.

### Emergency stop

At any time, access to the car park can be disabled. This access prohibition will be ensured by pressing a push button. Access will be authorised again after entering the system reset code (value 00) on the entry code box. **In practice: it is the external interrupt INT7 (connected to a push button on the evaluation board) that will cause the emergency stop.**


##Project

You can run the project with the file Proj_TP4_SM4.uproj under mircoVision. Alternatively you can open the assembler programs as text files.

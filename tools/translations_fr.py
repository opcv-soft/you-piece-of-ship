"""French translations (Olivier, 2026-10-22). Keys are the English texts used in the game.
Run:  python3 tools/translations_fr.py  ->  translations/strings.csv  (Godot imports it).
The title "You Piece of Ship" is never translated.
"""
import csv
from pathlib import Path

FR = {
    # Results
    "DELIVERED!": "LIVRÉ !", "SUNK!": "COULÉ !", "Time": "Temps", "%s (deadline %s)": "%s (limite %s)",
    "Cargo": "Cargaison", "%d of %d crates": "%d caisses sur %d", "Hull": "Coque", "%d%% dry": "%d %% au sec",
    "Distance": "Distance", "%d%% of the way": "%d %% du trajet", "Best": "Record", "%d points, %s": "%d points, %s",
    "cargo %d + dry hull %d + early %d": "cargaison %d + coque sèche %d + avance %d",
    "NEW BEST SCORE & TIME!": "NOUVEAUX RECORDS !", "NEW BEST SCORE!": "NOUVEAU RECORD DE SCORE !",
    "NEW BEST TIME!": "NOUVEAU RECORD DE TEMPS !", "Nothing went wrong. Suspicious.": "Rien n'a mal tourné. Louche.",
    "Enter / A: back to the dock     R / Start: sail again     J: change crew":
        "Entrée / A : retour au quai     R / Start : repartir     J : changer d'équipage",
    "SCORE %d": "SCORE %d", "+%d coins": "+%d pièces", "WHAT HAPPENED": "CE QUI S'EST PASSÉ",
    # Crew join
    "Press Jump to join the crew (Space, Enter, or A)": "Appuie sur Saut pour rejoindre l'équipage (Espace, Entrée ou A)",
    "ready!": "prêt !", "press Jump": "appuie sur Saut",
    "Then press Use (E, Right Shift, or X) to set sail": "Puis appuie sur Utiliser (E, Maj droite ou X) pour larguer les amarres",
    "\nSmall crew: the ship gets a slow automatic pump": "\nPetit équipage : le navire a une petite pompe automatique",
    # Main menu
    "Quick Play": "Partie rapide", "Jump into a random voyage": "Un voyage au hasard, tout de suite",
    "Host Game": "Héberger", "Start a game with friends": "Lancer une partie entre amis",
    "Join Game": "Rejoindre", "Enter your friend's address": "Entre l'adresse de ton ami",
    "Ship & Upgrades": "Navire et améliorations", "Crew, contracts and the shop": "Équipage, contrats et boutique",
    "Settings": "Réglages", "Quit": "Quitter", "Back": "Retour", "Music volume": "Volume de la musique",
    "Band comments": "Commentaires de l'orchestre", "Full screen": "Plein écran",
    "Your friend's address (they read it out from their screen):": "L'adresse de ton ami (il la lit sur son écran) :",
    "Type your friend's address first.": "Entre d'abord l'adresse de ton ami.",
    "That address doesn't look right.": "Cette adresse n'a pas l'air bonne.", "Joining %s...": "Connexion à %s...",
    "Couldn't reach that address. Check it with your friend.": "Impossible de joindre cette adresse. Vérifie-la avec ton ami.",
    "Same ship.\nDifferent view.\nTotal chaos.": "Même navire.\nAutre point de vue.\nChaos total.",
    "4 PLAYERS CO-OP": "COOP 4 JOUEURS",
    # Dock
    "THE DOCK": "LE QUAI", "CONTRACTS": "CONTRATS", "SHOP (every upgrade has a catch)": "BOUTIQUE (chaque amélioration a un revers)",
    "CREW: each player presses Use (E, Right Shift or X) to come aboard. Empty slots can be AI crewmates: a job, then a backup job.":
        "ÉQUIPAGE : chaque joueur appuie sur Utiliser (E, Maj droite ou X) pour monter à bord. Les places vides peuvent être des matelots IA : un poste, puis un poste de secours.",
    "Arrows / D-pad: choose     Enter / Space / A: confirm     Esc / B: back to the menu":
        "Flèches / croix : choisir     Entrée / Espace / A : valider     Échap / B : retour au menu",
    "Couldn't reach the host. Check the address.": "Impossible de joindre l'hôte. Vérifie l'adresse.",
    "The host left.": "L'hôte est parti.",
    "P%d is a human player. Press their Use again to free the slot.": "P%d est un joueur humain. Appuie encore sur son Utiliser pour libérer la place.",
    "Only the host sets up AI crew.": "Seul l'hôte règle les matelots IA.", "The host chooses the contract.": "L'hôte choisit le contrat.",
    "Locked: deliver the previous contract first.": "Verrouillé : livre d'abord le contrat précédent.",
    "Nobody aboard! At least one player presses Use (E, Right Shift or X) to join.":
        "Personne à bord ! Au moins un joueur appuie sur Utiliser (E, Maj droite ou X).",
    "Bought: %s": "Acheté : %s", "Not enough coins.": "Pas assez de pièces.", "Coins: %d": "Pièces : %d",
    "Hosting: %d aboard. Friends join with your address: %s": "Tu héberges : %d à bord. Tes amis rejoignent avec ton adresse : %s",
    "Online as P%d (your keyboard W A S D or controller). The host picks the contract.":
        "En ligne en tant que P%d (ton clavier Z Q S D ou ta manette). L'hôte choisit le contrat.",
    "Online: one friend hosts, the others join with the host's address. This computer: %s":
        "En ligne : un ami héberge, les autres rejoignent avec son adresse. Cet ordinateur : %s",
    "no network": "pas de réseau", "aboard": "à bord", "AI crewmate": "matelot IA", "press Use": "appuie sur Utiliser",
    "AI: on": "IA : oui", "AI: off": "IA : non", "Job: %s": "Poste : %s", "Job: -": "Poste : -", "Then: %s": "Sinon : %s",
    "Then: -": "Sinon : -", "   best %d": "   record %d", " in %s": " en %s",
    "%d. %s   %s   %d coins/crate   %s%s": "%d. %s   %s   %d pièces/caisse   %s%s",
    "%d. LOCKED (deliver the previous contract)": "%d. VERROUILLÉ (livre le contrat précédent)",
    "OWNED": "ACHETÉ", "%d coins": "%d pièces", "Host online game": "Héberger en ligne", "Join": "Rejoindre", "Leave": "Quitter",
    "Couldn't start hosting (is another game already hosting on this computer?).":
        "Impossible d'héberger (une autre partie héberge-t-elle déjà sur cet ordinateur ?).",
    # Ship, stations and status
    "water %d%%": "eau %d %%", "Cracking! %d": "Ça craque ! %d", "Use: hammer (2 crew = fast) %d%%": "Utiliser : clouer (à 2 = rapide) %d %%",
    "Plugged. Bring a plank!": "Bouché. Apporte une planche !", "Bring a plank (or a crate)!": "Apporte une planche (ou une caisse) !",
    "ROPE FRAYING!": "LA CORDE S'EFFILOCHE !", "WHEEL SHUDDERS! %d\n%s": "LA BARRE TREMBLE ! %d\n%s",
    "RUDDER BROKEN: bring the pin\n%s": "GOUVERNAIL CASSÉ : apporte la goupille\n%s",
    "BIG WAVE!\nGrab a station!": "GROSSE VAGUE !\nAccroche-toi à un poste !",
    "ENGINE ROOM  ": "SALLE DES MACHINES  ", "HEAT": "CHALEUR", "COAL (shovel it from the pile)": "CHARBON (à la pelle depuis le tas)",
    "Jump: vent steam": "Saut : lâcher la vapeur", "vent ready in %ds": "vapeur prête dans %d s", "WET COAL: -%d%% speed": "CHARBON MOUILLÉ : -%d %% de vitesse",
    "COOLING PIPE BURST": "TUYAU DE REFROIDISSEMENT PERCÉ", "STALLED %ds": "CALÉ %d s", "OVERHEAT! VENT NOW %d": "SURCHAUFFE ! LÂCHE LA VAPEUR %d",
    "Use: take one": "Utiliser : en prendre une", "rocks spotted: %d": "rochers repérés : %d", "COAL": "CHARBON", "WET!": "MOUILLÉ !",
    "Use: fill a shovel": "Utiliser : remplir une pelle", "OVERHEAT! Jump: vent  %d": "SURCHAUFFE ! Saut : vapeur  %d", "HOT": "CHAUD",
    "NO COAL! Shovel from the pile": "PLUS DE CHARBON ! Pelle au tas", "COAL LOW! Shovel from the pile": "CHARBON BAS ! Pelle au tas",
    "WET COAL": "CHARBON MOUILLÉ", "ASTERN %d%%": "ARRIÈRE %d %%", "throttle %d%%": "gaz %d %%", "MAP TABLE  read by ": "TABLE DES CARTES  lue par ",
    "PORT %d m": "PORT %d m", "P%d AI": "P%d IA", "Rock, %d o'clock, %d m!": "Rocher à %d heures, %d m !", "Port ahead, %d m!": "Port droit devant, %d m !",
    "Clear ahead!": "Rien devant !", "CRASH!": "CRAC !", "%s    Time %s / %s": "%s    Temps %s / %s",
    "Coal low! Fill a shovel at the COAL pile (back corner) and press Use at the ENGINE.":
        "Charbon bas ! Remplis une pelle au tas de CHARBON (coin arrière) et appuie sur Utiliser à la MACHINE.",
    "Out of coal: only the sail is pushing. Shovel coal from the pile into the ENGINE!":
        "Plus de charbon : seule la voile pousse. Pelle du charbon du tas jusqu'à la MACHINE !",
    "HELM": "BARRE", "Use: steer": "Utiliser : barrer", "MAP TABLE": "TABLE DES CARTES", "Stand here to read the chart": "Reste ici pour lire la carte",
    "PLANKS": "PLANCHES", "PINS": "GOUPILLES", "PUMP": "POMPE", "Use: pump water out": "Utiliser : pomper l'eau", "ENGINE": "MACHINE",
    "Use: run the engine": "Utiliser : tenir la machine", "COOLING PIPE": "TUYAU DE REFROIDISSEMENT", "TELESCOPE": "LONGUE-VUE",
    "Use: spot rocks in the fog": "Utiliser : repérer les rochers dans la brume", "LEAK": "VOIE D'EAU", "Station": "Poste",
    "Helm": "Barre", "Navigator": "Navigateur", "Engine": "Machine", "Pump": "Pompe", "Carpenter": "Charpentier", "nothing": "rien",
    "BURST! Use: fix (2 crew = fast)": "PERCÉ ! Utiliser : réparer (à 2 = rapide)",
    "P1: W A S D (Z Q S D on French keyboard) move, Space jump, E use     P2: arrows, Enter jump, Right Shift use     Controllers: stick, A jump, X use\nHelm: left/right steer, up/down throttle (below 0 = astern)     Engine: coal pile, Use = shovel / feed, Jump at engine = vent     R: restart     M: music     H: show / hide this help":
        "P1 : Z Q S D bouger, Espace sauter, E utiliser     P2 : flèches, Entrée sauter, Maj droite utiliser     Manettes : stick, A sauter, X utiliser\nBarre : gauche/droite barrer, haut/bas gaz (sous 0 = arrière)     Machine : tas de charbon, Utiliser = pelle / nourrir, Saut à la machine = vapeur     R : recommencer     M : musique     H : afficher / cacher l'aide",
    # Contracts
    "Maiden Voyage": "Voyage inaugural", "A short hop with spare sails. Learn the ropes; nobody sinks today.":
        "Un petit saut avec des voiles de rechange. On apprend les ficelles ; personne ne coule aujourd'hui.",
    "Reef Run": "Course au récif", "Six crates of tinned sardines through the Gull Reef. Five minutes, if nothing breaks.":
        "Six caisses de sardines en boîte à travers le récif des Goélands. Cinq minutes, si rien ne casse.",
    "The Narrows": "Le Goulet", "Fragile glassware through a channel barely wider than the ship. Mind the walls.":
        "De la verrerie fragile dans un chenal à peine plus large que le navire. Attention aux parois.",
    "Fog Bank": "Banc de brume", "Medicine for the lighthouse keeper. The fog is so thick the chart can't help much: use the telescope.":
        "Des remèdes pour le gardien du phare. La brume est si épaisse que la carte aide peu : utilise la longue-vue.",
    "Welcome aboard! Walk to a station and press Use. Captain: HELM, hold UP for throttle.":
        "Bienvenue à bord ! Va à un poste et appuie sur Utiliser. Capitaine : à la BARRE, maintiens HAUT pour les gaz.",
    "Engineer: fill a shovel at the COAL pile (back corner), carry it to the ENGINE and press Use. The pile never runs out.":
        "Mécanicien : remplis une pelle au tas de CHARBON (coin arrière), porte-la à la MACHINE et appuie sur Utiliser. Le tas ne s'épuise jamais.",
    "Buoys ahead! Navigator: stand at the MAP TABLE and call where they are.":
        "Bouées devant ! Navigateur : va à la TABLE DES CARTES et annonce où elles sont.",
    "A wave cracked the hull! Fetch a PLANK, put it on the LEAK, hammer it. Someone: PUMP!":
        "Une vague a fendu la coque ! Prends une PLANCHE, pose-la sur la VOIE D'EAU, cloue-la. Quelqu'un : POMPEZ !",
    "Headwind! The engine runs hot. Engineer: at the ENGINE, Jump vents steam (stand clear!).":
        "Vent de face ! La machine chauffe. Mécanicien : à la MACHINE, Saut lâche la vapeur (écartez-vous !).",
    "Big wave coming: grab a station so you don't fall over!": "Grosse vague en approche : accroche-toi à un poste pour ne pas tomber !",
    "Rudder trouble! Bring the PIN to the HELM. Two problems at once: split up!":
        "Problème de gouvernail ! Apporte la GOUPILLE à la BARRE. Deux problèmes d'un coup : séparez-vous !",
    "Port ahead! Steer between the yellow buoys.": "Port en vue ! Passe entre les bouées jaunes.",
    "Thick fog: the chart only sees 30 m. Navigator: the TELESCOPE at the bow spots rocks further ahead.":
        "Brume épaisse : la carte ne voit qu'à 30 m. Navigateur : la LONGUE-VUE à la proue repère les rochers plus loin.",
    # Upgrades
    "Overclocked engine": "Machine survoltée", "+20% top speed": "+20 % de vitesse max", "heats up 45% faster: more venting": "chauffe 45 % plus vite : plus de vapeur à lâcher",
    "Reinforced hull": "Coque renforcée", "leaks 40% slower, +3 s crack warning": "fuit 40 % moins vite, +3 s d'alerte avant fissure",
    "heavier: -8% speed, -10% turning": "plus lourde : -8 % de vitesse, -10 % de virage", "Bigger pumps": "Grosses pompes",
    "pump 80% faster": "pompe 80 % plus vite", "the pump burns coal: more shovelling": "la pompe brûle du charbon : plus de pelletage",
    "Second spare-parts crate": "Deuxième caisse de rechange", "+3 planks, +1 rudder pin": "+3 planches, +1 goupille de gouvernail",
    "one fewer cargo crate to sell": "une caisse de cargaison en moins à vendre",
    # The band
    "Band: smooth sailing, folks.": "Orchestre : tout baigne, les amis.", "The accordionist hums along.": "L'accordéoniste fredonne.",
    "The accordionist picks up the pace.": "L'accordéoniste accélère un peu.", "The drummer senses something.": "Le batteur sent venir quelque chose.",
    "The accordionist is sweating.": "L'accordéoniste transpire.", "The bassist starts walking. Nervously.": "Le bassiste se met à marcher. Nerveusement.",
    "The brass section is panicking.": "Les cuivres paniquent.", "The tuba player eyes the lifeboat.": "Le tubiste lorgne le canot de sauvetage.",
    "The tuba player has left the building.": "Le tubiste a quitté le navire.", "Band: we're fine. Everything's fine.": "Orchestre : ça va. Tout va bien.",
    "Someone in the band played a wrong note. On purpose.": "Quelqu'un dans l'orchestre a joué une fausse note. Exprès.",
    "Band: ...and that's our set. Goodnight!": "Orchestre : ...et c'était notre dernier morceau. Bonsoir !",
    "Band: we never doubted you. (We doubted you.)": "Orchestre : on n'a jamais douté de vous. (On a douté.)",
    "Band: that wasn't in the sheet music.": "Orchestre : ça, ce n'était pas sur la partition.",
    "The drummer dropped a stick.": "Le batteur a lâché une baguette.", "Band: take a bow! Not you. The ship.": "Orchestre : saluez ! Pas vous. Le navire.",
    # Voyage log
    "The hull cracked": "La coque s'est fendue", "Leak open: water pouring in": "Voie d'eau : l'eau entre",
    "Leak patched": "Voie d'eau colmatée", "Leak plugged with a crate (cargo lost)": "Voie d'eau bouchée avec une caisse (cargaison perdue)",
    "Engine overheating!": "La machine surchauffe !", "Engine stalled and the cooling pipe burst": "La machine a calé et le tuyau de refroidissement a percé",
    "%s vented steam": "%s a lâché la vapeur", "Cooling pipe fixed": "Tuyau de refroidissement réparé", "Out of coal!": "Plus de charbon !",
    "Hard hit: the wheel is shuddering": "Gros choc : la barre tremble", "Rudder broken: pulling to %s": "Gouvernail cassé : il tire vers %s",
    "Rudder pin swapped": "Goupille du gouvernail changée", "A cargo rope is fraying": "Une corde de la cargaison s'effiloche",
    "A crate broke loose": "Une caisse s'est détachée", "%s threw a crate overboard": "%s a jeté une caisse par-dessus bord",
    "Big wave coming from %s!": "Grosse vague par %s !", "Hit %s at %d%% speed": "Choc contre %s à %d %% de vitesse",
    "%s knocked over": "%s à terre", "Water %d%% up the hold!": "La cale est remplie à %d %% !",
    "Checking whether friends on the internet can reach you...": "On vérifie si des amis sur Internet peuvent te rejoindre...",
    "Friends can join you at: %s": "Tes amis peuvent te rejoindre à : %s",
    "Your internet connection can't host for friends elsewhere (your provider shares one address between customers). Ask your friend to host instead. Same Wi-Fi friends can join at: %s":
        "Ta connexion ne peut pas héberger pour des amis ailleurs (ton fournisseur partage une même adresse entre clients). Demande plutôt à ton ami d'héberger. Les amis sur le même Wi-Fi rejoignent à : %s",
    "Your router didn't open the game's door automatically (UPnP is off). Friends elsewhere probably can't join: ask them to host, or open UDP port 7777 on your router. Same Wi-Fi friends can join at: %s":
        "Ta box n'a pas ouvert la porte du jeu automatiquement (UPnP désactivé). Des amis ailleurs ne pourront sans doute pas rejoindre : demande-leur d'héberger, ou ouvre le port UDP 7777 sur ta box. Les amis sur le même Wi-Fi rejoignent à : %s",
    "Hosting: %d aboard.": "Tu héberges : %d à bord.", "Copy address": "Copier l'adresse", "Copied: %s": "Copié : %s",
    "starboard": "tribord", "port": "bâbord", "the coast": "la côte", "a rock": "un rocher", "Someone": "Quelqu'un",
    # Thought bubbles
    "Whoa!": "Ouh là !", "I'm in!": "Je prends la relève !", "To the helm!": "À la barre !", "Pumping!": "Je pompe !",
    "Too hot! Venting!": "Trop chaud ! Vapeur !", "Coal for the furnace!": "Du charbon pour la chaudière !",
    "Need coal!": "Il faut du charbon !", "To the map!": "À la carte !", "Hammering the leak!": "Je cloue la fuite !",
    "Fixing the pipe!": "Je répare le tuyau !", "Going to fix leak!": "Je vais réparer la fuite !",
    "Fetching a rudder pin!": "Je cherche une goupille !", "Tying down cargo!": "J'attache la cargaison !",
    # Pause menu and developer mode
    "Paused": "Pause", "Resume": "Reprendre", "Restart voyage": "Recommencer le voyage", "Back to the dock": "Retour au quai",
    "Main menu": "Menu principal", "Developer": "Développeur", "Events": "Événements", "Tune": "Réglages fins",
    "Time scale": "Vitesse du temps", "Time scale: %.1fx": "Vitesse du temps : %.1fx",
    "Search (e.g. heat, speed, leak)": "Chercher (ex. heat, speed, leak)", "Save %d": "Sauver %d", "Load %d": "Charger %d",
    "Reset all": "Tout réinitialiser", "Back to the defaults.": "Retour aux valeurs d'origine.",
    "Saved preset %d.": "Préréglage %d sauvé.", "Preset %d is empty.": "Le préréglage %d est vide.",
    "Loaded preset %d.": "Préréglage %d chargé.", "Forced: %s": "Forcé : %s", "God mode: %s": "Mode dieu : %s",
    "on": "activé", "off": "désactivé",
    "Crash into a rock": "Percuter un rocher", "Open a leak": "Ouvrir une fuite", "Flood +30%": "Inonder +30 %",
    "Overheat engine": "Surchauffe moteur", "Stall engine": "Caler le moteur", "Empty the coal": "Vider le charbon",
    "Break the rudder": "Casser le gouvernail", "Big wave (port)": "Grosse vague (bâbord)",
    "Big wave (starboard)": "Grosse vague (tribord)", "Loose cargo": "Cargaison détachée", "Reach port": "Arriver au port",
    "Sink (fail)": "Couler (échec)", "+500 coins": "+500 pièces", "Unlock everything": "Tout débloquer",
    "God mode on/off": "Mode dieu oui/non",
    "Ship handling": "Pilotage", "Engine and coal": "Moteur et charbon", "Hull and leaks": "Coque et fuites",
    "Waves": "Vagues", "Rudder": "Gouvernail", "Hazards": "Dangers", "Music": "Musique", "Camera": "Caméra",
    "Game feel": "Sensations", "Crew": "Équipage", "AI crew": "Équipage IA",
    # Obstacles and stars
    "Wreck, %d o'clock, %d m!": "Épave, %d heures, %d m !", "Whale, %d o'clock, %d m!": "Baleine, %d heures, %d m !",
    "Atoll, %d o'clock, %d m!": "Atoll, %d heures, %d m !", "Coast, %d o'clock, %d m!": "Côte, %d heures, %d m !",
    "Siren, %d o'clock! Don't listen!": "Sirène, %d heures ! N'écoutez pas !",
    "Spawn: reef rock": "Ajouter : récif", "Spawn: shipwreck": "Ajouter : épave", "Spawn: whale": "Ajouter : baleine",
    "Spawn: siren": "Ajouter : sirène", "Spawn: atoll": "Ajouter : atoll", "Sea": "Mer", "Stars": "Étoiles",
    " + fish & loot %d": " + poissons et butin %d", "Next star at %d points": "Prochaine étoile à %d points",
    # Fishing
    "FISHING": "PÊCHE", "Use: fish": "Utiliser : pêcher", "%s +%d": "%s +%d", "Too early!": "Trop tôt !", "Nothing yet...": "Rien pour l'instant...", "AT YOUR STATIONS!": "À VOS POSTES !",
    "It got away...": "Il s'est échappé...", "Gone fishing!": "Je vais pêcher !", "    Fish & loot +%d": "    Pêche et butin +%d",
    # Battles
    "CANNON": "CANON", "Use: aim   Jump: fire": "Utiliser : viser   Saut : feu", "loaded": "chargé", "Loaded!": "Chargé !",
    "Not loaded!": "Pas chargé !", "CANNONBALLS": "BOULETS", "PIRATES!": "PIRATES !", "Fire!": "Feu !",
    "To the cannon!": "Au canon !", "Load the cannon!": "Je charge le canon !", "BOOM!": "BOUM !",
    "Pirates sunk! Scoop up the loot": "Pirates coulés ! Ramassez le butin", "Pirates fired a broadside": "Les pirates ont tiré une bordée",
    "Pirates on the %s side!": "Pirates côté %s !", "Cannonball hit!": "Touchés par un boulet !",
    "Pirates sunk! Sail through the floating loot to scoop it up.": "Pirates coulés ! Passez sur le butin flottant pour le ramasser.",
    "PIRATES! Outrun them at full speed, or load the cannons on that side (cannonballs in the middle of the deck).":
        "PIRATES ! Semez-les à pleine vitesse, ou chargez les canons de ce côté (boulets au milieu du pont).",
    "Spawn: pirates (port)": "Ajouter : pirates (bâbord)", "Spawn: pirates (starboard)": "Ajouter : pirates (tribord)",
    "Gunner": "Canonnier",
    # Nautical callouts and the helm
    "%.1f knots": "%.1f nœuds", "%s, %s, %s!": "%s, %s, %s !", "Siren, %s! Don't listen!": "Sirène, %s ! N'écoutez pas !",
    "Land ho! %s dead ahead!": "Terre ! %s droit devant !", "%d fathoms": "%d brasses", "%.1f cables": "%.1f encablures",
    "dead ahead": "droit devant", "dead astern": "droit derrière",
    "off the starboard bow": "par tribord avant", "off the port bow": "par bâbord avant",
    "on the starboard beam": "par le travers tribord", "on the port beam": "par le travers bâbord",
    "off the starboard quarter": "par tribord arrière", "off the port quarter": "par bâbord arrière",
    "Realistic sea": "Mer réaliste", "CROW'S NEST": "NID-DE-PIE", "Use: climb up": "Utiliser : grimper", "Up the mast!": "En haut du mât !",
    "A chest burst open: gold all over the deck!": "Un coffre a éclaté : de l'or partout sur le pont !",
    "%d gold washed overboard": "%d pièces d'or emportées par-dessus bord", "gold": "or",
    "Haul": "Butin", "charcoal": "charbon", "planks": "planches", "whale grease": "graisse de baleine", "siren": "sirène",
    "SET SAIL!": "LARGUEZ !", "Use: let go": "Utiliser : lâcher", "Use: pick up %s": "Utiliser : prendre %s",
    "Use: put the gold back in": "Utiliser : remettre l'or dedans", "Legibility": "Lisibilité", "Use": "Utiliser",
    "Sail to the beach": "Aller jusqu'à la plage", "Barrel": "Tonneau", "Spawn: barrel": "Ajouter : tonneau",
    "Rock": "Rocher", "Wreck": "Épave", "Whale": "Baleine", "Atoll": "Atoll", "Coast": "Côte",
    "Show collision shapes": "Voir les formes de collision", "Test Drive: open ocean, no obstacles": "Essai libre : océan ouvert, sans obstacles",
    "Sail again  (R)": "Repartir  (R)", "World map  (Enter)": "Carte  (Entrée)", "Change crew  (J)": "Changer d'équipage  (J)",
    "CREW: press Use (E, Right Shift or X) to take an AI sailor's place. Press it again to hand back.":
        "ÉQUIPAGE : appuie sur Utiliser (E, Maj droite ou X) pour remplacer un marin IA. Appuie encore pour lui rendre sa place.",
    # World map and progression
    "World Map": "Carte du monde", "Oceans, ports and routes": "Océans, ports et routes", "WORLD MAP": "CARTE DU MONDE",
    "★ %d stars": "★ %d étoiles", "Set sail!": "Larguez les amarres !", "The host picks the route": "L'hôte choisit la route",
    "Crew & shop (dock)": "Équipage et boutique (quai)", "Aye aye!": "À vos ordres !", "NEW OCEAN: %s": "NOUVEL OCÉAN : %s",
    "Calm Cove": "Crique Tranquille", "Whale Waters": "Eaux des Baleines", "Pirate Sea": "Mer des Pirates",
    "Learn the ropes: steering, coal, leaks, the chart. Wrecks and atolls to steer around.":
        "Apprenez les bases : barre, charbon, fuites, carte. Des épaves et des atolls à contourner.",
    "Whales cross your path, sirens sing to your helmsman, and big swells shift the cargo.":
        "Les baleines croisent votre route, les sirènes chantent pour votre barreur et la houle déplace la cargaison.",
    "Pirates! Fog, storms, a ship without a sail and engines that fail.":
        "Des pirates ! Brouillard, tempêtes, un navire sans voile et des moteurs qui lâchent.",
    "Deadline %s    %d coins a chest": "Limite %s    %d pièces le coffre", "Danger: %s": "Danger : %s",
    "Watch out for: %s": "Attention : %s", "Best: %d points, %s": "Record : %d points, %s",
    "Locked. Earn %d stars to open this route (you have %d).": "Verrouillé. Gagnez %d étoiles pour ouvrir cette route (vous en avez %d).",
    "whales": "baleines", "sirens": "sirènes", "wrecks": "épaves", "atolls": "atolls", "pirates": "pirates", "fog": "brouillard",
    "a storm": "une tempête", "no sail": "pas de voile", "shifting cargo": "cargaison qui glisse",
    "engine failure": "panne moteur", "flooding": "inondation", "Unlocks: ": "À débloquer : ", "%s hat at %d★": "%s à %d★",
    "Captain": "Chapeau de capitaine", "Crown": "Couronne", "Tricorn": "Tricorne", "Bandana": "Bandana", "Beanie": "Bonnet",
    "Straw": "Chapeau de paille", "Hat: %s": "Chapeau : %s", "🔒 %d★": "🔒 %d★",
    "WORLD MAP: choose a route  ★ %d": "CARTE DU MONDE : choisir une route  ★ %d",
    "Locked: earn %d stars to open it.": "Verrouillé : gagnez %d étoiles pour l'ouvrir.",
    "%d. LOCKED (%d stars needed)": "%d. VERROUILLÉ (%d étoiles nécessaires)",
    "Enter / A: world map     R / Start: sail again     J: change crew": "Entrée / A : carte     R / Start : repartir     J : changer d'équipage",
    "Coral Hop": "Saut de Corail", "Siren Strait": "Détroit des Sirènes", "Whale Road": "Route des Baleines",
    "Smugglers' Run": "Route des Contrebandiers", "Kraken's Gate": "Porte du Kraken",
    "Pineapples for the atoll market. Short and sweet: steer round the old wreck.": "Des ananas pour le marché de l'atoll. Court et doux : contournez la vieille épave.",
    "Love letters for the lighthouse. Two sirens sing in the strait. Don't listen!": "Des lettres d'amour pour le phare. Deux sirènes chantent dans le détroit. N'écoutez pas !",
    "Delicate porcelain along the whales' road. When the big swell comes, the cargo shifts.": "De la porcelaine fragile sur la route des baleines. Quand la houle arrive, la cargaison glisse.",
    "Hush-hush cargo on a sail-less smuggler's ship. If the engine stops, so do you. Pirates know you're coming.": "Une cargaison secrète sur un navire de contrebande sans voile. Si le moteur s'arrête, vous aussi. Les pirates vous attendent.",
    "The crown jewels, through the worst storm in years. Everything that can go wrong will.": "Les joyaux de la couronne, dans la pire tempête depuis des années. Tout ce qui peut mal tourner tournera mal.",
    "The swell shifted the cargo! Tie the chests back down.": "La houle a déplacé la cargaison ! Rattachez les coffres.",
    "The engine coughed and died! Fix the cooling pipe and get it going again.": "Le moteur a toussé et calé ! Réparez le tuyau et relancez-le.",
    "A wave broke over the bow: the deck is flooding! Pump! Patch!": "Une vague a déferlé sur la proue : le pont est inondé ! Pompez ! Colmatez !",
    "Sardine": "Sardine", "Goldfish": "Poisson doré", "Squid": "Calamar", "Pufferfish": "Poisson-globe", "Treasure!": "Trésor !",
}


def escape(text: str) -> str:
    return text.replace("\\", "\\\\").replace("\n", "\\n")


if __name__ == "__main__":
    out = Path(__file__).resolve().parent.parent / "translations/strings.csv"
    out.parent.mkdir(exist_ok=True)
    with out.open("w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f, lineterminator="\n")
        writer.writerow(["keys", "en", "fr"])
        for key, fr in FR.items():
            writer.writerow([escape(key), escape(key), escape(fr)])
    print(f"{len(FR)} strings")

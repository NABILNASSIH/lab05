extends Node2D

# réseau
var peer = ENetMultiplayerPeer.new()
var hostname = "localhost"
var port = 11234

# état du jeu
var host_text = ""
var host_morse = ""
var client_answer = []
var game_over = false

# ===== GAME LOOP =====
func _physics_process(_delta):
	
	if (Input.is_action_just_pressed("ui_dot")): # fléche UP, point
		# jouer un son à J1
		rpc("_play_dot")
	elif (Input.is_action_just_pressed("ui_dash")): # fléche DOWN, trait d'union
		# jouer un son à J1
		rpc("_play_dash")
	# Note: Vous pouvez jouer le même son avec différentes durées pour le point (plus courte) et pour le trait d'union (plus longue), ou jouer des sons distincts.

# ===== EVÉNEMENTS INTERFACE =====
func _on_host_pressed():
	peer.create_server(port)
	multiplayer.multiplayer_peer = peer
	
	# montrer l'interface host
	$SendText.show()
	$MainMenu.hide()
	
func _on_join_pressed():
	peer.create_client(hostname, port)
	multiplayer.multiplayer_peer = peer
	
	# montrer l'interface client
	$ReceiveText.show()
	$MainMenu.hide()
	
func _on_btn_send_pressed():
	# à chaque fois que J1 envoye une message, le jeu est redémarré
	client_answer = []
	game_over = false
	host_text = $SendText/TextEdit.get_text()
	
	# chiffrer la message comme réference
	host_morse = get_morse_from_string(host_text)
	$SendText/AnswerPreview.set_text(host_morse)
	
	# envoyer la message à J2
	rpc("_show_text_on_client", host_text)

# ===== LOGIQUE DU JEU =====
func get_morse_from_string(text: String) -> String:
	var morse_code = {
		'A': '.-', 'B': '-...', 'C': '-.-.', 'D': '-..', 'E': '.', 'F': '..-.', 'G': '--.', 'H': '....',
		'I': '..', 'J': '.---', 'K': '-.-', 'L': '.-..', 'M': '--', 'N': '-.', 'O': '---', 'P': '.--.',
		'Q': '--.-', 'R': '.-.', 'S': '...', 'T': '-', 'U': '..-', 'V': '...-', 'W': '.--', 'X': '-..-',
		'Y': '-.--', 'Z': '--..', '1': '.----', '2': '..---', '3': '...--', '4': '....-', '5': '.....',
		'6': '-....', '7': '--...', '8': '---..', '9': '----.', '0': '-----', ' ': '/'
	}
	
	var morse_text = []
	
	for aChar in text.to_upper():
		if aChar in morse_code:
			morse_text.append(morse_code[aChar])
	
	return "".join(morse_text)
	
func reset_game():
	client_answer = []
	host_text = ""
	host_morse = ""
	$ReceiveText/TextDisplay.text = "" # Effacer le texte affiché sur le côté du client
	$SendText/TextEdit.text = "" # Effacer le texte de l'interface d'envoi
	game_over = true
func check_victory():
	#  Joueur 1 vérifie si la séquence reçue jusqu'à ce point correspond au message initial.
	var current_morse = "".join(client_answer)
	print( "current_morse = "+ current_morse)
	print( "morse answer  = "+ host_morse)
	
	if current_morse == host_morse:
		rpc("_show_text_on_client", "Victoire! Message correct.")
		reset_game() # Réinitialiser le jeu après la victoire

	else:
		rpc("_show_text_on_client", "Échec! Le message est incorrect.")
		reset_game() # Réinitialiser le jeu après la victoire


# ===== MÉTHODES RPC =====
@rpc("authority", "call_remote", "reliable")
func _show_text_on_client(text):
	# cette méthode sera appelé par J1
	# envoyer et montrer le texte à J2
	$ReceiveText/TextDisplay.text = text
	
@rpc("any_peer", "call_remote", "reliable")
func _play_dot():
	var current_morse = "".join(client_answer)
	if !game_over:
		# Jouer le beep pour le point. Assurez-vous d'avoir un AudioStreamPlayer configuré
		$PointSound.play()
		# Ajouter le point à la réponse du client
		client_answer.append(".")

		if len(client_answer) == len(host_morse):
			check_victory()

	
@rpc("any_peer", "call_remote", "reliable")
func _play_dash():
	if !game_over:
		# Jouer le beep pour le trait. Assurez-vous d'avoir un AudioStreamPlayer configuré
		$DashSound.play()
		# Ajouter le trait à la réponse du client
		client_answer.append("-")
		if len(client_answer) == len(host_morse):
			check_victory()


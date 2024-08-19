extends Node3D


#Create a peer and select the player scene
var peer = ENetMultiplayerPeer.new()
@export var player_scene : PackedScene
var upnp

##NOTE: at this time, this only works for multiplayer on the same device or LAN I think, I need to do a little more research before I can help
##      with over the internet connections, but whatever you build during this system *should* work over the internet

func _on_host_pressed():
	#Change this port to whatever you want
	upnp = UPNP.new()
	var disc = upnp.discover()
	
	if disc == UPNP.UPNP_RESULT_SUCCESS:
		if upnp.get_gateway() and upnp.get_gateway().is_valid_gateway():
			var map_res = upnp.add_port_mapping(57570, 57570, "voicechatgame", "TCP", 86400)
			upnp.add_port_mapping(57570, 57570, "voicechatgame", "UDP", 86400)
			
			if not map_res == UPNP.UPNP_RESULT_SUCCESS:
				upnp.add_port_mapping(57570, 57570, "voicechatgame", "TCP", 86400)
				upnp.add_port_mapping(57570, 57570, "voicechatgame", "UDP", 86400)
		print("Added upnp at ip " + str(upnp.query_external_address()))
	
	peer.create_server(57570)
	#set the peer we use to the peer we made
	multiplayer.multiplayer_peer = peer
	#whenever someone joins we run add_player
	multiplayer.peer_connected.connect(add_player)
	#add ourselves
	add_player()
	#hide buttons and capture mouse
	$CanvasLayer.hide()
	#Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _on_join_pressed():
	#Change this port and ip to whatever you want, 127.0.0.1 is on the same machine
	peer.create_client("127.0.0.1", 57570)
	#sets the peer to the peer we just made
	multiplayer.multiplayer_peer = peer
	#hide buttons and capture mouse
	$CanvasLayer.hide()
	#Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func add_player(id = 1):
	#instances the player, names it the id of the connecting person, and adds them to the scene
	var player = player_scene.instantiate()
	player.name = str(id)
	call_deferred("add_child",player)


func exit_game(id):
	#disconnect smoothly and delete the player for everyone
	multiplayer.peer_disconnected.connect(del_player)
	del_player(id)
	if multiplayer.get_unique_id() == 1:
		upnp.delete_port_mapping(57570, "UDP")
		upnp.delete_port_mapping(57570, "TCP")
		



func del_player(id):
	#remotley delete the player from everyones game
	_del_player.rpc(id)

#let anyone call this and also call it here
@rpc("any_peer","call_local")
func _del_player(id):
	#queue free the node
	get_node(str(id)).queue_free()




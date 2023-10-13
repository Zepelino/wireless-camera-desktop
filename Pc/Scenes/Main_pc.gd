extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
onready var file_explorer = $HBoxContainer/Panel/path/FileDialog
onready var image_column = $HBoxContainer/right_collumn/VBoxContainer/PanelContainer/Images
onready var path_line = $HBoxContainer/Panel/path
onready var name_line = $HBoxContainer/Panel/path/name
onready var image_holder = preload("res://Mobile/scenes/ImageHolder.tscn")
onready var loading_react = $loading_rect
onready var error_label = $HBoxContainer/Panel/error_label

export (NodePath) var advertiserPath: NodePath
onready var advertiser := get_node(advertiserPath)

const PORT := 3333

var server_data := {"name": "Computer"}

var failed: = false

func _enter_tree():
	var peer = NetworkedMultiplayerENet.new()
	var result = peer.create_server(PORT, 1)
	if result == OK:
		get_tree().set_network_peer(peer)
		print("Game hosted")
	else:
		print("Failed to host game")
		failed = true


func _ready():
	get_tree().connect("network_peer_connected", self, "_connection_status", [0])
	get_tree().connect("network_peer_disconnected", self, "_connection_status", [1])
	
	var server_file = File.new()
	if server_file.file_exists("user://img-server-info.txt"):
		server_file.open("user://img-server-info.txt", File.READ)
		server_data = parse_json(server_file.get_as_text())
		server_file.close()
	
	$HBoxContainer/Panel/path/server_name.text = server_data["name"]
	advertiser.serverInfo["name"] = server_data["name"]
	advertiser.serverInfo["port"] = PORT
	
	if failed:
		error_label.text = "Falha ao estabelecer servidor. Pode ser que outra instância do app já esteja aberta."

func _connection_status(_sus, status):
	match status:
		0:
			print("client connected")
		1:
			print("client disconnected")

remote func _receiving_data():
	loading_react.show()

remote func _send_image(data:PoolByteArray, size: Vector2, format: int, mipmap: bool, data_size):
	loading_react.hide()
	data = data.decompress(data_size, 3)
	var img = Image.new()
	img.create_from_data(size.x, size.y, mipmap, format, data)
	
	var texture = ImageTexture.new()
	texture.create_from_image(img, 0)
	
	var rect = image_holder.instance()
	rect.texture = texture
	image_column.add_child(rect)
	print(img)

func _process(delta):
	file_explorer.rect_position = Vector2(32, 130)
	loading_react.rect_rotation += delta*180


func _on_Button_button_up():
	file_explorer.popup(Rect2(32, 102, 490, 405))


func _on_FileDialog_dir_selected(dir):
	path_line.text = dir
	path_line.self_modulate = Color.white


func _on_save_bt_button_up():
	var directory = Directory.new()
	var valid = true
	
	if not directory.dir_exists(path_line.text) or path_line.text == '':
		path_line.placeholder_text = 'SELECIONE UMA PASTA VÁLIDA'
		path_line.text = ''
		path_line.self_modulate = Color.palevioletred
		valid = false
	if not name_line.text.is_valid_filename():
		name_line.placeholder_text = 'ESCREVA UM NOME VÁLIDO'
		name_line.text = ''
		name_line.self_modulate = Color.palevioletred
		valid = false
	
	if not valid:
		return
	
	var count = 0
	for rect in image_column.get_children():
		var export_img = rect.texture.get_data()
		var export_path = path_line.text + '/' + name_line.text + String(count) + '.png'
		export_img.save_png(export_path)
		count += 1
	


func _on_name_text_changed(new_text):
	while '.' in new_text:
		new_text.erase(new_text.find('.'), 1)
		name_line.text = new_text
		name_line.caret_position = name_line.text.length()
	
	name_line.self_modulate = Color.white


func _on_path_text_changed(_new_text):
	path_line.self_modulate = Color.white


func _on_LineEdit_text_entered(new_text):
	advertiser.serverInfo["name"] = new_text
	server_data.name = new_text
	
	var server_file = File.new()
	server_file.open("user://img-server-info.txt", File.WRITE)
	server_file.store_line(to_json(server_data))
	server_file.close()
	print("opa")

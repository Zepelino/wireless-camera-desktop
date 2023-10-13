extends Control


var image_plugin
onready var warning_text = $Container/error_label
onready var image_collumn = $ScrollContainer/VBoxContainer
onready var image_holder = preload("res://Mobile/scenes/ImageHolder.tscn")
onready var server_opt = $Container/OptionButton
onready var output = $WindowDialog/TextEdit

var hosts: = {}
var host_id: = 1

func _ready():
	
	get_tree().connect("connected_to_server", self, "_connection_status", [0])
	get_tree().connect("connection_failed", self, "_connection_status", [1])
	get_tree().connect("server_disconnected", self, "_connection_status", [2])
	
	if Engine.has_singleton('GodotGetImage'):
		image_plugin = Engine.get_singleton('GodotGetImage')
		image_plugin.connect('image_request_completed', self, '_image_request_completed')
		image_plugin.connect('permission_not_granted_by_user', self, '_image_permission_denied')
	
	server_opt.add_item("Selecionar host")

func _connection_status(status):
	match status:
		0:
			print("connect successfully")
			warning_text.text = "connect successfully"
		1:
			print("failed to connect")
			warning_text.text = "failed to connect"
		2:
			print("connection closed")
			warning_text.text = "connection closed"
			$Container/Send.disabled = true
 
func _image_request_completed(dict):
	for image in dict.values():
		var current_image = Image.new()
		current_image.load_jpg_from_buffer(image)
		current_image.clear_mipmaps()
		current_image.compress(Image.COMPRESS_ETC, Image.COMPRESS_SOURCE_SRGB, 90)
		#warning_text.text = 'Loading Image'
		yield(get_tree(), 'idle_frame')
		var texture = ImageTexture.new()
		texture.create_from_image(current_image, 0)
		
		var texture_rect = image_holder.instance()
		texture_rect.texture = texture
		
		image_collumn.add_child(texture_rect)
		
	

func _on_Button_button_up():
	
	if image_plugin:
		image_plugin.getCameraImage()
		warning_text.text = ''
	else:
		warning_text.text = 'Plugin not loaded'
	


func _on_Send_button_up():
	
	#$WindowDialog.popup() ##para debug
	output.text += String(image_collumn.get_children()) + "\n"
	for rect in image_collumn.get_children():
		output.text += "getting image data\n"
		var img_data: Image = rect.texture.get_data()
		
		var size = img_data.get_size()
		if size.x > 1800 or size.y > 1800:
			img_data.resize(1280, int(1280*size.y/size.x))
		
		var buffer: PoolByteArray = img_data.get_data()
		output.text += "buffer size before: %s\n"%[buffer.size()]
		var buffer_size = buffer.size()
		buffer = buffer.compress(3)
		output.text += "buffer size after: %s\n"%[buffer.size()]
		
		output.text += "image data done, making rpc\n"
		
		rpc("_receiving_data")
		rpc("_send_image", buffer, img_data.get_size(), img_data.get_format(), false, buffer_size)
		output.text += "rpc done\n"


func _on_Node_new_server(info):
	hosts[info.name] = [info.ip, host_id]
	host_id += 1
	server_opt.add_item(info.name)
	server_opt.disabled = false
	"""
	var peer = NetworkedMultiplayerENet.new()
	peer.create_client(info.ip, 3333)
	get_tree().network_peer = peer
	"""


func _on_server_finder_remove_server(info):
	print(info)
	server_opt.remove_item(hosts[info.name][1])
	hosts.erase(info.name)


func _on_OptionButton_item_selected(index):
	if server_opt.get_item_text(index) and hosts.has(server_opt.get_item_text(index)):
		warning_text.text = "trying to connecto to " + server_opt.get_item_text(index)\
		 + '/ IP: ' + hosts[server_opt.get_item_text(index)][0]
		var peer = NetworkedMultiplayerENet.new()
		peer.create_client(hosts[server_opt.get_item_text(index)][0], 3333)
		get_tree().network_peer = peer
		
		yield(get_tree(), "connected_to_server")
		
		$Container/Send.disabled = false


func _on_Add2_button_up():
	if image_plugin:
		image_plugin.getGalleryImages()
		warning_text.text = ''
	else:
		warning_text.text = 'Plugin not loaded'


func _image_permission_denied():
	image_plugin.resendPermission()

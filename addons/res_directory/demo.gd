extends Control

const ResDirectory = preload("res://addons/res_directory/res_directory.gd")

var error_msg = {
	FAILED: "Unspecified failure",
	ERR_FILE_ALREADY_IN_USE: "File already in use",
	ERR_FILE_UNRECOGNIZED: "Unrecognised file format",
	ERR_FILE_CORRUPT: "File is corrupt / incomplete"
}

func popup_message(text):
	var msgbox = AcceptDialog.new()
	msgbox.dialog_text = text
	msgbox.popup_exclusive = true
	msgbox.connect("popup_hide", msgbox, "queue_free")
	get_tree().get_root().add_child(msgbox)
	msgbox.popup_centered()

func _on_FileDialog_file_selected(path):
	var res = ResDirectory.new()
	var err = res.open(path)
	if err != OK:
		res = null
		var errmsg = "ResDirectory returned error code " + str(err)
		if error_msg.has(err):
			errmsg = errmsg + "\n(" + error_msg[err] + ")"
		popup_message(errmsg + "\n\nIs this resource pack really alright, human?")
		return

	popup_message("Res opened successfully!\nDiscovered " + str(res.file_count()) + " items.")

	var list = $VBoxContainer/RichTextLabel
	list.text = "Files in '" + path + "':\n\n"
	for entry in res.directory:
		list.text = list.text + entry.path + "\n"

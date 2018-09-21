extends Reference

const SIG_CDFH = 0x02014b50

var error = OK

# Entry data
var path # string

# Self-populates from an open file.
func _init(f):
	if f.get_32() != SIG_CDFH:
		error = ERR_FILE_CORRUPT
		return

	f.seek(f.get_position()
		+ 2 * 6 # skip versions, flags, compression method, file modification time, date
		+ 4 * 3 # skip CRC-32, compressed size, size
	)

	var path_len = f.get_16()
	if path_len < 0:
		error = FAILED
		return

	var extra_field_len = f.get_16()
	if extra_field_len < 0:
		error = FAILED
		return

	var file_comment_len = f.get_16()
	if file_comment_len < 0:
		error = FAILED
		return

	# Disk where file starts
	# Unimplemented
	if f.get_16() != 0:
		error = FAILED
		return

	f.seek(f.get_position()
		+ 2 + 4 # skip file attributes
		+ 4 # skip 32-bit offset of file header
		# (maybe useful if we were attempting to extract the file, but we're certainly not)
	)

	path = f.get_buffer(path_len).get_string_from_utf8()
	if typeof(path) == TYPE_STRING:
		# Convert the internal path to a Godot Engine resource path.
		path = "res://" + path

	# skip extra field and comment
	f.seek(f.get_position() + extra_field_len + file_comment_len)

func sanity():
	return error == OK and typeof(path) == TYPE_STRING

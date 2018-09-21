extends Reference

var error = OK

var path # string
var offset # int64
var size # int64
var md5 # PoolByteArray

var pck_path # string

# Self-populates from an open file.
func _init(f):
	pck_path = f.get_path()

	var path_len = f.get_32()
	if path_len < 0:
		error = FAILED
		return

	path = f.get_buffer(path_len).get_string_from_utf8()

	# TODO: Make sure these still work correctly over 4 GB even if they end up negative or something. @_@;;
	offset = f.get_64()
	size = f.get_64()

	md5 = f.get_buffer(16)

# Sanity test the data
# Returns false if something went awry.
# Used to detect file corruption.
func sanity():
	return error == OK \
		and typeof(path) == TYPE_STRING \
		and typeof(offset) == TYPE_INT \
		and typeof(size) == TYPE_INT \
		and typeof(md5) == TYPE_RAW_ARRAY \
		and typeof(pck_path) == TYPE_STRING

# returns an ERR_ code or a PoolByteArray containing this pck entry's data.
# check with typeof() == TYPE_INT or similar to see if it's an error code, just in case
func read():
	if size == 0:
		return PoolByteArray([])
	var f = File.new()
	var err = f.open(pck_path, File.READ)
	if err != OK:
		return err
	f.seek(offset)
	if f.eof_reached():
		f.close()
		return ERR_FILE_CORRUPT
	var buff = f.get_buffer(size)
	f.close()
	if buff.size() != size:
		return ERR_FILE_CORRUPT
	return buff

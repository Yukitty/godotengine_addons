extends Reference

const PckDirectoryEntry = preload("pck_entry.gd")
const ZipDirectoryEntry = preload("zip_entry.gd")

var directory # Array of DirectoryEntry

const SIG_PCK = 0x43504447
const SIG_EOCD = 0x06054b50

# Searches a file for a matching 32-bit sig, one byte at a time, front to back... Ugh!
# Returns the offset it was found at.
#
# Used to detect and read zip files, which don't necessarily start at the beginning OR a fixed distance from the end,
# and although it's more likely to be at the very end of the file, searching from the end would inevitably
# result in malicious users tricking you into reading an incorrect payload.
func find_sig(f, sig):
	while f.get_error() == OK:
		if f.get_32() == sig:
			return f.get_position() - 4
		if f.eof_reached():
			break
		f.seek(f.get_position() - 3)
	return -1

# Takes a path to a resource file (pck or zip)
# Calls open_pck or open_zip appropriately.
# Populates directory
# Returns an ERR_ or OK
func open(path):
	directory = null

	# Open the file for reading.
	# If it doesn't exist or otherwise unavailable, return the error.
	var f = File.new()
	var err = f.open(path, File.READ)
	if err != OK:
		return err

	# Is it a pck?
	if f.get_32() == SIG_PCK:
		return open_pck(f)

	# No?
	f.seek(0)

	# Maybe it's a zip?
	var offset = find_sig(f, SIG_EOCD)
	if offset != -1:
		return open_zip(f, offset)

	# Unknown file type.
	return ERR_FILE_UNRECOGNIZED

# Takes a path or open file
# Reads it as a pck
# Populates directory
# Returns an ERR_ or OK
func open_pck(path):
	var f

	if path is File:
		f = path
		path = f.get_path()
		f.seek(0)
	else:
		f = File.new()
		var err = f.open(path, File.READ)
		if err != OK:
			return err

	# Make sure the magic filetype identifier matches.
	if f.get_32() != SIG_PCK:
		return ERR_FILE_UNRECOGNIZED

	f.seek(4 * 5 # skip magic, version, major, minor, rev
		+ 4 * 16) # skip reserved header padding

	# Make sure the file stream is still good.
	if f.get_error() != OK:
		f.close()
		return ERR_FILE_CORRUPT

	# Read the entire directory into memory and store it in a big ol' array.
	directory = Array()
	var count = f.get_32()
	if count < 0:
		f.close()
		return ERR_FILE_CORRUPT
	for i in range(count):
		# Read an entry.
		var e = PckDirectoryEntry.new(f)

		# Make sure we didn't EOF or get bad data
		if f.get_error() != OK:
			f.close()
			directory = null
			return ERR_FILE_CORRUPT

		if not e.sanity():
			f.close()
			directory = null
			if e.error != OK:
				return e.error
			return FAILED

		# Add it to the directory and read the next one.
		directory.push_back(e)

	# All done~
	f.close()
	return OK

func open_zip(path, offset):
	var f

	if path is File:
		f = path
		path = f.get_path()
		f.seek(0)
	else:
		f = File.new()
		var err = f.open(path, File.READ)
		if err != OK:
			return err

	if not offset:
		offset = find_sig(f, SIG_EOCD)
		if offset == -1:
			return ERR_FILE_UNRECOGNIZED

	# Read the EOCD
	f.seek(offset)
	if f.get_32() != SIG_EOCD:
		return ERR_FILE_UNRECOGNIZED

	# Floppy disk splits
	# Unimplemented
	if f.get_32() != 0:
		return FAILED

	# Number of central directory records on this disk
	var count = f.get_16()

	# Total number of central directory records (w/ floppy disk splits)
	# Unimplemented
	if count != f.get_16():
		return FAILED

	# Grab the central directory's size and offset.
	var size = f.get_32()
	offset = f.get_32()

	# Make sure we didn't EOF or something while we were skimming over all that.
	if f.get_error() != OK:
		return ERR_FILE_CORRUPT

	# Alright, now read the Central Directory.
	directory = Array()
	f.seek(offset)
	while f.get_position() - offset < size:
		# Read an entry.
		var e = ZipDirectoryEntry.new(f)

		# Make sure we didn't EOF or get bad data
		if f.get_error() != OK:
			f.close()
			directory = null
			return ERR_FILE_CORRUPT

		if not e.sanity():
			f.close()
			directory = null
			if e.error != OK:
				return e.error
			return FAILED

		# Add it to the directory and read the next one.
		directory.push_back(e)

	return OK

# Alias for directory size. :P
func file_count():
	if directory:
		return directory.size()
	return null

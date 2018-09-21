# ResDirectory
Parses the contained file directory of external `pck` and `zip` files in GDScript.

Intended purpose: Aide to simple blacklisting of certain folder names or file extensions before allowing user-provided packages to be added to your resource tree.

## How to use
See `demo.gd` (and `demo.tscn`) for a working example.

- Load the addon script with `const ResDirectory = preload("res://addons/res_directory/res_directory.gd")` (Now you can pretend it's a built-in class with a proper name!)
- Call `r = ResDirectory.new()` to make a new file handler. (Referred to as `r` below)
- Call `int r.open(String path)` to read a pck or zip file. It returns an `ERR_` code, so make sure that's `OK` before continuing!
- Check `int r.file_count()` for how many files are included in the package, if that interests you.
- Iterate the file list with `for e in r.directory:` (Entries in the `r.directory[]` array are referred to as `e` below)
- Check the `e.path` string for the full `res://` path to each file in the package.
- Do whatever validation you want on the string and decide for yourself whether to abort loading the package proper or not.

More values and functions may be added to `e` in the future.


# Package openmw.vfs

# Package openmw.vfs

API v129

Provides read-only access to data directories via VFS.

Interface is very similar to "io" library.

global
menu
local
player
load

## Usage

`local vfs = require('openmw.vfs')`

## Type `vfs`

vfs.fileExists(fileName)

Check if a file exists in VFS

vfs.lines(fileName)

Get an iterator function to fetch the next line from a file with the given path.

vfs.open(fileName)

Open a file

vfs.pathsWithPrefix(path)

Get an iterator function to fetch file names with given path prefix from the VFS

vfs.type(handle)

Detect a file handle type

## Type `FileHandle`

FileHandle:close()

Close a file handle

FileHandle.fileName

VFS path to related file

FileHandle:lines()

Get an iterator function to fetch the next line from a given file.

FileHandle:read(...)

Read data from a file to strings.

FileHandle:seek(whence, offset)

Set new position in a file.

## Type `vfs`

### Field(s)

vfs.fileExists(fileName)

Check if a file exists in VFS

### Parameter

-
` #string fileName `:
Path to file in VFS

### Return value

#boolean:
(true - exists, false - does not exist)

### Usage

`local exists = vfs.fileExists("Test\\test.txt");`

vfs.lines(fileName)

Get an iterator function to fetch the next line from a file with the given path.

Throws an exception if the file is closed or the file with the given path does not exist.
Closes the file automatically when it fails to read any more bytes.

Hint: since garbage collection works once per frame,
you will get the whole file in RAM if you read it in one frame.
So if you need to read a really large file, it is better to split reading
between different frames (e.g. by keeping a current position in file
and using a "seek" to read from saved position).

### Parameter

-
` #string fileName `:
Path to file in VFS

### Return value

#function:
Iterator function to get next line

### Usage

`for line in vfs.lines("Test\\test.txt") do
print(line);
end`

vfs.open(fileName)

Open a file

### Parameter

-
` #string fileName `:
Path to file in VFS

### Return values

-
#FileHandle:
Opened file handle if a call succeeds without errors.

-
#nil, #string:
nil plus the error message in case of any error.

### Usage

`f, msg = vfs.open("Test\\test.txt");
-- print file name or error message
if (f == nil)
print(msg);
else
print(f.fileName);
end`

vfs.pathsWithPrefix(path)

Get an iterator function to fetch file names with given path prefix from the VFS

### Parameter

-
` #string path `:
Path prefix

### Return value

#function:
Function to get next file name

### Usages

-

`-- get all files with given prefix from VFS index
for fileName in vfs.pathsWithPrefix("Music\\Explore") do
print(fileName);
end`

-

`-- get some first files
local getNextFile = vfs.pathsWithPrefix("Music\\Explore");
local firstFile = getNextFile();
local secondFile = getNextFile();`

vfs.type(handle)

Detect a file handle type

### Parameter

-
` #any handle `:
Object to check

### Return value

#string:
File handle type. Can be:

- "file" - an argument is a valid opened openmw.vfs#FileHandle;

- "closed file" - an argument is a valid closed openmw.vfs#FileHandle;

- nil - an argument is not a openmw.vfs#FileHandle;

### Usage

`f = vfs.open("Test\\test.txt");
print(vfs.type(f));`

## Type `FileHandle`

### Field(s)

FileHandle:close()

Close a file handle

### Return values

-
#boolean:
true if a call succeeds without errors.

-
#nil, #string:
nil plus the error message in case of any error.

#string

FileHandle.fileName

VFS path to related file

FileHandle:lines()

Get an iterator function to fetch the next line from a given file.

Throws an exception if the file is closed.

Hint: since garbage collection works once per frame,
you will get the whole file in RAM if you read it in one frame.
So if you need to read a really large file, it is better to split reading
between different frames (e.g. by keeping a current position in file
and using a "seek" to read from saved position).

### Return value

#function:
Iterator function to get next line

### Usage

`f = vfs.open("Test\\test.txt");
for line in f:lines() do
print(line);
end`

FileHandle:read(...)

Read data from a file to strings.

Throws an exception if the file is closed, if there are too many arguments or if an invalid format is encountered.

Hint: since garbage collection works once per frame,
you will get the whole file in RAM if you read it in one frame.
So if you need to read a really large file, it is better to split reading
between different frames (e.g. by keeping a current position in file
and using a "seek" to read from saved position).

### Parameter

-
` ... `:
Read formats (up to 20 arguments, default value is one "*l"). Can be:

- "*a" (or "*all") - reads the whole file, starting at the current position as #string. On end of file, it returns the empty string.

- "*l" (or "*line") - reads the next line (skipping the end of line), returning nil on end of file (nil and error message if error occured);

- "*n" (or "*number") - read a floating point value as #number (nil and error message if error occured);

- number - reads a #string with up to this number of characters, returning nil on end of file (nil and error message if error occured). If number is 0 and end of file is not reached, it reads nothing and returns an empty string;

### Return value

#string:
One #string for every format if a call succeeds without errors. One #string for every successfully handled format, nil for first failed format.

### Usages

-

`-- read three numbers from file
f = vfs.open("Test\\test.txt");
local n1, n2, n3 = f:read("*number", "*number", "*number");`

-

`-- read 10 bytes from file
f = vfs.open("Test\\test.txt");
local n4 = f:read(10);`

-

`-- read until end of file
f = vfs.open("Test\\test.txt");
local n5 = f:read("*all");`

-

`-- read a line from file
f = vfs.open("Test\\test.txt");
local n6 = f:read();`

-

`-- try to read three numbers from file with "1" content
f = vfs.open("one.txt");
print(f:read("*number", "*number", "*number"));
-- prints(1, nil)`

FileHandle:seek(whence, offset)

Set new position in a file.

Throws an exception if the file is closed or seek base is incorrect.

### Parameters

-
` #string whence `:
Seek base (optional, "cur" by default). Can be:

- "set" - seek from beginning of file;

- "cur" - seek from current position;

- "end" - seek from end of file (offset needs to be <= 0);

-
` #number offset `:
Offset from given base (optional, 0 by default)

### Return values

-
#number:
new position in file if a call succeeds without errors.

-
#nil, #string:
nil plus the error message in case of any error.

### Usages

-

`-- set pointer to beginning of file
f = vfs.open("Test\\test.txt");
f:seek("set");`

-

`-- print current position in file
f = vfs.open("Test\\test.txt");
print(f:seek());`

-

`-- print file size
f = vfs.open("Test\\test.txt");
print(f:seek("end"));`

Package openmw.util

Package openmw.world

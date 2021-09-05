# ZTWRK

A simplified version of the Zeitwerk autoloader, written to help understand how the internals work.

This is purely exploratory code, and should not be used for anything. It lacks tests, configurability, thread-safety, and generally any attribute you'd want in production code.

What it does have is an extremely simplified representation of Zeitwerk autoloads a directory. It only supports one directory and one autoloader at a time - if you create another autoloader it will just overwrite the first one in `ZTWRK.loader`.

To use, simply include the script, instantiate a loader, and run `setup`. See `example.rb` for more detail.

This is written without the use of external gems for understandability.

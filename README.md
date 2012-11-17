
# Ada2Str
Ada2Str is a command line program which creates StrongHelp documentation
for Ada specifications. It is supplied with a desktop frontend, but is
also useable on its own.

NOTE: This is an app for RISC OS.


# Acknowledgments
This program uses 'AdaDoc' developed by Julien Burdy and
Vincent Decorges.

# Frontend use
1. Double click on the !Ada2Str icon - this will place an icon on the
iconbar. 
2. SELECT clicking on the iconbar icon will open a setup window.
3. Fill in the information needed and SELECT click on 'Run'. Use the
interactive help to get information about what to fill in where.

This will start the Ada2Str command line program and open a window
showing the status.

# Command line use
Syntax: ada2str docname sourcedir targetdir

All arguments are mandatory. Source and target must be directories.

The AdaDoc documentation and sourcecode is available at AdaDocs project
page on http://adadoc.sourceforge.net/
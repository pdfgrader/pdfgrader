# PDF GRADER 2.0


Getting Started:

https://valadoc.org/

Scripts: These scripts are designed for linux based systems

  pdfgrader/program/installDependencies.sh is a script that should install vala, valac, poppler (pdf library), and gee (list and object library)

  pdfgrader/program/maintain.sh is a script meant to build pdfgrader with make, then create a tar distribution

pdfgrader/program/Makefile.am is the Makefile that autotools uses. **Here you can see a full list of dependencies and package names.**

Package names and commands to install dependencies will depend on what flavor of linux you are using or emulating. 

We recommend MSYS2 for running PDFGRADER on a windows system.

https://www.msys2.org/

Package installation syntax is a little different with MSYS2 but is the same idea
https://github.com/msys2/msys2/wiki/Using-packages

Other helpful links
https://help.ubuntu.com/community/Vala
https://github.com/gerito1/vala-gtk-examples
https://valadoc.org/glib-2.0/GLib.Test.html

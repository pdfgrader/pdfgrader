# PDF GRADER

## Getting Started:

https://valadoc.org/

Scripts: These scripts are designed for linux based systems
- pdfgrader/program/installDependencies.sh is a script that should install the required libraries which are vala, valac, poppler (pdf library), and gee (list and object library), gtk, and libxml
- pdfgrader/program/maintain.sh is a script meant to build pdfgrader with make, then create a tar distribution

pdfgrader/program/Makefile.am is the Makefile that autotools uses. **Here you can see a full list of dependencies and package names.**

Package names and commands to install dependencies will depend on what flavor of linux you are using or emulating.

We recommend WSL for running and developing PDFGRADER on a windows system as our tools are for setting up on WSL/Linux but you can use [MSYS](https://www.msys2.org/).

[Package installation syntax](https://github.com/msys2/msys2/wiki/Using-packages) is a little different with MSYS2 but is the same idea

  

Other helpful links

[Ubuntu Community Vala Help](https://help.ubuntu.com/community/Vala)

[GTK examples in Vala](https://github.com/gerito1/vala-gtk-examples)

[GLib testing documentation](https://valadoc.org/glib-2.0/GLib.Test.html)

  

## Code Conventions:

### Braces:

- `if/else`, `for`, `while`, and `try/catch` should always have opening and closing braces

and their bodies should start on the following line

- Opening braces should always be on the same line as the statement

- `else` and `catch` statements should be on the same line as the preceding closing brace

### Spacing:

- Tabs should be set to 4 spaces

- There should not be any trailing spaces

### Naming:

- Variable names should reflect what they will be used for, easily understandable and in

- Follow Vala conventions for naming identifiers.

	- Variables and class fields are lowercase_with_underscores.

	- Namespaces and class names are CamelCased.

	- Method names are all lowercase and use underscores to separate words
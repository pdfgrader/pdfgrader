bin_PROGRAMS = pdfgrader


AM_CFLAGS = $(pdfgrader_CFLAGS)
AM_VALAFLAGS = $(pdfgrader_CFLAGS)

pdfgrader_LDADD = $(pdfgrader_LIBS)

pdfgrader_VALAFLAGS = --pkg=gtk+-3.0 --pkg=poppler-glib --pkg cairo --pkg gee-0.8 --pkg glib-2.0 --pkg libxml-2.0 --pkg posix


clean-git: clean-custom clean-autotools

clean-custom: 
	rm -f src/main/*.o 
	rm -f src/main/*.c 
	rm -f PDFGrader.exe
	rm -f pdfgrader
	rm -f pdfgrader_vala.stamp
	rm -f pdfgrader-0.2.tar.gz 
	rm -f stamp-h1

clean-autotools:
	rm -f Makefile.in
	rm -f Makefile
	rm -f aclocal.m4
	rm -rf autom4te.cache
	rm -f compile
	rm -f config.h
	rm -f config.h.in
	rm -f config.log
	rm -f config.status
	rm -f configure
	rm -f depcomp
	rm -f missing
	rm -f install-sh

PDFGrader.exe: src/main/System.vala src/main/QuestionSet.vala src/main/Question.vala src/main/Mark.vala src/main/Save.vala src/main/ExamImage.vala
	valac -o PDFGrader.exe --pkg=gtk+-3.0 --pkg=poppler-glib --pkg cairo --pkg gee-0.8 --pkg glib-2.0 --pkg libxml-2.0 --pkg posix src/main/System.vala src/main/QuestionSet.vala src/main/Question.vala src/main/Mark.vala src/main/Save.vala src/main/Lock.vala src/main/Export.vala src/main/ExamImage.vala

pdfgrader_SOURCES = src/main/System.vala \
    	src/main/ExamImage.vala \
	src/main/Export.vala \
	src/main/Mark.vala \
	src/main/QuestionSet.vala \
	src/main/Question.vala \
	src/main/Save.vala \
	src/main/Lock.vala

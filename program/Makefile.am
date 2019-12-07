bin_PROGRAMS = pdfgrader


AM_CFLAGS = $(pdfgrader_CFLAGS)
AM_VALAFLAGS = $(pdfgrader_CFLAGS)

pdfgrader_LDADD = $(pdfgrader_LIBS)

pdfgrader_VALAFLAGS = --pkg=gtk+-3.0 --pkg=poppler-glib --pkg cairo --pkg gee-0.8 --pkg glib-2.0 --pkg libxml-2.0 --pkg posix

pdfgrader_SOURCES = src/main/System.vala \
	src/main/Export.vala \
	src/main/Mark.vala \
	src/main/QuestionSet.vala \
	src/main/Question.vala \
	src/main/Save.vala \
	src/main/Lock.vala

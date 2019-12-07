public class Export : Object
{
    private Export() {}

    //calculates the number of digits it takes to display number (in base 10)
    private static int numDigits(int number)
    {
        string numstr = number.to_string();

        return numstr.char_count();
    }

    //returns a string that represents num, but with 0's padded on the left
    // to reach the maximum number of digits in the number maxNum
    private static string numToPadded(int num, int maxNum)
    {
        int numDigits = Export.numDigits(num);
        int maxNumDigits = Export.numDigits(maxNum);
        int zeroToPad = maxNumDigits - numDigits;

        string finalString = "";
        for (int i = 0; i < zeroToPad; i++)
        {
            finalString = finalString + "0";
        }

        return finalString + num.to_string();
    }

    //takes in a raw percentage (0.0 to 1.0) and returns a string that represents the %, 
    // rounded to 2 decimal places.
    // example: input = 0.743658309
    //          output = 74.37
    private static string percentageToPrettyString(double percentage)
    {
        int leftPart = (int)(percentage*100);
        int rightPart = (int)GLib.Math.round(percentage*10000) % 100;

        return leftPart.to_string() + "." + rightPart.to_string();
    }
    
    //goes through all of the files in .data and exports them to latex files
    public static void exportAsLaTeX(string filePath)
    {
        //create the folder if it doesnt already exist
        try
        {
            GLib.File dir = GLib.File.new_for_path(filePath);
            if (!dir.query_exists())
            {
                dir.make_directory();
            }
        }
        catch (GLib.Error e)
        {
            stderr.printf("Error when trying to create folder: %s\n", e.message);
        }
        
        //create the folder to put all of the pictures in
        try
        {
            GLib.File imagesDir = GLib.File.new_for_path(filePath + "/latexImages");
            if (!imagesDir.query_exists())
            {
                imagesDir.make_directory();
            }
        }
        catch (GLib.Error e)
        {
            stderr.printf("Error when trying to create picture folder: %s\n", e.message);
        }
        
        int numStudents = 0;
        if (System.examQuestionSet.size > 0)
        {
            numStudents = System.examQuestionSet.get(0).questions.size;
        }
        
        //save the window label for later
        string windowOriginalLabel = System.mainWindow.get_title();
        System.mainWindow.set_title("Exporting...");
        
        //load the questions from the files in .data
        Gee.ArrayList<QuestionSet> questionSets = new Gee.ArrayList<QuestionSet>();
        
        for (int i = 0; i <= System.examQuestionsPerTest; i++)
        {
            try
            {
                QuestionSet nextQuestion;
                Save.fileImport(i, numStudents, out nextQuestion, System.PDFPath, false);
                questionSets.add(nextQuestion);
            }
            catch (GLib.FileError e)
            {
                stderr.printf("GLib.FileError when trying to load in questions during export: %s\n", e.message);
            }
            catch (GLib.MarkupError e)
            {
                stderr.printf("GLib.MarkupError when trying to load in questions during export: %s\n", e.message);
            }
        }
        
        //generate all of the images
        for (int student = 0; student < numStudents; student++)
        {
            string sutdentNumPadded = Export.numToPadded(student+1, numStudents+1);

            //generate student name image
            System.mainWindow.set_title("Generating Student" + sutdentNumPadded + "_Name.png");
            Gdk.Pixbuf studentName = System.examImage.renderQuestionOnTest(questionSets.get(0), student);
            string nameFilename = "".concat(filePath, "/latexImages/", "Student", sutdentNumPadded, "_Name", ".png");
            try
            {
                studentName.save(nameFilename, "png");
            }
            catch (GLib.Error e)
            {
                stderr.printf("Error when trying to export png file: %s\n", e.message);
            }
                
            //loop through all question sets to go through a single exam:
            for (int question = 1; question < questionSets.size; question++)
            {
                System.mainWindow.set_title("Generating Student" + sutdentNumPadded + "__Question" + (question).to_string() + ".png");
                Gdk.Pixbuf studentAnswer = System.examImage.renderQuestionOnTest(questionSets.get(question), student);
                string filename = "".concat(filePath, "/latexImages/", "Student", sutdentNumPadded, "_Question", (question).to_string(), ".png");
                try
                {
                    studentAnswer.save(filename, "png");
                }
                catch (GLib.Error e)
                {
                    stderr.printf("Error when trying to export png file: %s\n", e.message);
                }
            }
        }

        Gee.ArrayList<StudentSummary> studentSummaries = new Gee.ArrayList<StudentSummary>();
        
        //create the .tex file for each student
        for (int student = 0; student < numStudents; student++)
        {
            string sutdentNumPadded = Export.numToPadded(student+1, numStudents+1);

            //create the .tex file that pdflatex will generate the pdf from
            try
            {
                GLib.File latexFile = GLib.File.new_for_path(filePath + "/" + "Student" + sutdentNumPadded + "Report.tex");
                
                if (latexFile.query_exists()) //delete it if it already exists.
                {
                    latexFile.delete();
                }
                
                DataOutputStream dos = new DataOutputStream(latexFile.create(FileCreateFlags.REPLACE_DESTINATION));
                
                //write to the file
                
                //first page (name picture)
                dos.put_string("""\documentclass[12pt]{article}""" + "\n");
                dos.put_string("""\usepackage{graphicx}""" + "\n");
                dos.put_string("""\usepackage{hyperref}""" + "\n");
                dos.put_string("""\usepackage{ltablex}""" + "\n");
                dos.put_string("""\begin{document}""" + "\n\n");
                
                dos.put_string("""\begin{figure}[ht!]""" + "\n");
                dos.put_string("""\centering""" + "\n");
                dos.put_string("""\includegraphics[width=\linewidth]{latexImages/Student""" + sutdentNumPadded + "_Name.png}\n");
                dos.put_string("""\end{figure}""" + "\n\n");
                
                //loop through all question sets to go through a single exam:
                for (int questionNum = 1; questionNum < questionSets.size; questionNum++)
                {
                    dos.put_string("""\newpage""" + "\n");
                    
                    dos.put_string("""\begin{figure}[ht!]""" + "\n");
                    dos.put_string("""\centering""" + "\n");
                    dos.put_string("""\includegraphics[width=\linewidth]{latexImages/Student""" + sutdentNumPadded + "_Question" + questionNum.to_string() + ".png}\n");
                    dos.put_string("""\end{figure}""" + "\n");
                    
                    QuestionSet questionSet = questionSets.get(questionNum);
                    Gee.HashMap<int, Mark> pool = questionSet.rubricPool;
                    
                    //get the current student's question
                    Question question = questionSet.questions.get(student);
                    
                    //calculate points lost
                    double pointsLost = 0.0;
                    Gee.ArrayList<int> marks = question.marks;
                    for (int z = 0; z < marks.size; z++)
                    {
                        Mark mark = pool.get(marks.get(z));
                        if (mark != null)
                        {
                            pointsLost += mark.getWorth();
                        }
                    }
                    question.pointsEarned = questionSet.totalPoints + pointsLost;
                    
                    dos.put_string("Points: " + question.pointsEarned.to_string() + " out of " + questionSet.totalPoints.to_string() + "\n\n");
                    dos.put_string("Comments:\n\n");
                    
                    //print mark descriptions
                    for (int z = 0; z < marks.size; z++)
                    {
                        Mark mark = pool.get(marks.get(z));
                        if (mark != null)
                        {
                            dos.put_string(toLatexSafeString(mark.getDescription()) + "\n\n");
                        }
                    }
                }
                
                //summary
                
                //table setup
                dos.put_string("""\newpage""" + "\n");
                dos.put_string("""\begin{tabularx}{\linewidth}{|c|c|c|X|}""" + "\n");
                dos.put_string("""\hline""" + "\n");
                dos.put_string("""\textbf{Question} & \textbf{Points Earned} & \textbf{Points Possible} & \textbf{Comments} \\""" + "\n");
                dos.put_string("""\hline""" + "\n");
                
                double pointsTest = 0.0;
                double pointsEarned = 0.0;
                
                //loop through all question sets to go through a single exam:
                for (int questionNum = 1; questionNum < questionSets.size; questionNum++)
                {
                    dos.put_string("""\hyperlink{page.""" + (questionNum+1).to_string() + "}{" + questionNum.to_string() + "} & ");
                    
                    QuestionSet questionSet = questionSets.get(questionNum);
                    Gee.HashMap<int, Mark> pool = questionSet.rubricPool;
                    
                    //get the current student's question
                    Question question = questionSet.questions.get(student);
                    
                    dos.put_string(question.pointsEarned.to_string() + " & " + questionSet.totalPoints.to_string() + " & ");
                    pointsTest += questionSet.totalPoints;
                    pointsEarned += question.pointsEarned;
                    
                    bool firstIter = true;
                    
                    //print mark descriptions
                    Gee.ArrayList<int> marks = question.marks;
                    for (int z = 0; z < marks.size; z++)
                    {
                        Mark mark = pool.get(marks.get(z));
                        if (mark != null)
                        {
                            if (firstIter)
                            {
                                dos.put_string(toLatexSafeString(mark.getDescription()));
                            }
                            else
                            {
                                dos.put_string(""" \newline \newline """ + toLatexSafeString(mark.getDescription()));
                            }
                            
                            firstIter = false;
                        }
                    }

                    if (firstIter)
                    {
                        //the student didn't have any marks assigned to them, put some default comment.
                        dos.put_string("No grade assigned by grader.");
                    }
                    
                    dos.put_string(""" \\ [0.5ex]""" + "\n");
                    dos.put_string("""\hline""" + "\n");
                }
                
                string finalGrade = Export.percentageToPrettyString(pointsEarned/pointsTest);

                //make a summary of this student for later, when we create the final report of all students
                StudentSummary thisStudentSummary = new StudentSummary("Student" + sutdentNumPadded,
                                                                       "latexImages/Student" + sutdentNumPadded + "_Name.png",
                                                                       pointsEarned.to_string(),
                                                                       pointsTest.to_string(),
                                                                       finalGrade);
                studentSummaries.add(thisStudentSummary);
                
                //total score
                dos.put_string("Total & " + pointsEarned.to_string() + " & " + pointsTest.to_string() + " & " + finalGrade + """\% \\ [0.5ex]""" + "\n");
                dos.put_string("""\hline""" + "\n");
                
                //close out the summary table and document
                dos.put_string("""\end{tabularx}""" + "\n");
                dos.put_string("""\end{document}""" + "\n");
            }
            catch (GLib.Error e)
            {
                stderr.printf("Error when trying to export LaTeX file: %s\n", e.message);
            }
        }

        //export the final report of all the students
        System.mainWindow.set_title("Generating Final Report");
        try
        {
            GLib.File latexFile = GLib.File.new_for_path(filePath + "/FinalReport.tex");
            
            if (latexFile.query_exists()) //delete it if it already exists.
            {
                latexFile.delete();
            }
            
            DataOutputStream dos = new DataOutputStream(latexFile.create(FileCreateFlags.REPLACE_DESTINATION));

            //first page
            dos.put_string("""\documentclass[12pt]{article}""" + "\n");
            dos.put_string("""\usepackage{graphicx}""" + "\n");
            dos.put_string("""\usepackage{ltablex}""" + "\n");
            dos.put_string("""\begin{document}""" + "\n\n");

            //page for every student
            for (int student = 0; student < numStudents; student++)
            {
                StudentSummary summary = studentSummaries.get(student);

                //name image
                dos.put_string("""\begin{figure}[ht!]""" + "\n");
                dos.put_string("""\centering""" + "\n");
                dos.put_string("""\includegraphics[width=\linewidth]{""" + summary.nameImage + "}\n");
                dos.put_string("""\end{figure}""" + "\n\n");
                
                //other
                dos.put_string(summary.studentNumberPadded + "\n\n");
                dos.put_string("Score: " + summary.pointsReceived + " out of " + summary.pointsPossible + " (" + summary.scorePretty + """\%)""" + "\n\n");
                dos.put_string("""\newpage""" + "\n\n");
            }

            //final report page
            dos.put_string("""\begin{tabularx}{\linewidth}{|c|c|c|X|}""" + "\n");
            dos.put_string("""\hline""" + "\n");
            dos.put_string("""\textbf{Student} & \textbf{Points Earned} & \textbf{Points Possible} & \textbf{Score} \\""" + "\n");
            dos.put_string("""\hline""" + "\n");

            for (int student = 0; student < numStudents; student++)
            {
                StudentSummary summary = studentSummaries.get(student);

                dos.put_string((student+1).to_string() + " & ");
                dos.put_string(summary.pointsReceived + " & ");
                dos.put_string(summary.pointsPossible + " & ");
                dos.put_string(summary.scorePretty + """\% \\""" + "\n");
                dos.put_string("""\hline""" + "\n");
            }

            //close out the final table
            dos.put_string("""\end{tabularx}""" + "\n");

            //close out the document
            dos.put_string("""\end{document}""" + "\n");
        }
        catch (GLib.Error e)
        {
            stderr.printf("Error when trying to export LaTeX file: %s\n", e.message);
        }
        
        //restore the windows label
        System.mainWindow.set_title(windowOriginalLabel);
    }

    //gets rid of special characters that would mess up LaTeX
    private static string toLatexSafeString(string raw)
    {
        string fix = "";
        fix = raw.replace("_",  "*");
        fix = fix.replace("{",  "*");
        fix = fix.replace("}",  "*");
        fix = fix.replace("\\", "*");
        fix = fix.replace("%",  "*");
        fix = fix.replace("$",  "*");
        fix = fix.replace("#",  "*");
        fix = fix.replace("<",  "*");
        fix = fix.replace(">",  "*");
        fix = fix.replace("^",  "*");
        fix = fix.replace("&",  "*");

        return fix;
    }
}

private class StudentSummary : Object
{
    public string studentNumberPadded;
    public string nameImage;
    public string pointsReceived;
    public string pointsPossible;
    public string scorePretty;

    public StudentSummary(string studentNumberPadded, 
                          string nameImage,
                          string pointsReceived,
                          string pointsPossible,
                          string scorePretty)
    {
        this.studentNumberPadded = studentNumberPadded;
        this.nameImage = nameImage;
        this.pointsReceived = pointsReceived;
        this.pointsPossible = pointsPossible;
        this.scorePretty = scorePretty;
    }
}

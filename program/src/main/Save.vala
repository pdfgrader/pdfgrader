public class Save
{
    //called when we are done setting up a new test, saves all of the initial
    // questions to the files in the .data directory
    public static void saveAll(string path, Gee.ArrayList<QuestionSet> questions){
      foreach (QuestionSet q in questions) {
        Save.save(q.getQNum(), q, false, path);
      }
    }

    public static void saveSpecific(string path, QuestionSet question){
      Save.save(question.getQNum(), question, false, path);
    }

    public static void ret_to_ex (int errc) throws FileError {
        if (errc < 0) {
            throw new FileError.FAILED ("Failed");
        }
    }

    private static void next(Xml.TextReader reader) throws MarkupError {
        int status = reader.read();
        if (status == -1) {
            error("failed to parse file");
        }

        Xml.ReaderType current_type = (Xml.ReaderType) reader.node_type ();
        if (current_type == Xml.ReaderType.WHITESPACE || current_type == Xml.ReaderType.SIGNIFICANT_WHITESPACE) {
            next(reader);
        }
    }

    private static int createFolder(string path, string dirName) {
        try {
            var newDir = GLib.File.new_for_path(path + dirName);
            newDir.make_directory();
            return 0;
        } catch (GLib.Error e) {
            return -1;
        }
    }

    public static int createMeta(int numQ, int numPages, string password, string path) {
        createFolder(path, "/.data");
        createFolder(path, "/.lock");
        Xml.TextWriter saver = new Xml.TextWriter.filename (path + "/.data/.exam.xml", false);
        if (saver == null) {
            print ("Error: Xml.TextWriter.filename () == null\n");
            return -1;
        }
        try {
            Save.ret_to_ex (saver.start_document ("1.0", "utf-8"));
            saver.set_indent (true);
            Save.ret_to_ex (saver.start_element("placeholder"));


            Save.ret_to_ex (saver.start_element("questions")); 
            Save.ret_to_ex (saver.write_attribute("number", numQ.to_string()));
            Save.ret_to_ex (saver.end_element());

            Save.ret_to_ex (saver.start_element("pages")); 
            Save.ret_to_ex (saver.write_attribute("number", numPages.to_string()));
            Save.ret_to_ex (saver.end_element());

            Save.ret_to_ex (saver.start_element("pass")); //need better format
            Save.ret_to_ex (saver.write_attribute("password", password));
            Save.ret_to_ex (saver.end_element());
            
            Save.ret_to_ex (saver.end_element());
            Save.ret_to_ex (saver.flush ());
        } catch (FileError e) {
            print ("Error: %s\n", e.message);
            return 1;
        }

        return 0;

    }

    public static int readMeta(ref int numQ, ref int numPages, out string password, string path) throws FileError, MarkupError {
        Xml.TextReader reader = new Xml.TextReader.filename(path + "/.data/.exam.xml");
        if (reader == null) {
            print ("Error: Xml.TextWriter.filename () == null\n");
            return -1;
        }

        while(reader.const_name() != "placeholder") {
            next(reader);
      }
        while (reader.const_name() != null) {
            switch (reader.const_name()) {
                case "questions":
                    numQ = int.parse(reader.get_attribute("number"));
                    next(reader);
                    break;

                case "pages":
                    numPages = int.parse(reader.get_attribute("number"));
                    next(reader);
                    break;

                case "pass":
                    password = reader.get_attribute("password");
                    next(reader);
                    break;

                default:
                    next(reader);
                    break;
            }
        }

        return 0;
    }

    public static void save(int qNum, QuestionSet currentQ, bool inUse, string path) {
        Xml.TextWriter saver = new Xml.TextWriter.filename (path + "/.data/Q" + qNum.to_string() + ".xml", false);
        if (saver == null) {
            print ("Error: Xml.TextWriter.filename () == null\n");
            return;
        }

        try {
            Save.ret_to_ex (saver.start_document ("1.0", "utf-8"));
            saver.set_indent (true);
            Save.ret_to_ex (saver.start_element("Q" + qNum.to_string()));

            Save.ret_to_ex (saver.start_element("exam"));
            Save.ret_to_ex (saver.write_attribute("inUse", inUse.to_string()));
            Save.ret_to_ex (saver.end_element());
            currentQ.save(saver);
            Save.ret_to_ex (saver.end_element());
            Save.ret_to_ex (saver.flush ());
        } catch (FileError e) {
            print ("Error: %s\n", e.message);
        }
    }

    //Set switchLock to false if you just want to load in the question data, and
    // not actually switch to grading that question.
    public static int fileImport(int qNum, int numTests, out QuestionSet question, string path, bool switchLock) throws FileError, MarkupError {
        
        string filePath = path + "/.data/Q" + qNum.to_string() + ".xml";
        Xml.TextReader reader = new Xml.TextReader.filename(filePath);
        if (reader == null) {
            stdout.printf("Error: Unable to read file data");
            return -1;
        }

        while(reader.const_name() != "exam") {
              next(reader);
        }

        int totalPoints = -1;
        double bounds[] = {-1, -1, -1, -1};	
        int pageNum = -1;
        int markID;
        double markWorth;
        string markDescription;
        bool markUnique;
        string testMarks;
        while (reader.const_name() != null) {
            switch (reader.const_name()) {
                case "totalPoints":
                    totalPoints = int.parse(reader.get_attribute("points"));
                    if (bounds[0] != -1 && bounds[1] != -1 && bounds[2] != -1 && bounds[3] != -1 && pageNum != -1) {
                        question = new QuestionSet(qNum, totalPoints, bounds, pageNum, numTests);
                    }
                    next(reader);
                    break;

                case "bounds":
                    bounds[0] = double.parse(reader.get_attribute("bound1"));
                    bounds[1] = double.parse(reader.get_attribute("bound2"));
                    bounds[2] = double.parse(reader.get_attribute("bound3"));
                    bounds[3] = double.parse(reader.get_attribute("bound4"));
                    if (totalPoints != -1 && pageNum != -1) {
                        question = new QuestionSet(qNum, totalPoints, bounds, pageNum, numTests);
                    }
                    next(reader);
                    break;
                
                case "pageNum":
                    pageNum = int.parse(reader.get_attribute("page"));
                    if (bounds[0] != -1 && bounds[1] != -1 && bounds[2] != -1 && bounds[3] != -1 && totalPoints != -1) {
                        question = new QuestionSet(qNum, totalPoints, bounds, pageNum, numTests);
                    }
                    next(reader);
                    break;

                case "marks":
                    next(reader);
                    while (reader.const_name() != "marks") {
                        if (reader.const_name().contains("mark")) {
                            markID = int.parse(reader.get_attribute("id"));
                            markWorth = double.parse(reader.get_attribute("worth"));
                            markDescription = reader.get_attribute("description");
                            if(markDescription == null) {
                                markDescription = "";
                            }
                            if (reader.get_attribute("unique") == "true") {
                                markUnique = true;
                            } else {
                                markUnique = false;
                            }
                            question.addMark(new Mark (markID, markWorth, markDescription, markUnique));
                            
                        }
                        next(reader);
                    }
                    next(reader);
                    break;

                case "testInfo":
                    next(reader);
        
                    int i = 0;
                    while (reader.const_name() != "testInfo") {
                        testMarks = reader.get_attribute("marks");
                                
                        if (testMarks.length != 0) {
                            string[] marks = testMarks.split(" ");
                            Question currentQuestion = question.questionSelect(i);
                            foreach (string mark in marks) {
                                currentQuestion.addMark(question.getMarkbyID(int.parse(mark)));
                            }
                        }
                        i++;
                        next(reader);
                    }
                    next(reader);
                    

                    break;

                default:
                    next(reader);
                    break;

            }
        }

        if (!switchLock) {
            return 0;
        }

        var result = Lock.attemptSwitch(path, qNum);
        if (result == -1) {
            bool userOverride = System.yesNoPrompt("Someone else is currently grading this question. Grading this question too could cause data loss. Would you like to proceed?", "Access Warning");
            if (userOverride) {
                Lock.lockAgain(path, qNum);
            } else {
                return -1;
            }
            
        } else if (result < 0) {
            return -1;
        }

        return 0;
    }
}

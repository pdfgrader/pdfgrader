public class Save
{
    // called when we are done setting up a new test, saves all of the initial
    // questions to the files in the .data directory
    public static void save_all(string path, Gee.ArrayList<QuestionSet> questions) {
        foreach (QuestionSet q in questions) {
            Save.save(q.get_question_num(), q, false, path);
        }
    }
    
    public static void save_specific(string path, QuestionSet question){
        Save.save(question.get_question_num(), question, false, path);
    }

    public static void ret_to_ex(int errc) throws FileError {
        if (errc < 0) {
            throw new FileError.FAILED ("Failed");
        }
    }

    private static void next(Xml.TextReader reader) throws MarkupError {
        int status = reader.read();
        if (status == -1) {
            error("failed to parse file");
        }

        Xml.ReaderType current_type = (Xml.ReaderType) reader.node_type();
        if (current_type == Xml.ReaderType.WHITESPACE || current_type == Xml.ReaderType.SIGNIFICANT_WHITESPACE) {
            next(reader);
        }
    }

    private static int create_folder(string path, string dir_name) {
        try {
            var new_dir = GLib.File.new_for_path(path + dir_name);
            new_dir.make_directory();
            return 0;
        } catch (GLib.Error e) {
            return -1;
        }
    }

    public static int create_meta(int num_questions, int num_pages, string password, string path) {
        create_folder(path, "/.data");
        create_folder(path, "/.lock");
        Xml.TextWriter saver = new Xml.TextWriter.filename(path + "/.data/.exam.xml", false);
        if (saver == null) {
            print ("Error: Xml.TextWriter.filename () == null\n");
            return -1;
        }
        try {
            Save.ret_to_ex(saver.start_document ("1.0", "utf-8"));
            saver.set_indent(true);
            Save.ret_to_ex(saver.start_element("placeholder"));

            Save.ret_to_ex(saver.start_element("questions")); 
            Save.ret_to_ex(saver.write_attribute("number", num_questions.to_string()));
            Save.ret_to_ex(saver.end_element());

            Save.ret_to_ex(saver.start_element("pages")); 
            Save.ret_to_ex(saver.write_attribute("number", num_pages.to_string()));
            Save.ret_to_ex(saver.end_element());

            Save.ret_to_ex(saver.start_element("pass")); //need better format
            Save.ret_to_ex(saver.write_attribute("password", password));
            Save.ret_to_ex(saver.end_element());
            
            Save.ret_to_ex(saver.end_element());
            Save.ret_to_ex(saver.flush());
        } catch (FileError e) {
            print("Error: %s\n", e.message);
            return 1;
        }

        return 0;
    }

    public static int read_meta(ref int num_questions, ref int num_pages, out string password, string path) throws FileError, MarkupError {
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
                    num_questions = int.parse(reader.get_attribute("number"));
                    next(reader);
                    break;

                case "pages":
                    num_pages = int.parse(reader.get_attribute("number"));
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

    public static void save(int question_num, QuestionSet curr_question, bool in_use, string path) {
        Xml.TextWriter saver = new Xml.TextWriter.filename(path + "/.data/Q" + question_num.to_string() + ".xml", false);
        if (saver == null) {
            print("Error: Xml.TextWriter.filename () == null\n");
            return;
        }

        try {
            Save.ret_to_ex(saver.start_document("1.0", "utf-8"));
            saver.set_indent (true);
            Save.ret_to_ex(saver.start_element("Q" + question_num.to_string()));

            Save.ret_to_ex(saver.start_element("exam"));
            Save.ret_to_ex(saver.write_attribute("in_use", in_use.to_string()));
            Save.ret_to_ex(saver.end_element());
            curr_question.save(saver);
            Save.ret_to_ex(saver.end_element());
            Save.ret_to_ex(saver.flush());
        } catch (FileError e) {
            print("Error: %s\n", e.message);
        }
    }

    // Set switch_lock to false if you just want to load in the question data, and
    // not actually switch to grading that question.
    public static int fileImport(int question_num, int num_tests, out QuestionSet question, string path, bool switch_lock) throws FileError, MarkupError {
        string file_path = path + "/.data/Q" + question_num.to_string() + ".xml";
        Xml.TextReader reader = new Xml.TextReader.filename(file_path);
        if (reader == null) {
            stdout.printf("Error: Unable to read file data");
            return -1;
        }

        while(reader.const_name() != "exam") {
              next(reader);
        }

        int total_points = -1;
        double bounds[] = {-1, -1, -1, -1};	
        int page_num = -1;
        int mark_id;
        double mark_worth;
        string mark_description;
        bool mark_unique;
        string test_marks;
        while (reader.const_name() != null) {
            switch (reader.const_name()) {
                case "total_points":
                    total_points = int.parse(reader.get_attribute("points"));
                    if (bounds[0] != -1 && bounds[1] != -1 && bounds[2] != -1 && bounds[3] != -1 && page_num != -1) {
                        question = new QuestionSet(question_num, total_points, bounds, page_num, num_tests);
                    }
                    next(reader);
                    break;

                case "bounds":
                    bounds[0] = double.parse(reader.get_attribute("bound1"));
                    bounds[1] = double.parse(reader.get_attribute("bound2"));
                    bounds[2] = double.parse(reader.get_attribute("bound3"));
                    bounds[3] = double.parse(reader.get_attribute("bound4"));
                    if (total_points != -1 && page_num != -1) {
                        question = new QuestionSet(question_num, total_points, bounds, page_num, num_tests);
                    }
                    next(reader);
                    break;
                
                case "page_num":
                    page_num = int.parse(reader.get_attribute("page"));
                    if (bounds[0] != -1 && bounds[1] != -1 && bounds[2] != -1 && bounds[3] != -1 && total_points != -1) {
                        question = new QuestionSet(question_num, total_points, bounds, page_num, num_tests);
                    }
                    next(reader);
                    break;

                case "marks":
                    next(reader);
                    while (reader.const_name() != "marks") {
                        if (reader.const_name().contains("mark")) {
                            mark_id = int.parse(reader.get_attribute("id"));
                            mark_worth = double.parse(reader.get_attribute("worth"));
                            mark_description = reader.get_attribute("description");
                            if(mark_description == null) {
                                mark_description = "";
                            }
                            if (reader.get_attribute("unique") == "true") {
                                mark_unique = true;
                            } else {
                                mark_unique = false;
                            }
                            question.add_mark(new Mark(mark_id, mark_worth, mark_description, mark_unique));
                            
                        }
                        next(reader);
                    }
                    next(reader);
                    break;

                case "test_info":
                    next(reader);
        
                    int i = 0;
                    while (reader.const_name() != "test_info") {
                        test_marks = reader.get_attribute("marks");
                                
                        if (test_marks.length != 0) {
                            string[] marks = test_marks.split(" ");
                            Question curr_question = question.get_question(i);
                            foreach (string mark in marks) {
                                curr_question.add_mark(question.get_mark_by_id(int.parse(mark)));
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

        if (!switch_lock) {
            return 0;
        }

        var result = Lock.attempt_switch(path, question_num);
        if (result == -1) {
            bool user_override = System.yesNoPrompt("Someone else is currently grading this question. Grading this question too could cause data loss. Would you like to proceed?", "Access Warning");
            if (user_override) {
                Lock.lock_again(path, question_num);
            } else {
                return -1;
            }    
        } else if (result < 0) {
            return -1;
        }

        return 0;
    }
}

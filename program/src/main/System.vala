//static class that has main method and some others
public class System
{
    public static unowned Gtk.Window? mainWindow;
    public static Gtk.EventBox examEventBox;
    public static ExamImage examImage;
    public static Gee.ArrayList<QuestionSet> examQuestionSet; //the master list of all QuestionSets for the current exam
    public static int examPagesPerTest = 0;
    public static int examQuestionsPerTest = 0;
    public static string password = "garbage";
    public static string PDFPath;
    
    public static Gtk.Menu menuQuestion; //the question menu that we need to add to once we know how many questions there are.
    public static int currentQuestion = -1; //which question is the grader currently viewing/grading?
    public static int currentTest = 0; //which exam number is the grader currently working on?
    public static bool isGrading = false; //have we finished setup/are we currently focusing on a particular question?

    public static Gtk.Grid marksGrid; //the grid that shows all of the current questions marks
    public static bool isBindingNewMarkHotkey = false;
    public static MarkViewHotkeyButton markHotkeyButton;
    
    private System(){}

    
    public static int main(string[] args)
    {
        Gtk.init(ref args);

        initUI();

        initCallbacks();

        setUMask();

        Gtk.main();
        
        shutdown();

        return 0;
    }

    //sets up gtk stuff
    private static void initUI()
    {
        var window = new Gtk.Window();
        mainWindow = window;
        window.set_title("PDF Grader");
        try
        {
            window.set_icon_from_file("res/icon.png");
        }
        catch (GLib.Error e)
        {
            print("Warning: Could not load 'res/icon.png'");
            print(e.message);
            print("\n");
        }
        
        //setup the menu bar
        var menuBar = new Gtk.MenuBar();
        var menuPane = new Gtk.Paned(Gtk.Orientation.VERTICAL);
        {
            menuPane.pack1(menuBar, false, false); //put the menu at the top of the application. shrink to smallest possible size
            window.add(menuPane);
            
            //the File submenu
            var menuFile = new Gtk.Menu();
            var menuItemFile1 = new Gtk.MenuItem.with_label("Resume Project");
            var menuItemFile2 = new Gtk.MenuItem.with_label("New Project");
            var menuItemFile3 = new Gtk.MenuItem.with_label("Save Project");
            var menuItemFile4 = new Gtk.MenuItem.with_label("Export Reports");
            menuFile.append(menuItemFile1);
            menuFile.append(menuItemFile2);
            menuFile.append(menuItemFile3);
            menuFile.append(menuItemFile4);
            menuItemFile1.activate.connect(clickedFileResume);
            menuItemFile2.activate.connect(clickedFileImport);
            menuItemFile3.activate.connect(clickedFileSave);
            menuItemFile4.activate.connect(clickedFileExport);

            var menuItemFile = new Gtk.MenuItem.with_label("File");
            menuItemFile.set_submenu(menuFile);
            menuBar.append(menuItemFile);
            
            
            //the Tools submenu
            var menuTools = new Gtk.Menu();
            var menuItemTools1 = new Gtk.MenuItem.with_label("Add a new Mark");
            menuTools.append(menuItemTools1);
            menuItemTools1.activate.connect(clickCreateNewMark);
            
            var menuItemTools = new Gtk.MenuItem.with_label("Tools");
            menuItemTools.set_submenu(menuTools);
            menuBar.append(menuItemTools);
            
            
            //the Question select submenu
            // (is a stub for now, will be generated later once we know how many questions there are
            menuQuestion = new Gtk.Menu();
            
            var menuItemQuestion = new Gtk.MenuItem.with_label("Question");
            menuItemQuestion.set_submenu(menuQuestion);
            menuBar.append(menuItemQuestion);
        }
        
        
        //setup window area UI
        {
            //setup the exam view on left, and tools on right
            var hpaned = new Gtk.Paned(Gtk.Orientation.HORIZONTAL);
            hpaned.set_size_request(800, 400); //minimum size of entire window content
            menuPane.pack2(hpaned, true, false);
            
            //left side: exam view
            examEventBox = new Gtk.EventBox(); //event box to wrap the image around
            examImage = new ExamImage(); //the image that goes in the exam frame
            examEventBox.add(examImage.getImage()); //wrap the Gtk.Image inside of an EventBox, in order to get callbacks
            hpaned.pack1(examEventBox, true, false);
            
            //right side: marks + cgi + hotkeys
            marksGrid = new Gtk.Grid();
            marksGrid.set_row_spacing(5);
            marksGrid.set_column_spacing(5);
            marksGrid.set_size_request(100, -1); //100 = minimum width
            hpaned.pack2(marksGrid, false, false); //put the vpaned on the right side of the hpaned
        }
        
        window.show_all();
    }

    private static void initCallbacks()
    {
        mainWindow.key_press_event.connect(examImage.onKeyPressed);
        mainWindow.key_release_event.connect(examImage.onKeyReleased);
        examEventBox.button_press_event.connect(examImage.onMouseClick);
        examEventBox.motion_notify_event.connect(examImage.onMouseMove);
        examEventBox.add_events(Gdk.EventMask.SCROLL_MASK); //needed for scroll events to happen
        examEventBox.scroll_event.connect(examImage.onScroll);
        mainWindow.destroy.connect(Gtk.main_quit); //when the main window is closed, Gtk returns from its main() call
        GLib.Timeout.add_seconds(30, timerCallback); //every 30 seconds, auto save
    }

    //sets the umask to 0000, so that files and directories created will be able to be read+written to by 
    // anyone, allowing multiple graders to work on the project.
    private static void setUMask()
    {
        Posix.umask(0);
    }
    
    //when the program closes, we need to save off the current question that we are editing,
    // so that it won't be 'inUse' in the file.
    private static void shutdown()
    {
        if (!examImage.isPdfLoaded() || 
            currentQuestion < 1 ||
            !isGrading)
        {
            return;
        }
        
        Save.save_specific(PDFPath, examQuestionSet.get(0));
        Lock.close_file(PDFPath, currentQuestion);
    }
    
    private static bool timerCallback()
    {   
        if (currentQuestion > 0) {
            Save.save_specific(PDFPath, examQuestionSet.get(0));
        }
        return true;
    }
    
    //after we know the total of number of question for the entire test, call
    // this function to generate all of the submenu items for the Question menu,
    // and also setup the callbacks
    public static void createQuestionMenuItems()
    {
        if (!examImage.isPdfLoaded())
        {
            return;
        }
        
        for (int i = 1; i <= examQuestionsPerTest; i++)
        {
            var menuItemQuestion = new Gtk.MenuItem.with_label("Question "+(i).to_string());
            menuQuestion.append(menuItemQuestion);
            menuItemQuestion.activate.connect(clickedQuestionMenuItem);
        }
        mainWindow.show_all();
    }
    
    //when the user selects a new question, call this to refresh which
    // marks are being displayed in the mark view.
    public static void refreshMarksView()
    {
        if (!examImage.isPdfLoaded())
        {
            return;
        }
        
        //clear all the action bars from before
        marksGrid.foreach((element) => marksGrid.remove(element));
        
        var questionSet = examQuestionSet.get(0); //since the first entry is the name space, we need to add 1
        var currQuestion = questionSet.get_questions().get(currentTest); //the specific student's test question
        var pool = questionSet.get_rubric();
        
        int i = 0;
        foreach (Mark mark in pool.values)
        {
            var actionbar = new Gtk.ActionBar();
            actionbar.set_hexpand(true);
            
            var label = new Gtk.Label(mark.get_description());
            label.set_line_wrap(true);
            label.set_size_request(96, -1); //make some room for mark descriptions
            actionbar.pack_start(label);
            
            var checkbox = new MarkViewCheckbox(mark);
            checkbox.set_size_request(24, -1);
            actionbar.pack_end(checkbox);
            if (currQuestion.get_marks().contains(mark.get_id()))
            {
                checkbox.set_active(true);
            }
            else
            {
                checkbox.set_active(false);
            }
            checkbox.toggled.connect(clickedMarkButton);
            
            var button = new MarkViewHotkeyButton(mark);
            button.set_size_request(24, -1);
            actionbar.pack_end(button);
            if (mark.get_hot_key() != 0)
            {
                button.set_label(keyvalToString(mark.get_hot_key()));
            }
            button.clicked.connect(clickedMarkHotkey);
            
            var entryWorth = new MarkViewWorthEntry(mark);
            entryWorth.set_size_request(24, -1);
            entryWorth.set_visibility(true);
            entryWorth.set_text(mark.get_worth().to_string());
            //entryWorth.set_max_length(4); Gtk.Entry's seem to have some large hard coded minimum length that this does not override.
            actionbar.pack_end(entryWorth);

            entryWorth.changed.connect(editedMarkWorth);
            
            marksGrid.attach(actionbar, 0, i);
            
            i++;
        }
        
        mainWindow.show_all();
    }

    //this function updates all of the checkboxes in the mark view
    // with their correct values. call this after hitting a hotkey.
    public static void refreshMarkViewCheckboxes()
    {
        var questionSet = examQuestionSet.get(0); //get the question set that is currently being graded
        var currQuestion = questionSet.get_questions().get(currentTest); //the specific student's question
        var pool = questionSet.get_rubric();
        
        int i = 0;
        foreach (Mark mark in pool.values)
        {
            Gtk.ActionBar actionbar = (Gtk.ActionBar)marksGrid.get_child_at(0, i);

            var widgets = actionbar.get_children();

            MarkViewCheckbox checkbox = (MarkViewCheckbox)widgets.nth_data(3);

            if (currQuestion.get_marks().contains(mark.get_id()))
            {
                checkbox.set_active(true);
            }
            else
            {
                checkbox.set_active(false);
            }

            i++;
        }
    }
    
    //when the user clicks the checkmark button, we need to save that
    // info into the QuestionSet.questions field
    public static void clickedMarkButton(Gtk.ToggleButton source)
    {
        var btn = (MarkViewCheckbox)source;
        var questionSet = examQuestionSet.get(0); //since the first entry is the name space, we need to add 1
        var currQuestion = questionSet.get_questions().get(currentTest); //the specific student's test question
        var questionActiveMarks = currQuestion.get_marks();
        
        var mark = btn.mark;
        
        if (btn.get_active()) //the checkbox is now checked, so add the mark to the question's mark list
        {
            if (!questionActiveMarks.contains(mark.get_id()))
            {
                questionActiveMarks.add(mark.get_id());
            }
        }
        else //the checkbox is now unchecked, remove the mark from the question's mark list
        {
            if (questionActiveMarks.contains(mark.get_id()))
            {
                questionActiveMarks.remove(mark.get_id());
            }
        }
    }
    
    //when the user clicks the hotkey button for a mark, it means
    // that they want to reassign a hotley value
    public static void clickedMarkHotkey(Gtk.Button source)
    {
        isBindingNewMarkHotkey = true;
        markHotkeyButton = (MarkViewHotkeyButton)source;
        source.set_label("...");
    }
    
    //this is called whenever the user has changed the text value of any marks'
    // worth in the UI. So, this function will parse the new text and update
    // the actual double value in the mark object.
    public static void editedMarkWorth(Gtk.Editable source)
    {
        MarkViewWorthEntry worthEntry = (MarkViewWorthEntry)source;
        string newWorthText = worthEntry.get_text();

        if (double.try_parse(newWorthText))
        {
            worthEntry.mark.set_worth(double.parse(newWorthText));
        }
    }
    
    private static void clickedFileSave()
    {
        if (currentQuestion > 0) {
            Save.save_specific(PDFPath, examQuestionSet.get(0));
        }
    }

    //function that gets called when the menu file import gets clicked
    private static void clickedFileImport()
    {
        if (isGrading)
        {
            popupMessage("Restart", "Restart program to begin a new project.");
            return;
        }

        var filename = System.getFileViaChooser(mainWindow);
        if (filename != "")
        {
            GLib.File PDFDir = GLib.File.new_for_path(filename).get_parent();
            PDFPath = PDFDir.get_path();
            password = "garbage";
            
            examImage.loadPDF(filename);
            examImage.renderNewPage();
            examImage.refreshCurrentPage();
            
            examPagesPerTest = -1;
            while (examPagesPerTest < 0)
            {
                examPagesPerTest = (int)getNumberFromUserPrompt("How many pages per test?", "Enter # pages per test");
            }

            examQuestionsPerTest = -1;
            while (examQuestionsPerTest < 0)
            {
                examQuestionsPerTest = (int)getNumberFromUserPrompt("How many questions per test?", "Enter # questions per test");
            }
            
            currentQuestion = 0;
            createQuestionMenuItems();
            
            examQuestionSet = new Gee.ArrayList<QuestionSet>();
            examImage.nameSelect();
        }
    }
    
    //function that gets called when the menu file resume gets clicked
    private static void clickedFileResume()
    {
        if (examImage.isPdfLoaded()) //dont resume if there is already a test loaded.
        {
            popupMessage("Restart", "Restart program to resume a different project.");
            return;
        }
        
        var filename = System.getFileViaChooser(mainWindow);
        if (filename != "")
        {   
            GLib.File PDFDir = GLib.File.new_for_path(filename).get_parent();
            PDFPath = PDFDir.get_path();
            //get a password from user
            password = "garbage";
            if (PDFDir.get_child(".data").query_exists()) {
                examImage.loadPDF(filename);
                examImage.renderNewPage();
                examImage.refreshCurrentPage();
                
                try {
                    Save.read_meta(ref examQuestionsPerTest, ref examPagesPerTest, out password, PDFPath);
                    
                    int qNum = 1;
                    QuestionSet startingQuestion;
                    int result = Save.fileImport(qNum, examImage.getNumPDFPages()/examPagesPerTest, out startingQuestion, PDFPath, true);
                    while (result != 0) { //if question 1 is being used, go on to question 2, and so on...
                        qNum++;
                        result = Save.fileImport(qNum, examImage.getNumPDFPages()/examPagesPerTest, out startingQuestion, PDFPath, true);
                    } 
                    
                    currentQuestion = qNum;
                    examQuestionSet = new Gee.ArrayList<QuestionSet>();
                    examQuestionSet.add(startingQuestion);
                    
                    createQuestionMenuItems();
                    refreshMarksView();
                    examImage.renderPageWithQuestionFocus();
                } catch (Error e) {
                    stdout.printf("unable to intake data\n");
                    return;
                }
                isGrading = true;
            }
            else
            {
                stdout.printf("No .data directory found to resume from.\n");
            }
        }
    }
    
    private static void clickedFileExport()
    {
        if (!examImage.isPdfLoaded() ||
            !isGrading)
        {
            return;
        }
        
        string filePath = getDirectoryPathViaChooser(mainWindow);

        if (filePath != null)
        {
            //save current question out to the file so we don't skip any local changes in the export
            Save.save_specific(PDFPath, examQuestionSet.get(0));

            Export.exportAsLaTeX(filePath);
        }
    }

    //when the user clicks the "new mark" button in the menu bar, this function gets called
    // to create a prompt for the user to enter the new mark, and also assigns it to the current 
    // question being graded.
    private static void clickCreateNewMark()
    {
        if (!examImage.isPdfLoaded())
        {
            return;
        }
        
        bool retry = true;
        
        while (retry)
        {
            var dialogWindow = new Gtk.MessageDialog(
                    mainWindow,
                    Gtk.DialogFlags.MODAL,
                    Gtk.MessageType.QUESTION,
                    Gtk.ButtonsType.OK_CANCEL,
                    "Enter the Mark values for the new Mark");
                                   
            dialogWindow.set_title("Create a new Mark");
            
            var dialogBox = dialogWindow.get_content_area();
            
            var userEntry1 = new Gtk.Entry();
            userEntry1.set_visibility(true);
            userEntry1.set_size_request(250, 0);
            userEntry1.set_text("(description)");
            dialogBox.pack_start(userEntry1, false, false, 0);
            
            var userEntry2 = new Gtk.Entry();
            userEntry2.set_visibility(true);
            userEntry2.set_size_request(250, 0);
            userEntry2.set_text("(worth)");
            dialogBox.pack_start(userEntry2, false, false, 0);
            
            dialogWindow.show_all();
            var response = dialogWindow.run();
            var userInput1 = userEntry1.get_text();
            var userInput2 = userEntry2.get_text();
            
            dialogWindow.close();
            dialogWindow.destroy();
            
            if (response != Gtk.ResponseType.OK)
            {
                retry = false;
            }
            else if ((userInput1 != "") && (userInput2 != ""))
            {
                if (double.try_parse(userInput2))
                {
                    retry = false;
                    
                    var questionSet = examQuestionSet.get(0); //since the first entry is the name space, we need to add 1
                    var pool = questionSet.get_rubric();
                    int maxID = -1;
                    foreach (Mark mark in pool.values)
                    {
                        maxID = int.max(maxID, mark.get_id());
                    }
                    maxID+=1; //make the next mark be one greater than the previous max of all the marks in the pool
                    
                    //create new mark
                    double worth = double.parse(userInput2);
                    string description = userInput1;
                    Mark newMark = new Mark(maxID, worth, description, true); //todo: not sure what unique parameter is
                    //add new mark to current question set
                    pool[maxID] = newMark;
                    
                    //now that the current question set has a new mark, we need to update the
                    // UI to show the new mark.
                    refreshMarksView();
                }
                else
                {
                    print("Error: Cannot parse user input for worth.");
                }
            }
            //resets to pre assigning point
            isGrading = true;
        }
    }

    //returns -1 if user text can't be parsed
    public static double getNumberFromUserPrompt(string prompt, string title)
    {
        var dialogWindow = new Gtk.MessageDialog(
                mainWindow,
                Gtk.DialogFlags.MODAL,
                Gtk.MessageType.QUESTION,
                Gtk.ButtonsType.OK_CANCEL,
                prompt);

        dialogWindow.set_title(title);

        var dialogBox = dialogWindow.get_content_area();
        var userEntry = new Gtk.Entry();
        userEntry.set_visibility(true);
        userEntry.set_size_request(250, 0);
        dialogBox.pack_end(userEntry, false, false, 0);

        dialogWindow.show_all();
        var response = dialogWindow.run();
        var userInput = userEntry.get_text();

        dialogWindow.close();
        dialogWindow.destroy();

        if ((response == Gtk.ResponseType.OK) && (userInput != ""))
        {
            if (double.try_parse(userInput))
            {
                return double.parse(userInput);
            }
            else
            {
                print("Error: Cannot parse user input for number of exams.");
            }
        }

        return -1;
    }

    //displays a popup message and blocks until user closes it
    public static void popupMessage(string title, string prompt)
    {
        var dialogWindow = new Gtk.MessageDialog(
                mainWindow,
                Gtk.DialogFlags.MODAL,
                Gtk.MessageType.INFO,
                Gtk.ButtonsType.OK,
                prompt);

        dialogWindow.set_title(title);

        dialogWindow.show_all();
        dialogWindow.run();

        dialogWindow.close();
        dialogWindow.destroy();
    }

    public static bool yesNoPrompt(string prompt, string title)
    {
        var dialogWindow = new Gtk.MessageDialog(
                mainWindow,
                Gtk.DialogFlags.MODAL,
                Gtk.MessageType.QUESTION,
                Gtk.ButtonsType.YES_NO,
                prompt);

        dialogWindow.set_title(title);

        dialogWindow.show_all();
        var response = dialogWindow.run();

        dialogWindow.close();
        dialogWindow.destroy();

        if (response == Gtk.ResponseType.YES)
        {
            return true;
        } else {
            return false;
        }
    }

    //pops up a file chooser and blocks until the user opens a file or cancels
    public static string getFileViaChooser(Gtk.Window* window)
    {
        var dialog = new Gtk.FileChooserDialog("Open File",                //title
                                               window,                     //parent
                                               Gtk.FileChooserAction.OPEN, //action
                                               "Open",                     //first button text
                                               Gtk.ResponseType.ACCEPT,    //first button response type
                                               "Cancel",                   //second button text
                                               Gtk.ResponseType.CANCEL,    //second button response type
                                               null);

        int response = dialog.run(); //blocks until finished

        string filename = "";

        if (response == Gtk.ResponseType.ACCEPT)
        {
            filename = dialog.get_filename();
        }

        //without this, window will stay open
        dialog.close();
        dialog.destroy();

        return filename;
    }
    
    //pops up a file chooser and blocks until the user opens a file or cancels.
    // returns the full filepath to the new file, or null if the user cancels
    public static string getDirectoryPathViaChooser(Gtk.Window* window)
    {
        var dialog = new Gtk.FileChooserDialog("Select Drectory to Export .tex Files", //title
                                               window,                                 //parent
                                               Gtk.FileChooserAction.SELECT_FOLDER,    //action
                                               "Select Directory",                     //first button text
                                               Gtk.ResponseType.ACCEPT,                //first button response type
                                               "Cancel",                               //second button text
                                               Gtk.ResponseType.CANCEL,                //second button response type
                                               null);

        int response = dialog.run(); //blocks until finished

        string path = null;

        if (response == Gtk.ResponseType.ACCEPT)
        {
            path = dialog.get_filename();
        }

        //without this, window will stay open
        dialog.close();
        dialog.destroy();

        return path;
    }
    
    public static FileOutputStream getNewFileViaChooser(Gtk.Window* window)
    {
        var dialog = new Gtk.FileChooserDialog("Save File",                //title
                                               window,                     //parent
                                               Gtk.FileChooserAction.SAVE, //action
                                               "Save",                     //first button text
                                               Gtk.ResponseType.ACCEPT,    //first button response type
                                               "Cancel",                   //second button text
                                               Gtk.ResponseType.CANCEL,    //second button response type
                                               null);

        int response = dialog.run(); //blocks until finished

        string filename = "";

        if (response == Gtk.ResponseType.ACCEPT)
        {
            filename = dialog.get_filename();
        }

        var file = GLib.File.new_for_path(filename);

        FileOutputStream filestream = null;
        try
        {
            filestream = file.create(FileCreateFlags.PRIVATE);
        }
        catch (GLib.Error e)
        {
            stdout.printf("getNewFileViaChooser GLib.Error: %s\n", e.message);
        }

        //without this, window will stay open
        dialog.close();
        dialog.destroy();

        return filestream;
    }
    
    //function that gets called when the user clicks on a question menu item
    public static void clickedQuestionMenuItem(Gtk.MenuItem source)
    {
        if (!examImage.isPdfLoaded())
        {
            return;
        }
        
        isGrading = true;
        
        string label = source.get_label();
        string numString = label.substring(9); //parse the question number from the menu item's label
        int qNum = int.parse(numString);
        
        if (currentQuestion == qNum) //clicked the same question as we are already on
        {
            return;
        }

        // load the new question from the file.
        QuestionSet nextQuestion;
        try
        {
            int returnVal = Save.fileImport(qNum, examImage.getNumPDFPages()/examPagesPerTest, out nextQuestion, PDFPath, true);
            if (returnVal < 0)
            {
                stdout.printf("unable to load question");
                return;
            }
        }
        catch (GLib.FileError e)
        {
            stdout.printf("clickedQuestionMenuItem GLib.FileError: %s\n", e.message);
        }
        catch (GLib.MarkupError e)
        {
            stdout.printf("clickedQuestionMenuItem GLib.MarkupError: %s\n", e.message);
        }
        
        if (currentQuestion != -1) //write the old question out to the file, as we are no longer using it
        {
            Save.save_specific(PDFPath, examQuestionSet.get(0));
        }
        
        //make the new question we are editing be the only question in the question set
        examQuestionSet.clear();
        examQuestionSet.add(nextQuestion);
        
        currentQuestion = qNum;
        
        refreshMarksView();
        
        examImage.renderPageWithQuestionFocus();
    }

    //searches the current questionset mark map to see if any of the marks
    //have the same keybind as what was pressed returning the position in the
    //map if there is a match
    public static int checkIfBound(uint binding)
    {
        Gee.HashMap<int, Mark> currPool = examQuestionSet.get(0).get_rubric(); //since the first entry is the name space, we need to add 1
        for (int i = 0; i < currPool.size; i++)
        {
            if(binding == currPool.get(i).get_hot_key())
            {
                return i;
            }
        }
        return -1;
    }

    //returns whether we are ok with a certain key being a hotkey.
    public static bool keyvalCanBeHotkey(uint keyval)
    {
        return ((keyval > 47 && keyval < 58)  || //numbers
                (keyval > 64 && keyval < 91)  || //capital
                (keyval > 96 && keyval < 123) || //lowercase
                (keyval >= Gdk.Key.KP_0 && keyval <= Gdk.Key.KP_9)); //numpad
    }

    //converts a keyval into a displayable string
    public static string keyvalToString(uint keyval)
    {
        if (keyvalCanBeHotkey(keyval))
        {
            if (keyval >= Gdk.Key.KP_0 && keyval <= Gdk.Key.KP_9)
            {
                int num = (int)(keyval - Gdk.Key.KP_0);
                //return "Num " + num.to_string(); //maybe add Num before to difference it from normal numbers?
                return num.to_string();
            }
            else
            {
                return  ((char)keyval).to_string();
            }
        }
        else
        {
            return "";
        }
    }
}

//a CheckButton that we will put in the marks view on the main UI.
// The button contains a reference to a Mark, so we can add/remove 
// it to the current Question+Test# in the QuestionSet
public class MarkViewCheckbox : Gtk.CheckButton
{
    public Mark mark;
    
    public MarkViewCheckbox(Mark myMark)
    {
        this.mark = myMark;
        this.set_label("");
    }
}

//a Button that we will put in the marks view on the main UI.
// The button contains a reference to a Mark, so we can add/remove 
// it to the current Question+Test# in the QuestionSet
public class MarkViewHotkeyButton : Gtk.Button
{
    public Mark mark;
    
    public MarkViewHotkeyButton(Mark myMark)
    {
        this.mark = myMark;
        this.set_label("");
    }
}

//a Entry that we will put in the marks view on the main UI.
// The button contains a reference to a Mark, so we can add/remove 
// it to the current Question+Test# in the QuestionSet
public class MarkViewWorthEntry : Gtk.Entry
{
    public Mark mark;
    
    public MarkViewWorthEntry(Mark myMark)
    {
        this.mark = myMark;
    }
}

//Class that handles all of the rendering of a pdf document page.
//First, you create an object, and load in a PDF file to it,
// then you can call renderNewPage and getImage.
public class ExamImage
{
    private bool pdfIsLoaded = false;
    private Poppler.Document document;
    private Gdk.Pixbuf pdfPagePixbufMaxScale; //the pixbuf for the pdf at max scale
    private Gdk.Pixbuf pdfPagePixbufCurrent; //the pixbuf that we are displaying for the current pdf page
    private Gtk.Image image;
    private int width  = 640; //arbitrary default size. this variable holds the width of pdfPagePixbufCurrent
    private int height = 800; //arbitrary default size. this variable holds the height of pdfPagePixbufCurrent
    private int defaultWidth  = 1; //the width that a pdf rendered at "%100" zoom will be. to be set in loadPDF function
    private int defaultHeight = 1; //the height that a pdf rendered at "%100" zoom will be. to be set in loadPDF function
    private double currentScale = 1.0;
    private const double MAXSCALE = 4.0;
    private double currentFocusX = 0.5; //the center x value that we are zoomed in on
    private double currentFocusY = 0.5; //the center y value that we are zoomed in on
    private int currentPage = 0;

    private bool isHoldingCtrl = false; //is the user currently holding the ctrl key?
    private bool isHoldingShft = false; //is the user currently holding the shft key?
    
    //variables used when setting up a new exam project
    // (calculating bounds of each question)
    private bool isSettingUpBounds = false;
    private bool isNameBoundsSet = false;
    private int currentQuestionSetup = 1;
    //variables that represent the current bounds that the user has 
    // drawn, to save later when the user does a keypress
    //the coordinates that the user started the click
    private double coordsClickStartX;
    private double coordsClickStartY;
    //the coordinates theat the user ended the click on
    private double coordsClickEndX;
    private double coordsClickEndY;

    public ExamImage()
    {
        this.initImage();
    }

    public int getNumPDFPages() {
        return document.get_n_pages();
    }
    
    public bool isPdfLoaded()
    {
        return this.pdfIsLoaded;
    }
    
    public void loadPDF(string filename)
    {
        if (!this.pdfIsLoaded)
        {
            try
            {
                this.document = new Poppler.Document.from_file(Filename.to_uri(filename), "");
                var page = this.document.get_page(0);
                //get size of first page, set that to our size
                double w;
                double h;
                page.get_size(out w, out h);
                this.width  = (int)w;
                this.height = (int)h;
                this.defaultWidth  = (int)w;
                this.defaultHeight = (int)h;
                this.pdfIsLoaded = true;
            }
            catch (Error e)
            {
                print("Error while opening the PDF document: ");
                print(e.message);
                print("\n");
            }
        }
        else
        {
            print("Warning: ExamImage trying to load a pdf when it has already been loaded.");
            print("\n");
        }
    }

    public void nameSelect()
    {
        this.isNameBoundsSet = true;
        var dialogWindowname = new Gtk.MessageDialog(
                System.mainWindow,
                Gtk.DialogFlags.MODAL,
                Gtk.MessageType.INFO,
                Gtk.ButtonsType.OK,
                "Draw the bounds for name space. Press Enter to confirm bounds.");
        dialogWindowname.set_title("Instructions");
        dialogWindowname.show_all();
        dialogWindowname.run();
        
        dialogWindowname.close();
        dialogWindowname.destroy();
    }
    
    public void startQuestionSetup()
    {
        this.isSettingUpBounds = true;
        this.currentQuestionSetup = 1;
        var dialogWindow = new Gtk.MessageDialog(
                System.mainWindow,
                Gtk.DialogFlags.MODAL,
                Gtk.MessageType.INFO,
                Gtk.ButtonsType.OK,
                "Draw the bounds for each question. Press Enter to confirm bounds and move to next question.");
                           
        dialogWindow.set_title("Instructions");
        
        dialogWindow.show_all();
        dialogWindow.run();
        
        dialogWindow.close();
        dialogWindow.destroy();
    }
    
    private void initImage()
    {
        var surface = new Cairo.ImageSurface(Cairo.Format.ARGB32, this.width, this.height);
        var context = new Cairo.Context(surface);
        
        //fill the image with white
        context.set_source_rgba(1.0, 1.0, 1.0, 1.0);
        context.rectangle(0, 0, this.width, this.height);
        context.fill();
        
        //fill the image with a rainbow gradient.
        // an example of what graphics can do.
        // for more examples: https://valadoc.org/cairo/Cairo.Context.html
        //for (int y = 0; y < this.height; y++)
        //{
        //    double r;
        //    double g;
        //    double b;
        //    Gtk.HSV.to_rgb(((double)y)/this.height, 140/256.0, 255/256.0, out r, out g, out b);
        //    
        //    context.set_source_rgba(r, g, b, 1.0);
        //    context.rectangle(0, y, this.width, 1);
        //    context.fill();
        //}
        
        this.image = new Gtk.Image.from_surface(surface);
    }
    
    public bool onKeyReleased(Gtk.Widget source, Gdk.EventKey key)
    {
        if (key.keyval == Gdk.Key.Control_L ||
            key.keyval == Gdk.Key.Control_R)
        {
            this.isHoldingCtrl = false;
        }
        
        if (key.keyval == Gdk.Key.Shift_L ||
            key.keyval == Gdk.Key.Shift_R)
        {
            this.isHoldingShft = false;
        }
        
        return false;
    }

    public bool onKeyPressed(Gtk.Widget source, Gdk.EventKey key)
    {
        if (key.keyval == Gdk.Key.Control_L ||
            key.keyval == Gdk.Key.Control_R)
        {
            this.isHoldingCtrl = true;
        }
        
        if (key.keyval == Gdk.Key.Shift_L ||
            key.keyval == Gdk.Key.Shift_R)
        {
            this.isHoldingShft = true;
        }
        
        if (!this.pdfIsLoaded)
        {
            return false;
        }
        
        if (System.isBindingNewMarkHotkey)
        {
            if (key.keyval == 0xff1b) //escape will clear the hotkey
            {
                System.markHotkeyButton.mark.set_hot_key(0);
                System.markHotkeyButton.set_label("");
                
                System.isBindingNewMarkHotkey = false;
                System.markHotkeyButton = null;
                return true;
            }
            else if (!System.keyvalCanBeHotkey(key.keyval))
            {
                print("Key value %x not allowed as a value for a hotkey.\n", key.keyval);
                return true; //key not allowed as a hotkey
            }
            else
            {         
                if (System.checkIfBound(key.keyval) == -1) //hotkey not already in use
                {
                    string keyDisplay = System.keyvalToString(key.keyval);

                    System.markHotkeyButton.set_label(keyDisplay); //set the label to new hotkey string
                    System.markHotkeyButton.mark.set_hot_key(key.keyval);
                    
                    System.isBindingNewMarkHotkey = false;
                    System.markHotkeyButton = null;
                    return true;
                }
                else //hotkey already being used
                {
                    return true;
                }
            }
        }

        if (System.isGrading) //we have finished setup, and are now actually grading the different student's tests
        {
            int index = System.checkIfBound(key.keyval);
            if (index != -1)
            {
                QuestionSet questionSet = System.examQuestionSet.get(0); //since the first entry is the name space, we need to add 1
                Question currQuestion = questionSet.get_questions().get(System.currentTest); 
                Gee.ArrayList<int> questionActiveMarks = currQuestion.get_marks();
                if (questionActiveMarks.contains(index))
                {
                    questionActiveMarks.remove(index);
                }
                else 
                {
                    questionActiveMarks.add(index);
                }
                System.refreshMarkViewCheckboxes();
            }
            else
            {
                switch (key.keyval)
                {
                    case 0xff52: //Up
                    case 0xff55: //Page Up
                    {
                        if (System.currentTest > 0)
                        {
                            System.currentTest--;
                            System.refreshMarkViewCheckboxes();
                            this.renderPageWithQuestionFocus();
                        }
                        return true;
                    }
                    
                    case 0xff54: //Down
                    case 0xff56: //Page Down
                    {
                        int totalTests = this.document.get_n_pages()/System.examPagesPerTest;
                        if (System.currentTest < totalTests-1)
                        {
                            System.currentTest++;
                            System.refreshMarkViewCheckboxes();
                            this.renderPageWithQuestionFocus();
                        }
                        return true;
                    }
                    
                    case Gdk.Key.Left:
                    {
                        //System.currentQuestion = int.max(System.currentQuestion-1, 0);
                        //this.renderPageWithQuestionFocus();
                        break;
                    }
                    
                    case Gdk.Key.Right:
                    {
                        //System.currentQuestion = int.min(System.currentQuestion+1, System.examQuestionsPerTest-1);
                        //this.renderPageWithQuestionFocus();
                        break;
                    }
                    
                    case Gdk.Key.plus:
                    case Gdk.Key.KP_Add:
                    {
                        if ((key.state & Gdk.ModifierType.CONTROL_MASK) != 0)
                        {
                            this.currentScale+=0.15;
                            this.currentScale = double.min(this.currentScale, ExamImage.MAXSCALE);
                            this.renderPageWithQuestionFocus();
                        }
                        break;
                    }
                    
                    case Gdk.Key.minus:
                    case Gdk.Key.KP_Subtract:
                    {
                        if ((key.state & Gdk.ModifierType.CONTROL_MASK) != 0)
                        {
                            this.currentScale-=0.15;
                            this.currentScale = double.max(this.currentScale, 0.3);
                            this.renderPageWithQuestionFocus();
                        }
                        break;
                    }
                    
                    default:
                        break;
                }
            }
        }
        else
        {
            switch (key.keyval)
            {
                case 0xff52: //Up
                case 0xff55: //Page Up
                {
                    if (this.currentPage > 0)
                    {
                        this.currentPage--;
                        this.renderNewPage();
                        this.refreshCurrentPage();
                    }
                    break;
                }
                
                case 0xff54: //Down
                case 0xff56: //Page Down
                {
                    if (this.currentPage < this.document.get_n_pages()-1)
                    {
                        this.currentPage++;
                        this.renderNewPage();
                        this.refreshCurrentPage();
                    }
                    break;
                }
                
                case Gdk.Key.plus:
                case Gdk.Key.KP_Add:
                {
                    if ((key.state & Gdk.ModifierType.CONTROL_MASK) != 0)
                    {
                        this.currentScale+=0.15;
                        this.currentScale = double.min(this.currentScale, ExamImage.MAXSCALE);
                        this.refreshCurrentPage();
                    }
                    break;
                }
                
                case Gdk.Key.minus:
                case Gdk.Key.KP_Subtract:
                {
                    if ((key.state & Gdk.ModifierType.CONTROL_MASK) != 0)
                    {
                        this.currentScale-=0.15;
                        this.currentScale = double.max(this.currentScale, 0.3);
                        this.refreshCurrentPage();
                    }
                    break;
                }
                
                case Gdk.Key.Return:
                {
                    if (this.isSettingUpBounds)
                    {
                        double[] bounds = new double[4];
                        bounds[0] = coordsClickStartX;
                        bounds[1] = coordsClickStartY;
                        bounds[2] = coordsClickEndX;
                        bounds[3] = coordsClickEndY;

                        int numTests = this.document.get_n_pages()/System.examPagesPerTest;
                        string pointsQuestion = "How much is this question worth?";
                        string pointsTitle = "Instructions";
                        double pointWorth = System.getNumberFromUserPrompt(pointsQuestion, pointsTitle);
                        QuestionSet newQ = new QuestionSet(this.currentQuestionSetup, pointWorth, bounds, this.currentPage, numTests);
                        newQ.add_default_marks();
                        System.examQuestionSet.add(newQ);
                        
                        if (this.currentQuestionSetup < System.examQuestionsPerTest)
                        {
                            var dialogWindow = new Gtk.MessageDialog(
                                    System.mainWindow,
                                    Gtk.DialogFlags.MODAL,
                                    Gtk.MessageType.INFO,
                                    Gtk.ButtonsType.OK,
                                    "Question "+(this.currentQuestionSetup).to_string()+" complete. Now do question "+(this.currentQuestionSetup+1).to_string());
                            
                            dialogWindow.set_title("Question "+(this.currentQuestionSetup).to_string()+" complete");
                            dialogWindow.show_all();
                            dialogWindow.run();
                            dialogWindow.close();
                            dialogWindow.destroy();
                            
                            this.currentQuestionSetup+=1;
                        }
                        else
                        {
                            var dialogWindow = new Gtk.MessageDialog(
                                    System.mainWindow,
                                    Gtk.DialogFlags.MODAL,
                                    Gtk.MessageType.INFO,
                                    Gtk.ButtonsType.OK,
                                    "All questions completed");
                            
                            dialogWindow.set_title("All done");
                            dialogWindow.show_all();
                            dialogWindow.run();
                            dialogWindow.close();
                            dialogWindow.destroy();
                            
                            this.isSettingUpBounds = false;
                            this.currentQuestionSetup = 0;

                            Save.create_meta(System.examQuestionsPerTest, System.examPagesPerTest, System.password, System.PDFPath);
                            Save.save_all(System.PDFPath, System.examQuestionSet);

                            
                            //remove all questions from memory except question 1
                            //int size = System.examQuestionSet.size;
                            //for (int i = size - 1; i >= 0; i--) {
                            //    stdout.printf("i: %d\n", i);
                            //    if (i != 1) {
                            //        System.examQuestionSet.remove_at(i);
                            //    }        
                            //}
                            //stdout.printf("%d\n" ,System.examQuestionSet.size);
                            
                            
                            System.isGrading = true;
                            System.currentQuestion = -1;
                            
                            //start grading question 1 by default
                            System.clickedQuestionMenuItem(new Gtk.MenuItem.with_label("Question 1"));
                        }
                    }

                    if (this.isNameBoundsSet)
                    {
                        double[] bounds = new double[4];
                        bounds[0] = coordsClickStartX;
                        bounds[1] = coordsClickStartY;
                        bounds[2] = coordsClickEndX;
                        bounds[3] = coordsClickEndY;

                        int numTests = this.document.get_n_pages()/System.examPagesPerTest;
                        QuestionSet newQ = new QuestionSet(0, 0.0, bounds, 0, numTests);
                        System.examQuestionSet.add(newQ);
                        var dialogWindow = new Gtk.MessageDialog(
                                System.mainWindow,
                                Gtk.DialogFlags.MODAL,
                                Gtk.MessageType.INFO,
                                Gtk.ButtonsType.OK,
                                "Name space selected");
                        
                        dialogWindow.set_title("All done");
                        dialogWindow.show_all();
                        dialogWindow.run();
                        //dialogWindow.close(); //causes an error for some reason, and not needed
                        dialogWindow.destroy();
                        
                        this.isNameBoundsSet = false;
                        this.currentQuestionSetup = 1;
                        startQuestionSetup();
                    }                
                    break;
                }
                
                default:
                    break;
            }
        }

        return false;
    }
    
    public bool onScroll(Gtk.Widget source, Gdk.EventScroll evt)
    {
        if (System.isGrading) //we have finished setup, and are now actually grading the different student's tests
        {
            switch (evt.direction)
            {
                case Gdk.ScrollDirection.UP:
                {
                    if (this.isHoldingCtrl)
                    {
                        this.currentScale+=0.15;
                        this.currentScale = double.min(this.currentScale, ExamImage.MAXSCALE);
                        this.renderPageWithQuestionFocus();
                    }
                    
                    break;
                }
                
                case Gdk.ScrollDirection.DOWN:
                {
                    if (this.isHoldingCtrl)
                    {
                        this.currentScale-=0.15;
                        this.currentScale = double.max(this.currentScale, 0.3);
                        this.renderPageWithQuestionFocus();
                    }
                    
                    break;
                }
            }
        }
        else
        {
            switch (evt.direction)
            {
                case Gdk.ScrollDirection.UP:
                {
                    if (this.isHoldingCtrl)
                    {
                        this.currentScale+=0.15;
                        this.currentScale = double.min(this.currentScale, ExamImage.MAXSCALE);
                        this.refreshCurrentPage();
                    }
                    else if (this.isHoldingShft)
                    {
                        this.currentFocusX-=0.05;
                        this.refreshCurrentPage();
                    }
                    else
                    {
                        this.currentFocusY-=0.05;
                        this.refreshCurrentPage();
                    }
                    
                    break;
                }
                
                case Gdk.ScrollDirection.DOWN:
                {
                    if (this.isHoldingCtrl)
                    {
                        this.currentScale-=0.15;
                        this.currentScale = double.max(this.currentScale, 0.3);
                        this.refreshCurrentPage();
                    }
                    else if (this.isHoldingShft)
                    {
                        this.currentFocusX+=0.05;
                        this.refreshCurrentPage();
                    }
                    else
                    {
                        this.currentFocusY+=0.05;
                        this.refreshCurrentPage();
                    }
                    
                    break;
                }
                
                case Gdk.ScrollDirection.LEFT:
                {
                    this.currentFocusX-=0.01;
                    this.refreshCurrentPage();
                    break;
                }
                
                case Gdk.ScrollDirection.RIGHT:
                {
                    this.currentFocusX+=0.01;
                    this.refreshCurrentPage();
                    break;
                }
            }
        }
        
        return false;
    }

    public bool onMouseClick(Gtk.Widget source, Gdk.EventButton evt)
    {
        if (System.isGrading)
        {
            return false;
        }
        
        if (this.pdfIsLoaded && evt.button == 1) //left click
        {
            //the events are relative to the event box that wraps the image, not
            // the image itself. So, in case the image size does not fill the entire
            // event box container, we need to compute the offsets to get the
            // event coordinates to be relative to the image.
            Gtk.Allocation rect = getEventBoxRect();
            double imageStartX = (rect.width  - this.width)/2;
            double imageStartY = (rect.height - this.height)/2;
            
            this.coordsClickStartX = (evt.x - imageStartX) / this.width;
            this.coordsClickStartY = (evt.y - imageStartY) / this.height;
            
            this.coordsClickStartX = double.max(this.coordsClickStartX, 0.0);
            this.coordsClickStartY = double.max(this.coordsClickStartY, 0.0);
            this.coordsClickStartX = double.min(this.coordsClickStartX, 0.99999999);
            this.coordsClickStartY = double.min(this.coordsClickStartY, 0.99999999);
            
            //the entire pdf view cant fit inside the event box view, so
            // we are only seeing a subsample of it. adjust the coords
            // so that they are global and not local
            double scale = this.currentScale / ExamImage.MAXSCALE;
            int scaledWidth  = (int)(this.pdfPagePixbufMaxScale.width  * scale);
            int scaledHeight = (int)(this.pdfPagePixbufMaxScale.height * scale);
            
            if (scaledWidth > rect.width)
            {
                double viewWidthPercentage = ((double)rect.width)/scaledWidth;
                this.coordsClickStartX = this.currentFocusX - (viewWidthPercentage/2) + viewWidthPercentage*this.coordsClickStartX;
            }
            
            if (scaledHeight > rect.height)
            {
                double viewHeightPercentage = ((double)rect.height)/scaledHeight;
                this.coordsClickStartY = this.currentFocusY - (viewHeightPercentage/2) + viewHeightPercentage*this.coordsClickStartY;
            }
            
            this.coordsClickEndX = this.coordsClickStartX;
            this.coordsClickEndY = this.coordsClickStartY;
            
            redrawPageWithSelectionBox();
        }
        
        return false;
    }
    
    public bool onMouseMove(Gtk.Widget source, Gdk.EventMotion evt)
    {
        if (System.isGrading)
        {
            return false;
        }
        
        if (this.pdfIsLoaded)
        {
            Gtk.Allocation rect = getEventBoxRect();
            double imageStartX = (rect.width  - this.width)/2;
            double imageStartY = (rect.height - this.height)/2;
            
            double coordsMouseX = (evt.x - imageStartX) / this.width;
            double coordsMouseY = (evt.y - imageStartY) / this.height;
            
            coordsMouseX = double.max(coordsMouseX, 0.0);
            coordsMouseY = double.max(coordsMouseY, 0.0);
            coordsMouseX = double.min(coordsMouseX, 0.99999999);
            coordsMouseY = double.min(coordsMouseY, 0.99999999);
            
            //the entire pdf view cant fit inside the event box view, so
            // we are only seeing a subsample of it. adjust the coords
            // so that they are global and not local
            double scale = this.currentScale / ExamImage.MAXSCALE;
            int scaledWidth  = (int)(this.pdfPagePixbufMaxScale.width  * scale);
            int scaledHeight = (int)(this.pdfPagePixbufMaxScale.height * scale);
            
            if (scaledWidth > rect.width)
            {
                double viewWidthPercentage = ((double)rect.width)/scaledWidth;
                coordsMouseX = this.currentFocusX - (viewWidthPercentage/2) + viewWidthPercentage*coordsMouseX;
            }
            
            if (scaledHeight > rect.height)
            {
                double viewHeightPercentage = ((double)rect.height)/scaledHeight;
                coordsMouseY = this.currentFocusY - (viewHeightPercentage/2) + viewHeightPercentage*coordsMouseY;
            }
            
            this.coordsClickEndX = coordsMouseX;
            this.coordsClickEndY = coordsMouseY;
                
            redrawPageWithSelectionBox();
        }
        
        return false;
    }
    
    private void redrawPageWithSelectionBox()
    {
        if (!this.pdfIsLoaded)
        {
            return;
        }
        
        var surface = new Cairo.ImageSurface(Cairo.Format.ARGB32, this.width, this.height);
        var context = new Cairo.Context(surface);
        
        // Draw the existing pixbuf onto the surface
        Gdk.cairo_set_source_pixbuf(context, this.pdfPagePixbufCurrent, 0, 0);
        context.paint();
        
        Gtk.Allocation rect = getEventBoxRect();
        
        int startX = (int)(this.coordsClickStartX * this.width);
        int startY = (int)(this.coordsClickStartY * this.height);
        int rectWidth  = (int)((this.coordsClickEndX * this.width)  - startX);
        int rectHeight = (int)((this.coordsClickEndY * this.height) - startY);
        
        double scale = this.currentScale / ExamImage.MAXSCALE;
        int scaledWidth  = (int)(this.pdfPagePixbufMaxScale.width  * scale);
        int scaledHeight = (int)(this.pdfPagePixbufMaxScale.height * scale);
        
        if (scaledWidth > rect.width)
        {
            double viewPercWidth = ((double)rect.width)/scaledWidth;
            double minPercX = this.currentFocusX - (viewPercWidth/2);
            double startPercX = (this.coordsClickStartX-minPercX)/viewPercWidth;
            
            startX = (int)(startPercX * this.width);
            rectWidth = (int)(rectWidth/viewPercWidth);
        }
        
        if (scaledHeight > rect.height)
        {
            double viewPercHeight = ((double)rect.height)/scaledHeight;
            double minPercY = this.currentFocusY - (viewPercHeight/2);
            double startPercY = (this.coordsClickStartY-minPercY)/viewPercHeight;
            
            startY = (int)(startPercY * this.height);
            rectHeight = (int)(rectHeight/viewPercHeight);
        }
        
        //draw a black transparent rectangle
        context.set_source_rgba(0, 0, 0, 0.4);
        context.rectangle(startX, startY, rectWidth, rectHeight);
        context.fill();
        
        var pixbuf = Gdk.pixbuf_get_from_surface(context.get_target(), 0, 0, this.width, this.height);
        this.image.set_from_pixbuf(pixbuf);
    }
    
    //will draw the page with only a specific question visible
    public void renderPageWithQuestionFocus()
    {
        if (!this.pdfIsLoaded)
        {
            return;
        }
        
        QuestionSet qs = System.examQuestionSet.get(0); //add 1 because first entry is name space
        this.currentPage = qs.get_page_num() + System.currentTest*System.examPagesPerTest;
        
        //make sure we are on the right page
        this.renderNewPage();
        
        
        //step 1: scale the page to our zoom level
        //TODO: make sure this height+width dont go over the size of the eventBox.
        double scale = this.currentScale / ExamImage.MAXSCALE;
        //the size (in pixels) that we are going to scale the maxsize pixbuf to
        int scaledWidth  = (int)(this.pdfPagePixbufMaxScale.width  * scale);
        int scaledHeight = (int)(this.pdfPagePixbufMaxScale.height * scale);
        Gdk.Pixbuf? scaledPixbuf = null;
        if (scale < 0.35)
        {
            scaledPixbuf = this.pdfPagePixbufMaxScale.scale_simple(scaledWidth, scaledHeight, Gdk.InterpType.BILINEAR);
        }
        else if (scale <= 1.0)
        {
            scaledPixbuf = this.pdfPagePixbufMaxScale.scale_simple(scaledWidth, scaledHeight, Gdk.InterpType.BILINEAR);
            //scaledPixbuf = this.pdfPagePixbufMaxScale.scale_simple(scaledWidth, scaledHeight, Gdk.InterpType.NEAREST);
        }
        
        //step 2: select the bounds of the scaled image to be our specific question bounds
        
        double[] bounds = qs.get_bounds();
        double minX = double.min(bounds[0], bounds[2]);
        double maxX = double.max(bounds[0], bounds[2]);
        double minY = double.min(bounds[1], bounds[3]);
        double maxY = double.max(bounds[1], bounds[3]);
        
        int boundsLeft  = (int)(scaledWidth*minX);
        int boundsRight = (int)(scaledWidth*maxX);
        int boundsTop   = (int)(scaledHeight*minY);
        int boundsBot   = (int)(scaledHeight*maxY);
        
        //TODO: make sure this height+width dont go over the size of the eventBox.
        this.pdfPagePixbufCurrent = new Gdk.Pixbuf.subpixbuf(scaledPixbuf, boundsLeft, boundsTop, (boundsRight-boundsLeft), (boundsBot-boundsTop));
        this.image.set_from_pixbuf(this.pdfPagePixbufCurrent);
        
        System.mainWindow.set_title("PDF Grader        Grading Test "+(System.currentTest+1).to_string()+", Question "+(System.currentQuestion).to_string());
    }
    
    //call this to render from scratch any given students answer to a given question.
    // used in export when making the latex file
    public Gdk.Pixbuf renderQuestionOnTest(QuestionSet questionSet, int testNumber)
    {
        if (!this.pdfIsLoaded)
        {
            return this.pdfPagePixbufMaxScale;
        }
        
        //the size (in pixels) that the pdf has been rendered at
        int renderWidth  = (int)(this.defaultWidth  * ExamImage.MAXSCALE);
        int renderHeight = (int)(this.defaultHeight * ExamImage.MAXSCALE);
        
        //create a new surface because the size may be different since the last time the pdf was drawn
        var surface = new Cairo.ImageSurface(Cairo.Format.ARGB32, renderWidth, renderHeight);
        var context = new Cairo.Context(surface);
        
        //set the scale to fit the entire eventbox window (as much as we can in either dimension)
        context.get_target().set_device_scale(ExamImage.MAXSCALE, ExamImage.MAXSCALE);
        
        //calculate which page this question is on
        QuestionSet qs = questionSet;
        int pageNum = qs.get_page_num() + testNumber*System.examPagesPerTest;
        
        //render the pdf page onto the surface via the context
        var page = this.document.get_page(pageNum);
        page.render(context);
        
        var fullPage = Gdk.pixbuf_get_from_surface(context.get_target(), 0, 0, renderWidth, renderHeight);
        
        //step 2: select the bounds of the scaled image to be our specific question bounds
        
        double[] bounds = qs.get_bounds();
        double minX = double.min(bounds[0], bounds[2]);
        double maxX = double.max(bounds[0], bounds[2]);
        double minY = double.min(bounds[1], bounds[3]);
        double maxY = double.max(bounds[1], bounds[3]);
        
        int boundsLeft  = (int)(renderWidth*minX);
        int boundsRight = (int)(renderWidth*maxX);
        int boundsTop   = (int)(renderHeight*minY);
        int boundsBot   = (int)(renderHeight*maxY);
        
        return new Gdk.Pixbuf.subpixbuf(fullPage, boundsLeft, boundsTop, (boundsRight-boundsLeft), (boundsBot-boundsTop));
    }
    
    //returns an allocation object that contains the 
    // width and height of the Gtk.EventBox that we live inside of.
    private Gtk.Allocation getEventBoxRect()
    {
        Gtk.Allocation rect = Gtk.Allocation();
        System.examEventBox.get_allocation(out rect);
        return rect;
    }
    
    //creates a new pixbuf based on the already rendered pdf page pixbuf.
    //call this after anything like zoom/focus position changes
    public void refreshCurrentPage()
    {
        if (!this.pdfIsLoaded)
        {
            return;
        }
        
        double scale = this.currentScale / ExamImage.MAXSCALE;
        //the size (in pixels) that we are going to scale the maxsize pixbuf to
        int renderWidth  = (int)(this.pdfPagePixbufMaxScale.width  * scale);
        int renderHeight = (int)(this.pdfPagePixbufMaxScale.height * scale);
        Gdk.Pixbuf? scaledPixbuf = null;
        if (scale < 0.35)
        {
            scaledPixbuf = this.pdfPagePixbufMaxScale.scale_simple(renderWidth, renderHeight, Gdk.InterpType.BILINEAR);
        }
        else if (scale <= 1.0)
        {
            scaledPixbuf = this.pdfPagePixbufMaxScale.scale_simple(renderWidth, renderHeight, Gdk.InterpType.NEAREST);
        }
        
        Gtk.Allocation viewSize = getEventBoxRect();
        
        //the center of focus 
        int focusX = (int)(renderWidth  * this.currentFocusX);
        int focusY = (int)(renderHeight * this.currentFocusY);
        
        //make sure that the focus is not going out of bounds, and readjust the focus to be in bounds
        if (viewSize.width >= scaledPixbuf.width) //if the view is bigger, then focus on the center
        {
            this.currentFocusX = 0.5;
        }
        else if (focusX < viewSize.width/2)
        {
            this.currentFocusX = ((double)(viewSize.width/2))/(scaledPixbuf.width);
        }
        else if (focusX > scaledPixbuf.width-(viewSize.width/2))
        {
            this.currentFocusX = 1-(((double)(viewSize.width/2))/(scaledPixbuf.width));
        }
        
        if (viewSize.height >= scaledPixbuf.height)
        {
            this.currentFocusY = 0.5;
        }
        else if (focusY < viewSize.height/2)
        {
            this.currentFocusY = ((double)(viewSize.height/2))/(scaledPixbuf.height);
        }
        else if (focusY > scaledPixbuf.height-(viewSize.height/2))
        {
            this.currentFocusY = 1-(((double)(viewSize.height/2))/(scaledPixbuf.height));
        }
                
        //recompute focus with new focus values
        focusX = (int)(renderWidth  * this.currentFocusX);
        focusY = (int)(renderHeight * this.currentFocusY);
        
        int boundsLeft  = focusX - (viewSize.width/2);
        int boundsRight = focusX + (viewSize.width/2);
        
        int boundsTop = focusY - (viewSize.height/2);
        int boundsBot = focusY + (viewSize.height/2);
        
        boundsLeft = int.max(0, boundsLeft);
        boundsLeft = int.min(renderWidth, boundsLeft);
        boundsRight = int.max(0, boundsRight);
        boundsRight = int.min(renderWidth, boundsRight);
        
        boundsTop = int.max(0, boundsTop);
        boundsTop = int.min(renderHeight, boundsTop);
        boundsBot = int.max(0, boundsBot);
        boundsBot = int.min(renderHeight, boundsBot);
        
        this.pdfPagePixbufCurrent = new Gdk.Pixbuf.subpixbuf(scaledPixbuf, boundsLeft, boundsTop, (boundsRight-boundsLeft), (boundsBot-boundsTop));
        this.image.set_from_pixbuf(this.pdfPagePixbufCurrent);
        
        this.width  = this.pdfPagePixbufCurrent.width;
        this.height = this.pdfPagePixbufCurrent.height;
    }
    
    //renders the page and stores the result in the surface
    // this is an expensive function.
    public void renderNewPage()
    {
        if (!this.pdfIsLoaded)
        {
            return;
        }
        
        //the size (in pixels) that the pdf has been rendered at
        int renderWidth  = (int)(this.defaultWidth  * ExamImage.MAXSCALE);
        int renderHeight = (int)(this.defaultHeight * ExamImage.MAXSCALE);
        
        //create a new surface because the size may be different since the last time the pdf was drawn
        var surface = new Cairo.ImageSurface(Cairo.Format.ARGB32, renderWidth, renderHeight);
        var context = new Cairo.Context(surface);
        
        //set the scale to fit the entire eventbox window (as much as we can in either dimension)
        context.get_target().set_device_scale(ExamImage.MAXSCALE, ExamImage.MAXSCALE);
        
        //render the pdf page onto the surface via the context
        var page = this.document.get_page(this.currentPage);
        page.render(context);
        
        this.pdfPagePixbufMaxScale = Gdk.pixbuf_get_from_surface(context.get_target(), 0, 0, renderWidth, renderHeight);
    }
    
    public Gtk.Image getImage()
    {
        return this.image;
    }
}

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
    public static Gtk.ProgressBar progress_bar; //progress bar for user to view how many questions are graded out of total number of questions

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
    private static void initUI() { 
        var window = new Gtk.Window();
        mainWindow = window;
        window.set_title("PDF Grader");
        try { 
            window.set_icon_from_file("res/icon.png");
        }
        catch (GLib.Error e) { 
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
            
            //ViewPane is left side pane featuring examEventBox and progress_bar
            var viewPane = new Gtk.Paned(Gtk.Orientation.VERTICAL);
            examEventBox = new Gtk.EventBox(); //event box to wrap the image around
            examImage = new ExamImage(); //the image that goes in the exam frame
            examEventBox.add(examImage.getImage()); //wrap the Gtk.Image inside of an EventBox, in order to get callbacks
            viewPane.pack1(examEventBox, true, false);

            //Progress Bar init and pack into left side viewPane under the examEventBox
            progress_bar = new Gtk.ProgressBar();
            progress_bar.set_fraction(0);
            viewPane.pack2(progress_bar, true, false);
            hpaned.pack1(viewPane, true, false);

            
            //right side: marks + cgi + hotkeys
            marksGrid = new Gtk.Grid();
            marksGrid.set_row_spacing(5);
            marksGrid.set_column_spacing(5);
            marksGrid.set_size_request(100, -1); //100 = minimum width
            hpaned.pack2(marksGrid, false, false); //put the vpaned on the right side of the hpaned

        }
        
        window.show_all();
    }

    private static void initCallbacks() { 
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
        
        Save.saveSpecific(PDFPath, examQuestionSet.get(0));
        Lock.closeFile(PDFPath, currentQuestion);
    }
    
    private static bool timerCallback()
    {   
        if (currentQuestion > 0) {
            Save.saveSpecific(PDFPath, examQuestionSet.get(0));
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
        var currQuestion = questionSet.getQuestions().get(currentTest); //the specific student's test question
        var pool = questionSet.rubricPool;

        
        int i = 0;
        foreach (Mark mark in pool.values)
        {
            var actionbar = new Gtk.ActionBar();
            actionbar.set_hexpand(true);
            
            var label = new Gtk.Label(mark.getDescription());
            label.set_line_wrap(true);
            label.set_size_request(96, -1); //make some room for mark descriptions
            actionbar.pack_start(label);
            
            var checkbox = new MarkViewCheckbox(mark);
            checkbox.set_size_request(24, -1);
            actionbar.pack_end(checkbox);
            if (currQuestion.getMarks().contains(mark.getID()))
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
            if (mark.hotKey != 0)
            {
                button.set_label(keyvalToString(mark.hotKey));
            }
            button.clicked.connect(clickedMarkHotkey);
            
            var entryWorth = new MarkViewWorthEntry(mark);
            entryWorth.set_size_request(24, -1);
            entryWorth.set_visibility(true);
            entryWorth.set_text(mark.getWorth().to_string());
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
        var currQuestion = questionSet.getQuestions().get(currentTest); //the specific student's question
        var pool = questionSet.rubricPool;
        
        int i = 0;
        foreach (Mark mark in pool.values)
        {
            Gtk.ActionBar actionbar = (Gtk.ActionBar)marksGrid.get_child_at(0, i);

            var widgets = actionbar.get_children();

            MarkViewCheckbox checkbox = (MarkViewCheckbox)widgets.nth_data(3);

            if (currQuestion.getMarks().contains(mark.getID()))
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
        var currQuestion = questionSet.getQuestions().get(currentTest); //the specific student's test question
        var questionActiveMarks = currQuestion.getMarks();

        var mark = btn.mark;
        
        if (btn.get_active()) //the checkbox is now checked, so add the mark to the question's mark list
        {
            if (!questionActiveMarks.contains(mark.getID()))
            {
                questionActiveMarks.add(mark.getID());
            }
        }
        else //the checkbox is now unchecked, remove the mark from the question's mark list
        {
            if (questionActiveMarks.contains(mark.getID()))
            {
                questionActiveMarks.remove(mark.getID());
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
            worthEntry.mark.setWorth(double.parse(newWorthText));
        }
    }
    
    private static void clickedFileSave()
    {
        if (currentQuestion > 0) {
            Save.saveSpecific(PDFPath, examQuestionSet.get(0));
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
                    Save.readMeta(ref examQuestionsPerTest, ref examPagesPerTest, out password, PDFPath);
                    
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
            Save.saveSpecific(PDFPath, examQuestionSet.get(0));

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
                    var pool = questionSet.rubricPool;
                    int maxID = -1;
                    foreach (Mark mark in pool.values)
                    {
                        maxID = int.max(maxID, mark.getID());
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
            Save.saveSpecific(PDFPath, examQuestionSet.get(0));
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
        Gee.HashMap<int, Mark> currPool = examQuestionSet.get(0).getRubric(); //since the first entry is the name space, we need to add 1
        for (int i = 0; i < currPool.size; i++)
        {
            if(binding == currPool.get(i).getHotKey())
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


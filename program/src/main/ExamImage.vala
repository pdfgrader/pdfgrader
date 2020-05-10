//Class that handles all of the rendering of a pdf document page.
//First, you create an object, and load in a PDF file to it,
//then you can call renderNewPage and getImage.
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
                System.markHotkeyButton.mark.hotKey = 0;
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
                    System.markHotkeyButton.mark.hotKey = key.keyval;
                    
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
                Question currQuestion = questionSet.getQuestions().get(System.currentTest); 
                Gee.ArrayList<int> questionActiveMarks = currQuestion.getMarks();
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

                            //Update progress bar with the progress on the current question
                            System.progressBar.set_fraction(((double) System.currentTest)/(document.get_n_pages()/System.examPagesPerTest));

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

                            //Update progress bar with the progress on the current question
                            System.progressBar.set_fraction(((double) System.currentTest)/(document.get_n_pages()/System.examPagesPerTest));

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
                        newQ.addDefaultMarks();
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

                            Save.createMeta(System.examQuestionsPerTest, System.examPagesPerTest, System.password, System.PDFPath);
                            Save.saveAll(System.PDFPath, System.examQuestionSet);

                            
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
        this.currentPage = qs.getPageNum() + System.currentTest*System.examPagesPerTest;
        
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
        
        double[] bounds = qs.getBounds();
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
        int pageNum = qs.getPageNum() + testNumber*System.examPagesPerTest;
        
        //render the pdf page onto the surface via the context
        var page = this.document.get_page(pageNum);
        page.render(context);
        
        var fullPage = Gdk.pixbuf_get_from_surface(context.get_target(), 0, 0, renderWidth, renderHeight);
        
        //step 2: select the bounds of the scaled image to be our specific question bounds
        
        double[] bounds = qs.getBounds();
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
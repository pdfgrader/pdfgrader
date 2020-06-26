using Xml;
using Gee;

public class QuestionSet : Object{
    public int questionNum; // question number
    public double totalPoints; // total points possible
    public double[] bounds;
    public int pageNum; // which page is this question on?
    public Gee.HashMap<int, Mark> rubricPool;
    public Gee.ArrayList<Question> questions;
    //private Question currQuestion;

    public QuestionSet(int QNum, double total, double[] b, int pNum){
        this.questionNum = QNum;
        this.totalPoints = total;
        this.bounds = b;
        this.pageNum = pNum;
        this.questions = new Gee.ArrayList<Question>();
        this.rubricPool = new Gee.HashMap<int, Mark>();
    }

    // Fills question set with new empty questions - HAS to be called before grading starts but can only be called after the number of tests has been determined (aka, end of setup)
    public void init_question_set(int num) { 
        for(int i = 0; i < num; i++) { 
            Question q = new Question();
            this.questions.add(q);
        }
    }
    
    public void addDefaultMarks() {
        this.rubricPool[0] = new Mark(0, -totalPoints, "No points", true);
        this.rubricPool[1] = new Mark(1, -totalPoints/2, "Half points", true);
        this.rubricPool[2] = new Mark(2, 0.0, "Full points", true);
    }
    
    public Question questionSelect(int num){
        return questions.get(num);
    }

    public Mark getMarkbyID(int ID) {
        return rubricPool.get(ID);
    }

    public bool are_bounds_valid() { 
        if (bounds[0] == 0 && bounds[1] == 0 && bounds[2] == 0 && bounds[3] == 0) { 
            return true;
        } else { 
            return false;
        } 
    }

    public void set_points(double points) { 
        this.totalPoints = points;
    }

    public void set_bounds(double[] bounds){
        this.bounds = bounds;
    }
    
    public double[] getBounds(){
        return this.bounds;
    }

    public int getQNum() {
        return this.questionNum;
    }
    
    public Gee.HashMap<int, Mark> getRubric(){
        return rubricPool;
    }
    
    public int getPageNum(){
        return this.pageNum;
    }
    
    public Gee.ArrayList<Question> getQuestions(){
        return this.questions;
    }

    public void addMark (Mark m) {
        rubricPool.@set(m.getID(), m);   
    }

    public void save(Xml.TextWriter saver) throws FileError {
        
		Save.ret_to_ex (saver.start_element("QuestionSet"));
        


        Save.ret_to_ex (saver.start_element("totalPoints"));
        Save.ret_to_ex (saver.write_attribute("points",totalPoints.to_string()));
        Save.ret_to_ex (saver.end_element());

        Save.ret_to_ex (saver.start_element("bounds"));
        //string bound = "bound";
        for (int i = 1; i <= bounds.length; i++) {
            Save.ret_to_ex (saver.write_attribute("bound" + i.to_string(), bounds[i-1].to_string()));
        }
        Save.ret_to_ex (saver.end_element());

        Save.ret_to_ex (saver.start_element("pageNum"));
        Save.ret_to_ex (saver.write_attribute("page", pageNum.to_string()));
        Save.ret_to_ex (saver.end_element());

        if (questionNum != 0) {
            Save.ret_to_ex (saver.start_element("marks"));
            
            Gee.Collection<Mark> marks = rubricPool.values;
            foreach (Mark mark in marks) {
                mark.save(saver);
            }

            Save.ret_to_ex (saver.end_element());


            Save.ret_to_ex (saver.start_element("testInfo"));
            
            for( int i = 0; i < questions.size; i++) {
                questions.get(i).save(saver, i);
            }

            Save.ret_to_ex (saver.end_element());
        }
        
        
    
		Save.ret_to_ex (saver.end_element ());
        
	}
}

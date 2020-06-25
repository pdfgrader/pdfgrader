using Xml;
using Gee;

public class QuestionSet : Object {
    private int question_num; // question number
    private double total_points; // total points possible
    private double[] bounds;
    private int page_num; // which page is this question on?
    private Gee.HashMap<int, Mark> rubric_pool;
    private Gee.ArrayList<Question> questions;

    public QuestionSet(int q_num, double total_points, double[] bounds, int page_num, int num_questions) {
        this.question_num = q_num;
        this.total_points = total_points;
        this.bounds = bounds;
        this.page_num = page_num;
        this.questions = new Gee.ArrayList<Question>();
        for(int i = 0; i < num_questions; i++) {
            Question q = new Question();
            this.questions.add(q);
        }
        this.rubric_pool = new Gee.HashMap<int, Mark>();
    }
    
    public void add_default_marks() {
        this.rubric_pool[0] = new Mark(0, -total_points, "No points", true);
        this.rubric_pool[1] = new Mark(1, -total_points/2, "Half points", true);
        this.rubric_pool[2] = new Mark(2, 0.0, "Full points", true);
    }

    public int get_question_num() {
        return this.question_num;
    }

    public double get_total_points() {
        return this.total_points;
    }
   
    public double[] get_bounds() {
        return this.bounds;
    }

    public int get_page_num() {
        return this.page_num;
    }

    public Gee.HashMap<int, Mark> get_rubric() {
        return rubric_pool;
    }

    public Mark get_mark_by_id(int ID) {
        return rubric_pool.get(ID);
    }

    public void add_mark (Mark m) {
        rubric_pool.@set(m.get_id(), m);   
    }

    public Gee.ArrayList<Question> get_questions() {
        return this.questions;
    }

    public Question get_question(int test_num) {
        return questions.get(test_num);
    }

    public void save(Xml.TextWriter saver) throws FileError {
		Save.ret_to_ex (saver.start_element("QuestionSet"));
        
        Save.ret_to_ex (saver.start_element("total_points"));
        Save.ret_to_ex (saver.write_attribute("points", total_points.to_string()));
        Save.ret_to_ex (saver.end_element());

        Save.ret_to_ex (saver.start_element("bounds"));
        for (int i = 1; i <= bounds.length; i++) {
            Save.ret_to_ex (saver.write_attribute("bound" + i.to_string(), bounds[i-1].to_string()));
        }
        Save.ret_to_ex (saver.end_element());

        Save.ret_to_ex (saver.start_element("page_num"));
        Save.ret_to_ex (saver.write_attribute("page", page_num.to_string()));
        Save.ret_to_ex (saver.end_element());

        if (question_num != 0) {
            Save.ret_to_ex (saver.start_element("marks"));
            Gee.Collection<Mark> marks = rubric_pool.values;
            foreach (Mark mark in marks) {
                mark.save(saver);
            }
            Save.ret_to_ex (saver.end_element());

            Save.ret_to_ex (saver.start_element("test_info"));
            for( int i = 0; i < questions.size; i++) {
                questions.get(i).save(saver, i);
            }
            Save.ret_to_ex (saver.end_element());
        }

		Save.ret_to_ex (saver.end_element ());
	}
}

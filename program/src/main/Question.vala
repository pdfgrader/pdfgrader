using Xml;
using Gee;


public class Question : Object {
    private double points_earned; // total points earned on quesiton
    private Gee.ArrayList<int> marks;

    public Question() {
        points_earned = 0.0;
        marks = new Gee.ArrayList<int>();
    }

    public double get_points_earned() {
        return this.points_earned;
    }

    public void set_points_earned(double points_earned) {
        this.points_earned = points_earned;
    }

    public Gee.ArrayList<int> get_marks() {
        return this.marks;
    }

    public void add_mark(Mark m) {
        marks.add(m.get_id());
    }

    public void add_mark_by_id(int id) {
        marks.add(id);
    }

    public void save(Xml.TextWriter saver, int testNum) throws FileError {
        Save.ret_to_ex (saver.start_element("test" + (testNum + 1).to_string()));
        if (marks.size > 0) {
            StringBuilder mark_list = new StringBuilder();
            int i;
            for (i = 0; i < marks.size - 1; i++) {
                mark_list.append(marks.get(i).to_string() + " "); 
            }
            mark_list.append(marks.get(i).to_string());

            Save.ret_to_ex (saver.write_attribute("marks", mark_list.str));
        } else {
            Save.ret_to_ex (saver.write_attribute("marks", ""));
        }
        Save.ret_to_ex (saver.end_element());   
    }
}

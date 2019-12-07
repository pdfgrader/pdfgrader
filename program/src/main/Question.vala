using Xml;
using Gee;


public class Question : Object{
    public double pointsEarned; // total points earned on quesiton
    public Gee.ArrayList<int> marks;

    //private string gradeDescription;

    public Question(){
        pointsEarned = 0.0;
        marks = new Gee.ArrayList<int>();
    }

    public void addMark(Mark m){
        marks.add(m.getID());
    }
    
    public void addMarkbyID(int id){
        marks.add(id);
    }

    public void removeMarka(Mark m){
        //marks.remove(m.getID());
    }
    
    public void save(Xml.TextWriter saver, int testNum) throws FileError {
        Save.ret_to_ex (saver.start_element("test" + (testNum + 1).to_string()));
        if (marks.size > 0) {
            StringBuilder markList = new StringBuilder();
            int i;
            for (i = 0; i < marks.size - 1; i++) {
                markList.append(marks.get(i).to_string() + " "); 
            }
            markList.append(marks.get(i).to_string());

            Save.ret_to_ex (saver.write_attribute("marks", markList.str));
        } else {
            Save.ret_to_ex (saver.write_attribute("marks", ""));
        }
        

        Save.ret_to_ex (saver.end_element());
        
    }
    
    public Gee.ArrayList<int> getMarks(){
        return this.marks;
    }
}

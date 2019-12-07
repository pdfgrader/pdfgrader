using Xml;
using Gee;


public class Mark : Object{
    private int ID; //quick search identifier
    private double worth;
    private string description;
    private bool unique;
    public uint hotKey; //Key bind. 0 means no key

    public Mark(int id, double worth, string desc, bool unique){
        this.ID = id;
        this.worth = worth;
        this.description = desc;
        this.unique = unique;
    }

    public void setDescription(string d){
        description = d;
    }

    public string getDescription(){
        return description;
    }

    public void setWorth(double w){
        worth = w;
    }

    public double getWorth(){
        return worth;
    }

    public int getID(){
        return ID;
    }

    public void setHotKey(uint k){
        hotKey = k;
    }

    public uint getHotKey(){
        return hotKey;
    }
    
    public string toString(){
        string ret = "Points Lost: ".concat(worth.to_string(), "\n", "Description: ", description, "\n");
        return ret;
    }


    public void save(Xml.TextWriter saver) throws FileError {
        
        Save.ret_to_ex (saver.start_element("mark"));

        Save.ret_to_ex (saver.write_attribute("id", ID.to_string()));

        Save.ret_to_ex (saver.write_attribute("worth", worth.to_string()));

        Save.ret_to_ex (saver.write_attribute("description", description));

        Save.ret_to_ex (saver.write_attribute("unique",unique.to_string()));


        Save.ret_to_ex (saver.end_element());
        
    }
}

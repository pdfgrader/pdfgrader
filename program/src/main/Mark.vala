using Xml;
using Gee;

public class Mark : Object {
    private int id; //quick search identifier
    private double worth;
    private string description;
    private bool unique;
    private uint hot_key; //Key bind. 0 means no key

    public Mark(int id, double worth, string desc, bool unique) {
        this.id = id;
        this.worth = worth;
        this.description = desc;
        this.unique = unique;
    }

    public int get_id() {
        return id;
    }

    public double get_worth() {
        return worth;
    }

    public void set_worth(double w) {
        this.worth = w;
    }

    public string get_description() {
        return description;
    }

    public void set_description(string d) {
        this.description = d;
    }

    public uint get_hot_key() {
        return hot_key;
    }
    
    public void set_hot_key(uint hk) {
        this.hot_key = hk;
    }

    public string to_string() {
       return "Points Lost: ".concat(worth.to_string(), "\n", "Description: ", description, "\n");
    }

    public void save(Xml.TextWriter saver) throws FileError {
        Save.ret_to_ex (saver.start_element("mark"));
        Save.ret_to_ex (saver.write_attribute("id", id.to_string()));
        Save.ret_to_ex (saver.write_attribute("worth", worth.to_string()));
        Save.ret_to_ex (saver.write_attribute("description", description));
        Save.ret_to_ex (saver.write_attribute("unique", unique.to_string()));
        Save.ret_to_ex (saver.end_element());        
    }
}

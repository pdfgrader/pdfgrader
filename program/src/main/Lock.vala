public class Lock {

    private static int current_question_number = 0;

    // returns 0 if switched to new question
    public static int attempt_switch(string path, int q_num) {
        File lock_file = File.new_for_path(path + "/.lock/Q" + q_num.to_string() + ".lock");
        try {
            lock_file.create(FileCreateFlags.NONE);
            FileOutputStream stream = lock_file.append_to(FileCreateFlags.NONE);
            // Write a period to show one program has the corresponding question open
            stream.write({46});
            stream.close();
            release_lock(File.new_for_path(path + "/.lock/Q" + current_question_number.to_string() + ".lock"));
            current_question_number = q_num;
            return 0;
        } catch (IOError.EXISTS e) {
            return -1;
        } catch (Error e) {
            return -2;
        }
    }

    private static int release_lock(File old_file) {     
            try {
                uint8[] contents;
                if (GLib.FileUtils.get_data(old_file.get_path(), out contents)) {
                    var locks = contents.length; 
                    if (locks == 1) {
                        old_file.delete();
                    } else {
                        contents = contents[0 : locks - 1];
                        GLib.FileUtils.set_data(old_file.get_path(), contents);
                    }
                } 
                return 0;
            } catch (Error e) {
                return -1;
            }
    }

    public static int close_file(string path, int q_num) {
        return release_lock(File.new_for_path(path + "/.lock/Q" + q_num.to_string() + ".lock"));
    }

    public static int lock_again(string path, int q_num) {
        release_lock(File.new_for_path(path + "/.lock/Q" + current_question_number.to_string() + ".lock"));
        File file = File.new_for_path(path + "/.lock/Q" + q_num.to_string() + ".lock");
        try {
            FileOutputStream stream = file.append_to(FileCreateFlags.NONE);
            // Write a period to show another program has the corresponding question open
            stream.write({46});
            stream.close();
            current_question_number = q_num;
            return 0;
        } catch (Error e) {
            return -1;
        }
        
    }
}

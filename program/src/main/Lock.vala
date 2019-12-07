public class Lock  {

    private static int currentQNum = 0;

    //returns 0 if switched to new question
    public static int attemptSwitch(string path, int qNum) {
        File lockFile = File.new_for_path(path + "/.lock/Q" + qNum.to_string() + ".lock");
        try {
            lockFile.create(FileCreateFlags.NONE);
            FileOutputStream stream = lockFile.append_to(FileCreateFlags.NONE);
            stream.write({46});
            stream.close();
            releaseLock(File.new_for_path(path + "/.lock/Q" + currentQNum.to_string() + ".lock"));
            currentQNum = qNum;
            return 0;
        } catch (IOError.EXISTS e) {
            return -1;
        } catch (Error e) {
            return -2;
        }
    }

    private static int releaseLock(File oldFile) {     
            try {
                uint8[] contents;
                if (GLib.FileUtils.get_data(oldFile.get_path(), out contents)) {
                    var locks = contents.length; 
                    if (locks == 1) {
                        oldFile.delete();
                    } else {
                        locks--;
                        contents = contents[0 : locks];
                        GLib.FileUtils.set_data(oldFile.get_path(), contents);
                    }
                } 
                return 0;
            } catch (Error e) {
                return -1;
            }
    }

    public static int closeFile(string path, int qNum) {
        return releaseLock(File.new_for_path(path + "/.lock/Q" + qNum.to_string() + ".lock"));
    }

    public static int lockAgain(string path, int qNum) {
        releaseLock(File.new_for_path(path + "/.lock/Q" + currentQNum.to_string() + ".lock"));
        File file = File.new_for_path(path + "/.lock/Q" + qNum.to_string() + ".lock");
        try {
            FileOutputStream stream = file.append_to(FileCreateFlags.NONE);
            stream.write({46});
            stream.close();
            currentQNum = qNum;
            return 0;
        } catch (Error e) {
            return -1;
        }
        
    }
}

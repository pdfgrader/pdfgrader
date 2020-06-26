


public static int main(string[] args) {
    int numQs = 5;
    int numTests = 7;
    string path = "./test.pdf";
    string pass = "password";
    Save.create_meta(numQs, numTests, path, pass);

    numQs = 17;
    numTests = 80;
    path = "./nota.pdf";
    pass = "fake";
    Save.read_meta(ref numQs, ref numTests, out path, pass);
    Save.create_meta(numQs, numTests, path, pass);



    var Question1 = new QuestionSet(1, 15, {12.5, 15}, 7, 1);

    var test1 = new Mark(1, -15, "hi", false);
    Question1.add_mark(test1);
    var test2 = new Mark(2, -12, "hello", true);
    Question1.add_mark(test2);
    var test3 = new Mark(3, 500, "bye", false);
    Question1.add_mark(test3);

    Question1.get_question(0).add_mark(test1);

    Question1.get_question(6).add_mark(test2);
    Question1.get_question(6).add_mark(test1);

    Question1.get_question(2).add_mark(test1);
    Question1.get_question(2).add_mark(test3);
    Question1.get_question(2).add_mark(test2);

    //save(1, Question1, false);

    //QuestionSet readInTest;
    //fileImport(1, 7, out readInTest);

    //save(2, readInTest, true);

    QuestionSet readInTest2;
    //fileImport(2, 7, out readInTest2);
    //bool concurrencyTest = (readInTest2 == null);
    //stdout.printf("%p\n", readInTest2);

    var examQuestionSet = new Gee.ArrayList<QuestionSet>();
    examQuestionSet.add(Question1);
    bool u = true;


    for(int i = 0; i < 1000000000; i++){
      stdout.printf("");
    }
    for(int i = 0; i < 1000000000; i++){
      stdout.printf("");
    }
    for(int i = 0; i < 1000000000; i++){
      stdout.printf("");
    }
    for(int i = 0; i < 1000000000; i++){
      stdout.printf("");
    }



    return 0;
}

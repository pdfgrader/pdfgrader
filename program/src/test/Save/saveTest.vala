


public static int main(string[] args) {
    int numQs = 5;
    int numTests = 7;
    string path = "./test.pdf";
    string pass = "password";
    Save.createMeta(numQs, numTests, path, pass);

    numQs = 17;
    numTests = 80;
    path = "./nota.pdf";
    pass = "fake";
    Save.readMeta(ref numQs, ref numTests, out path, pass);
    Save.createMeta(numQs, numTests, path, pass);



    var Question1 = new QuestionSet(1, 15, {12.5, 15}, 7, 1);

    var test1 = new Mark(1, -15, "hi", false);
    Question1.addMark(test1);
    var test2 = new Mark(2, -12, "hello", true);
    Question1.addMark(test2);
    var test3 = new Mark(3, 500, "bye", false);
    Question1.addMark(test3);

    Question1.questionSelect(0).addMark(test1);

    Question1.questionSelect(6).addMark(test2);
    Question1.questionSelect(6).addMark(test1);

    Question1.questionSelect(2).addMark(test1);
    Question1.questionSelect(2).addMark(test3);
    Question1.questionSelect(2).addMark(test2);

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

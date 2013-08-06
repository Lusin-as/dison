GEN=DisonTestMsg.java DisonRequestMsg.java DisonLogMsg.java DisonTopoMsg.java Constants.java

TESTDISON_H=../TestDison.h
DISON_H=../../DisonNew/src/DISON.h

all: testdison.jar

testdison.jar: TestDison.class
	jar cf $@ *.class

DisonTestMsg.java: $(TESTDISON_H)
	mig -target=null -java-classname=DisonTestMsg java $(TESTDISON_H) dison_test -o $@

DisonRequestMsg.java: $(TESTDISON_H)
	mig -target=null -java-classname=DisonRequestMsg java $(TESTDISON_H) dison_user_request -o $@
	
DisonLogMsg.java: $(TESTDISON_H)
	mig -target=null -java-classname=DisonLogMsg java $(TESTDISON_H) dison_stats -o $@
	
DisonTopoMsg.java: $(TESTDISON_H)
	mig -target=null -java-classname=DisonTopoMsg java $(TESTDISON_H) dison_topo -o $@
	
Constants.java: $(TESTDISON_H)
	ncg -target=null -java-classname=Constants java $(TESTDISON_H) TestDison.h -o $@

TestDison.class: $(wildcard *.java) $(GEN)
	javac *.java

clean:
	rm -f *.class $(GEN)

veryclean: clean
	rm testdison.jar

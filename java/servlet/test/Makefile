# Makefile for RHash, remote object server stuff.

JAVAHOME=/usr
JAR=$(JAVAHOME)/bin/jar
JAVAC=$(JAVAHOME)/bin/javac
JAVA=$(JAVAHOME)/bin/java
MYLIB=$(HOME)/lib/java
C1=$(MYLIB)/jsdk.jar:$(MYLIB)/DBCB.jar
C2=$(MYLIB)/RHash.jar:$(MYLIB)/cos.jar
C3=$(MYLIB)/spy.jar:$(MYLIB)/postgresql.jar:$(MYLIB)/xml4j.jar
CLASSPATH=$(C1):$(C2):$(C3):.

SCP=scp
DEST=bleu.west.spy.net:/usr/local/apache/java/net/spy/test/
# DEST=170.1.69.194:/usr/local/apache/java

CLASSES=net/spy/test/TestConfig.class \
	net/spy/test/TestUser.class net/spy/test/TestTest.class \
	net/spy/test/TestQuestion.class net/spy/test/TestAnswer.class \
	net/spy/test/Loader.class

.SUFFIXES: .java .class .jar

all: $(CLASSES)

jar: testtaker.jar

testtaker.jar: $(CLASSES)
	$(JAR) cv0f $@ $(CLASSES)

test: all
	env CLASSPATH=$(CLASSPATH) $(SERVLETRUNNER) -d $(PWD)

install: all
	$(SCP) $(CLASSES) $(DEST)

clean:
	rm -f $(CLASSES) testtaker.jar

.java.class:
	env CLASSPATH=$(CLASSPATH) $(JAVAC) $<

SHELL=bash

all: eval

clean:
	rm -f *.o eval mkosdefs

.SUFFIXES:

%.e: %.l
	./eval boot.l $^

%.s: %.l
	if [ $$(grep -l "compile-begin" $^) ]; then \
		./eval -O boot.l emit.l $^ > $@; \
	else \
		./eval -O boot.l emit.l <(echo "(compile-begin)"; cat $^; echo "(compile-end)") > $@; \
	fi

%: %.s
	gcc -m32 $^ -o $@ 

%.s: %.ll
	llc-3.4 -march=x86 $^ > $@

%.ll: %.c
	 clang -S -emit-llvm $^ -o $@ 

osdefs.k : mkosdefs
	./mkosdefs > $@

mkosdefs : mkosdefs.c
	gcc -o $@ $^

eval.s: boot.l emit.l eval.l osdefs.k
	./eval -O boot.l emit.l eval.l > $@

tests: eval test/test-subr test/test-basic

test-%: test-%.l
	./eval boot.l $^

test-bootstrap: boot.l emit.l eval.l
	./eval -O $^ > eval-self.s
	diff eval.s eval-self.s
	rm eval-self.s

stats:
	cat boot.l emit.l        | sed 's/.*debug.*//;s/;.*//' | sort -u | wc -l
	cat eval.l               | sed 's/.*debug.*//;s/;.*//' | sort -u | wc -l
	cat boot.l emit.l eval.l | sed 's/.*debug.*//;s/;.*//' | sort -u | wc -l

all:demo.cgi

demo.cgi:demo-cgi.lisp packages.lisp generate-executable.lisp Makefile
	clisp -q -ansi -norc -x '(load "generate-executable.lisp")' -x '(quit)'

clean:
	rm demo.cgi

tarball:
	tar -C .. -jcf ../demo.tar.bz2 demo

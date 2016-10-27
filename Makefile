
pkgs := javascriptcore,linenoise,compiler-libs.toplevel,astring

ml-js-repl:repl.ml
	ocamlfind ocamlc \
	-package ${pkgs} \
	-linkpkg $< -o $@
	./$@

.PHONY:clean

clean:;@rm -f *.cmt ml-js-repl *.o *.cmo *.cmi *.txt

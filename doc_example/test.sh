#/bin/sh
erl -pa deps/*/ebin -pa apps/*/ebin -eval 'application:start(doc_example)'
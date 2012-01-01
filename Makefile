# build all lib files
lib :
	./node_modules/.bin/coffee --compile --lint --output lib src

# build single lib file
lib/%.js : src/%.coffee
	./node_modules/.bin/coffee --compile --lint --output lib $<

.PHONY: lib

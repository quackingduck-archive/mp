# build all lib files
lib :
	./node_modules/.bin/coffee --compile --lint --output lib src

# build single lib file
lib/%.js : src/%.coffee
	./node_modules/.bin/coffee --compile --lint --output lib $<

# ---

test : test-internals

test-internals :
	./node_modules/.bin/mocha --ui qunit --bail --colors

# ---

tag :
	git tag v`coffee -e "console.log JSON.parse(require('fs').readFileSync 'package.json').version"`

# ---

.PHONY: lib

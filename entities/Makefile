RAGEL = ragel
RAGELFLAGS =
NODE = node
NODEFLAGS =

.PHONY: all
all: handlers.dat numeric.dat

entities.json:
	curl "https://html.spec.whatwg.org/$@" -o $@

machine.rl: to-ragel.js entities.json
machine.json: to-json.js machine.xml
handlers.dat: to-data.js machine.json
numeric.dat: gen-numeric-data.js

values.txt: handlers.dat

machine.rl machine.json handlers.dat numeric.dat:
	$(NODE) $(NODEFLAGS) $<

machine.xml: machine.rl
	$(RAGEL) $(RAGELFLAGS) -x $< > $@

.PHONY: clean
clean:
	rm entities.json machine.rl machine.json handlers.dat values.txt machine.xml numeric.dat

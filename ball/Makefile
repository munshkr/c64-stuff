BIN=ball.prg
SRC=main.s

all: $(BIN)

$(BIN): $(SRC)
	cl65 -o $(BIN) -u __EXEHDR__ -t c64 -C c64-asm.cfg $(SRC)

clean:
	rm -f $(BIN) *.o

run: $(BIN)
	x64 $<

.PHONY: clean run

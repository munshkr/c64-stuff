XA=xa

all: $(BIN)

$(BIN): main.s $(SRC)
	$(XA) -OPETSCII -o $@ $^

clean:
	rm -f $(BIN)

run: $(BIN)
	x64 $<

.PHONY: clean run

XA=xa

all: $(BIN)

$(BIN): $(SRC)
	$(XA) -o $@ $^

clean:
	rm -f $(BIN)

run: $(BIN)
	x64 $<

.PHONY: clean run

SRC = src/*.v
TEST_SRC = test/*.v
BIN = a.out

$(BIN): $(SRC) $(TEST_SRC)
	iverilog -s top_tb -o target/$(BIN) $(SRC) $(TEST_SRC)

.PHONY: all clean test

all: $(BIN)

target/%.vcd: test/%.v
	rm $@; iverilog -o target/$(BIN) $(SRC) $^; cd target; vvp $(BIN)

as: data/main.S
	./tools/as.hs -s data/main.S -o data/ram.txt -f

test: all as
	cd target; vvp $(BIN)

clean:
	rm -f target/*

build: 
	@v -o dist/vmonkey ./

run: build 
	@./dist/vmonkey

test: test-lexer test-parser

test-lexer: 
	@echo "Testing Lexer"
	@v test ./src/lexer

test-parser: 
	@echo "Testing Parser"
	@v test ./src/parser

fmt: 
	@v fmt -w ./
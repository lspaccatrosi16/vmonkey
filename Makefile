build: 
	@v -o dist/vmonkey ./

run: build 
	@./dist/vmonkey

test: test_lexer test_parser

test_lexer: 
	@echo "Testing Lexer"
	@v test ./src/lexer

test_parser: 
	@echo "Testing Parser"
	@v test ./src/parser

fmt: 
	@v fmt -w ./
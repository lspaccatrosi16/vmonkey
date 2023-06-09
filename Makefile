build: 
	@v -o dist/vmonkey ./

run: build 
	@./dist/vmonkey

test: 
	@echo "Testing all"
	@v -stats test ./src/

test_lexer: 
	@echo "Testing Lexer"
	@v -stats test ./src/lexer/

test_parser: 
	@echo "Testing Parser"
	@v -stats test ./src/parser/ 

fmt: 
	@v fmt -w ./
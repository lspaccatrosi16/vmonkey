build: 
	@v -g -keepc -profile profile.txt -o dist/vmonkey ./

run: build 
	@./dist/vmonkey -s cache_v -track

test: 
	@echo "Testing all"
	@v -stats test ./src/

test_lexer: 
	@echo "Testing Lexer"
	@v -stats test ./src/lexer/

test_parser: 
	@echo "Testing Parser"
	@v -stats test ./src/parser/ 

test_evaluator:
	@echo "Testing Evaluator"
	@v -stats test ./src/evaluator/

fmt: 
	@v fmt -w ./
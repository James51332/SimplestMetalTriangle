.SILENT:
build:
	clang++ -o MetalTriangle Main.mm -framework Cocoa -framework Metal -framework Metalkit -std=c++17

run:
	./MetalTriangle
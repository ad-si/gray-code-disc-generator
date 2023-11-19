example.svg: source/cli.ts source/index.ts
	bun $< --resolution 10 > $@

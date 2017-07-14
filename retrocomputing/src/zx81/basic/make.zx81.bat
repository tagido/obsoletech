REM download zxtext2p from http://freestuff.grok.co.uk/zxtext2p/index.html

@echo ### Building fernando pessoa [ZX81]


@set ZX81_BASIC_COMPILER="D:\Program Files (x86)\Zx\ZX81\zxtext2p\zxtext2p.exe"

%ZX81_BASIC_COMPILER% -o tape\fernando_pessoa.zx81.p fernando_pessoa.zx81.bas
1 REM Created with OBSOLETECH Text Compiler from text file
2 REM   This program is free software; you can redistribute it and/or modify
3 REM   it under the terms of the GNU General Public License as published by
4 REM   the Free Software Foundation; either version 2 of the License, or
5 REM   (at your option) any later version.
50  LET NLINES=35
100 DIM T$(NLINES,210)
1000 LET T$(1) = "Fernando Pessoa"
1001 LET T$(2) = "Poems"
1002 LET T$(3) = "To be great, be whole"
1003 LET T$(4) = "Exclude nothing, exaggerate nothing that is not you."
1004 LET T$(5) = "Be whole in everything. Put all you are"
1005 LET T$(6) = "Into the smallest thing you do."
1006 LET T$(7) = "So, in each lake, the moon shines with splendor"
1007 LET T$(8) = "Because it blooms up above."
1008 LET T$(9) = "If after I die, people want to write my biography, "
1009 LET T$(10) = "there is nothing simpler. "
1010 LET T$(11) = "They only need two dates: "
1011 LET T$(12) = "the date of my birth and the date of my death. "
1012 LET T$(13) = "Between one and another, every day is mine."
1013 LET T$(14) = "But I am not perfect in my way of putting things"
1014 LET T$(15) = "Because I lack the divine simplicity"
1015 LET T$(16) = "Of being only what I appear to be."
1016 LET T$(17) = "To be understood is to prostitute oneself"
1017 LET T$(18) = "Without madness what is man"
1018 LET T$(19) = "But a wholesome beast,"
1019 LET T$(20) = "Postponed corpse that begets?"
1020 LET T$(21) = "Lord, may the pain be ours, And the weakness that it brings, "
1021 LET T$(22) = "But at least give us the strength, Of not showing it to anyone"
1022 LET T$(23) = "This world is for those who are born to conquer it,"
1023 LET T$(24) = "Not for those who dream that are able to conquer it, "
1024 LET T$(25) = "even if theyre right."
1025 LET T$(26) = "Again I see you, But me I dont see, "
1026 LET T$(27) = "The magical mirror in which I saw myself has been broken, "
1027 LET T$(28) = "And only a piece of me I see in each fatal fragment "
1028 LET T$(29) = "Only a piece of you and me..."
1029 LET T$(30) = "Isnt joyful or painful this pain in which I rejoice"
1030 LET T$(31) = "Theres a non-existent peace in the uncertain quietness"
1031 LET T$(32) = "Give me some more wine, because life is nothing"
1032 LET T$(33) = "I believe in the World as in a daisy."
1033 LET T$(34) = "Because I see it. But I dont think about it"
1034 LET T$(35) = "Because thinking is not understanding... "
2000 REM Passa livro
2010 FOR I=1 TO NLINES
2015 CLS
2020 PRINT T$(I)
2025 PAUSE 250
2030 NEXT I
2100 GOTO 2000

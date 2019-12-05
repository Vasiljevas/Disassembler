# Disassembler
Programa, kuri mašininį kodą paverčia į assembler'io komandas, spausdina "emu8086" būdu. Daugiau informacijos žemiau:

Disasembleris - tai programa, daranti priešingą operaciją, negu asemblerio kompiliatorius: verčianti mašininį kodą į assemblerio kalbą. Pavyzdžiui, sukompiliavus komandą „MOV cl, bh“, gaunami du baitai „8A CF“. Taigi disasembleris perskaitęs du baitus, kurių reikšmės „8A CF“, turėtų išsiaiškinti, kad tai komanda MOV, kad naudojami baitiniai registrai cl ir bh, o priskyrimas vyksta į registrą cl. Reikėtų pažymėti, kad komandos gali būti tiek dviejų baitų (kaip pastarajame pavyzdyje), tiek vieno, trijų, keturių, penkių ar šešių baitų. Nustatyti, kokio ilgio bus kita komanda, galima tik tą komandą nuskaičius ir atpažinus. Pavyzdžiui, komandos „CMP [bx+0105], 0804“ mašininis kodas yra toks: „81 BF 05 01 04 08“. Perskaitęs pirmąjį baitą, „81“, disasembleris galės pasakyti tik tiek, kad tai yra komanda kuri turi betarpišką operandą, kuris yra dviejų baitų. Ir tik perskaitęs kitą baitą, „BF“, jis galės apskaičiuoti visą komandos dydį: 6 baitai (1 baitas („81“) + 1 baitas („BF“) + 2 baitai (poslinkis adreso formavimui) + 2 baitai (betarpiškas operandas)).
    Tiesa, norint atsiskaityti disasemblerį, nebūtina, kad jis mokėtų atpažinti visas Intel 8086 procesoriaus komandas, užteks pačių pagrindinių. Taip pat nebūtina „suprasti“ exe formato failų - užteks žymiai paprastesnio com formato.
 
 Reikalavimai disasembleriui:
Paleidus disasemblerį su argumentu "/?", jis turi išmesti aprašą: 
atsiskaitančiojo vardas, pavardė, kursas, grupė, trumpas programos aprašymas.
Visi parametrai disasembleriui turi būti paduodami komandine eilute,
o ne prašant juos įvesti iš klaviatūros. Pvz.: disasm prog.com prog.asm.
Disasemblerio rezultatas turi būti išvedamas į failą.
Jeigu disasembleris paleistas be parametrų arba parametrai nekorektiški, reikia atspausdinti pagalbos pranešimą tokį patį, kaip paleidus disasemblerį su parametru "/?".
Disasembleris turi apdoroti įvedimo išvedimo (ir kitokias) klaidas.
Pavyzdžiui, nustačius, kad nurodytas failas neegzistuoja - jis turi išvesti pagalbos pranešimą ir baigti darbą.
Failų skaitymo ar rašymo buferio dydis turi būti nemažesnis už 10 baitų.
Failo dydis gali viršyti skaitymo ar rašymo buferio dydį.
Su programa turi būti pateikiamas testinis com failas ir jo kodas asm faile.
Rezultatų faile turi būti išvedama poslinkis nuo kodo segmento pradžios, komandos mašininis kodas ir pati komanda. 
Turėkite omenyje, kad pirmoji komanda com faile yra su poslinkiu 100h nuo segmento pradžios.
Turi būti suprantamos ir disasembliuojamos šios komandos:
Segmento keitimo prefiksas;
Visi MOV variantai (6);
Visi PUSH variantai (3);
Visi POP variantai (3);
Visi ADD variantai (3);
Visi INC variantai (2);
Visi SUB variantai (3);
Visi DEC variantai (2);
Visi CMP variantai (3);
Komanda MUL;
Komanda DIV;
Visi CALL variantai (4);
Visi RET variantai (4);
Visi JMP variantai (5);
Visos sąlyginio valdymo perdavimo komandos (17);
Komanda LOOP;
Komanda INT;
Jei nuskaičius baitą nesugebama jo atpažinti, reikia jį praleisti (apie tai pažymint rezultatų faile)
ir bandyti atpažinti po jo einantį baitą;

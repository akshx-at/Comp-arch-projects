.section .text
.globl _start
_start:

    # Load the base address into x1
    lui x1, 0x1eceb          # Load upper 20 bits into x1
    addi x1, x1, 0x100        # Add lower 12 bits to x1

    lui x13, 0x869EA
    lui x24, 0xC3F07
    sub x23, x9, x29
    rem x1, x7, x2
    lui x22, 0xA7875
    rem x19, x8, x29
    mulh x29, x24, x24
    lui x9, 0xEB3C5
    remu x1, x30, x25
    divu x15, x8, x1
    slli x26, x24, 30
    lh x27, -1682(x1)
    addi x19, x14, 168
    srli x28, x16, 31
    lbu x27, -1586(x1)
    slti x12, x17, -854
    sltiu x17, x13, 1176
    lui x27, 0xF66ED
    andi x16, x15, 962
    mul x23, x9, x15
    lui x28, 0xCF0F2
    rem x17, x4, x21
    srli x17, x8, 21
    rem x12, x12, x21
    mulhu x24, x24, x13
    srl x31, x28, x8
    div x17, x19, x20
    srai x13, x23, 4
    lhu x9, -794(x1)
    lhu x22, -770(x1)
    lui x28, 0x82045
    lui x14, 0x28FC2
    mul x25, x27, x15
    mulhu x29, x3, x14
    slt x26, x2, x14
    lh x18, -418(x1)
    srai x2, x30, 29
    mul x23, x17, x29
    remu x30, x19, x27
    srli x30, x27, 3
    lui x14, 0xFC89C
    remu x30, x18, x14
    slt x1, x13, x0
    slli x4, x24, 31
    slti x4, x22, -508
    sltiu x12, x3, 1905
    lhu x9, 452(x1)
    andi x4, x8, -325
    sll x23, x23, x31
    rem x14, x24, x23
    divu x18, x2, x7
    srli x16, x30, 12
    divu x28, x22, x24
    div x16, x29, x9
    srai x24, x31, 29
    srli x1, x22, 25
    xor x4, x26, x1
    andi x16, x0, -404
    srai x24, x15, 25
    addi x18, x23, -1727
    xori x31, x0, -1966
    addi x3, x14, -775
    rem x23, x2, x12
    srai x6, x22, 10
    srai x28, x26, 0
    sll x30, x21, x23
    mulhsu x21, x29, x14
    ori x30, x13, -2041
    add x14, x18, x16
    mulhsu x22, x14, x7
    divu x15, x15, x18
    remu x7, x1, x29
    xori x20, x23, 1834
    addi x26, x0, 87
    sltiu x13, x26, 88
    lui x4, 0x6C824
    lui x15, 0x321F0
    mul x29, x30, x25
    lhu x18, -1710(x1)
    lh x29, 1342(x1)
    srli x16, x13, 1
    sltu x7, x8, x19
    lui x6, 0xCC357
    srli x7, x13, 10
    xori x27, x27, -1462
    lw x6, -1700(x1)
    lui x28, 0x1A852
    lui x26, 0x63EF4
    mul x8, x18, x13
    lui x24, 0x4E1CF
    div x14, x15, x6
    lui x13, 0x4B0A7
    lb x9, 1388(x1)
    lui x4, 0x7CCED
    lui x21, 0xD31D8
    or x21, x14, x20
    and x1, x23, x16
    lw x4, 1524(x1)
    div x18, x6, x3
    lh x4, -850(x1)
    sltu x4, x16, x22
    add x18, x30, x8
    sltu x8, x13, x28
    srli x22, x3, 1
    lbu x30, -1311(x1)
    mulh x12, x4, x31
    divu x1, x23, x6
    lh x21, -1110(x1)
    srli x29, x3, 26
    lh x27, -1048(x1)
    lw x19, 436(x1)
    lui x23, 0x7B301
    srai x16, x30, 3
    lui x30, 0xF1B38
    lui x8, 0x60768
    lui x31, 0x3E5A9
    div x18, x20, x4
    lh x14, 1684(x1)
    lui x30, 0xA6845
    slli x18, x12, 7
    sll x6, x0, x24
    lui x6, 0xCDBEE
    srl x13, x2, x3
    srli x23, x17, 7
    lhu x24, -1378(x1)
    mulhsu x27, x25, x2
    lhu x22, -1958(x1)
    mulhu x13, x9, x22
    lui x4, 0xE292B
    lui x17, 0xC8147
    lw x13, -472(x1)
    and x27, x22, x12
    srai x12, x26, 7
    lui x27, 0x6BB6D
    xori x14, x20, 1012
    remu x24, x31, x4
    lui x4, 0x81E17
    lui x3, 0x8B90E
    lui x22, 0xB8A75
    lui x16, 0xA8DF9
    lw x9, -1004(x1)
    mulhu x13, x9, x3
    mulhu x26, x9, x30
    slt x1, x29, x3
    andi x15, x22, 1009
    lui x8, 0xA77D2
    sra x30, x28, x31
    lh x9, -1986(x1)
    slli x28, x7, 13
    srli x25, x23, 19
    lui x1, 0x7B315
    mulhu x27, x4, x4
    lw x31, -768(x1)
    lui x8, 0xD5A93
    mulhsu x17, x21, x9
    add x20, x26, x7
    lui x23, 0x5274A
    ori x8, x17, 1686
    srai x6, x9, 23
    mul x6, x12, x31
    andi x31, x26, -537
    lhu x30, -42(x1)
    lhu x22, 1808(x1)
    lui x22, 0xF04FE
    remu x14, x6, x19
    mulhsu x6, x16, x4
    lh x19, -1420(x1)
    lui x16, 0xACE7F
    lh x22, 46(x1)
    divu x25, x8, x0
    sra x8, x18, x30
    lui x19, 0xE4398
    lh x20, -1438(x1)
    lui x4, 0xCB54D
    sra x14, x12, x26
    lui x16, 0x5C382
    lui x19, 0xB72CD
    srai x14, x12, 26
    mulhu x30, x1, x12
    rem x25, x25, x23
    sltiu x1, x24, 830
    lbu x8, 1650(x1)
    slt x3, x31, x4
    mulhsu x26, x25, x13
    lb x18, -925(x1)
    srli x19, x9, 5
    lw x13, 1952(x1)
    lb x29, 391(x1)
    sltiu x4, x29, 1147
    srli x4, x31, 14
    rem x17, x27, x6
    xori x24, x19, 1629
    xor x2, x15, x7
    addi x26, x16, -1896
    lui x6, 0x2194B
    mulhu x29, x1, x16
    lui x14, 0xC0713
    lui x9, 0x45479
    remu x16, x4, x18
    or x31, x14, x14
    lw x18, 1756(x1)
    xor x18, x16, x18
    lui x15, 0xD2BB0
    mul x17, x12, x28
    sltiu x15, x17, -1484
    sll x29, x23, x27
    lw x14, -128(x1)
    remu x3, x22, x20
    div x25, x31, x30
    rem x20, x3, x12
    lb x23, -877(x1)
    lui x25, 0xD71F3
    lw x21, 936(x1)
    andi x9, x25, 1689
    lb x6, 633(x1)
    lh x20, -734(x1)
    lb x9, -731(x1)
    mulh x26, x6, x27
    srai x15, x14, 10
    sltiu x4, x22, 1125
    lw x20, 1940(x1)
    lui x1, 0xAE4F9
    lbu x31, 1636(x1)
    mul x8, x3, x26
    srai x29, x12, 1
    div x7, x17, x3
    lui x25, 0xFF9D9
    mulhu x15, x3, x16
    lui x25, 0x6D7F2
    slli x22, x15, 7
    mulhsu x12, x9, x27
    lw x30, -1920(x1)
    lhu x21, 446(x1)
    lh x18, 744(x1)
    lh x30, 132(x1)
    lui x21, 0x939DB
    lbu x26, 229(x1)
    lui x26, 0x69BF0
    andi x24, x17, -570
    lui x8, 0x523C2
    or x3, x4, x2
    or x20, x30, x4
    lbu x30, 1971(x1)
    mulhsu x30, x0, x17
    rem x31, x20, x28
    lui x27, 0x1073D
    sltu x21, x24, x16
    mulh x22, x13, x19
    lhu x14, 728(x1)
    lh x25, 624(x1)
    xori x15, x9, 1695
    divu x2, x4, x15
    ori x9, x0, 257
    addi x16, x29, 263
    lh x13, -974(x1)
    andi x28, x30, -1319
    lbu x12, 1012(x1)
    or x20, x23, x1
    lui x17, 0x9577B
    lw x9, -928(x1)
    mulhsu x2, x8, x8
    remu x7, x14, x12
    sltu x28, x1, x21
    lb x17, 954(x1)
    lui x4, 0x6642B
    remu x22, x31, x31
    lui x4, 0x39C74
    xori x12, x18, -1140
    mulhsu x20, x19, x24
    lui x25, 0xC63FB
    lui x27, 0xB4C5B
    srl x19, x3, x2
    xori x22, x16, 900
    lui x24, 0x19A10
    lw x17, -160(x1)
    xor x1, x6, x15
    div x6, x7, x22
    lw x17, 1056(x1)
    lb x30, 921(x1)
    lw x31, 364(x1)
    lb x13, -590(x1)
    sltiu x28, x0, -1276
    lui x21, 0x9073A
    lb x13, -1479(x1)
    lui x4, 0xA05F1
    lui x6, 0x24CE7
    mulh x22, x4, x2
    srl x25, x29, x28
    lb x16, 282(x1)
    add x17, x3, x31
    lui x22, 0xF1E58
    lui x23, 0xB0A0
    remu x2, x3, x4
    ori x12, x3, 1442
    lbu x16, -1256(x1)
    srli x7, x22, 19
    xor x16, x22, x1
    xori x6, x19, -1432
    sub x24, x30, x4
    sra x17, x26, x3
    lui x15, 0xCC8F9
    sltiu x18, x16, -73
    lui x29, 0xF91DE
    lb x16, -217(x1)
    xori x28, x26, 739
    lb x7, 891(x1)
    mulh x18, x7, x2
    xori x24, x6, 991
    lui x27, 0x843A6
    slti x3, x8, -835
    srl x16, x9, x28
    sltiu x22, x25, 426
    addi x28, x20, -1216
    lui x9, 0x405E8
    lui x30, 0xF929A
    lui x22, 0x417EA
    lui x16, 0x7A8AD
    srai x22, x1, 14
    and x6, x21, x21
    srli x30, x13, 3
    xori x24, x23, -887
    mulh x31, x30, x28
    lh x12, -572(x1)
    lbu x1, 931(x1)
    lh x13, -1330(x1)
    lui x15, 0xFFDC2
    sra x24, x3, x3
    remu x13, x6, x25
    lui x20, 0x6BE4D
    lb x13, 349(x1)
    srli x2, x6, 24
    mulhu x24, x15, x24
    lui x29, 0x812E5
    lui x23, 0x31586
    srli x22, x13, 23
    xori x23, x30, -532
    lui x27, 0xD20BB
    andi x30, x31, 2045
    lui x25, 0x16BC6
    lui x20, 0x2F7CE
    sll x2, x12, x20
    srli x9, x2, 27
    lui x7, 0xC8CCF
    sltiu x31, x19, -625
    srai x30, x15, 21
    lui x14, 0x82FB3
    lb x4, -31(x1)
    slt x3, x20, x16
    mulh x26, x24, x6
    lhu x23, 900(x1)
    sltu x30, x20, x30
    sll x17, x2, x26
    mulhsu x21, x14, x28
    lhu x24, 610(x1)
    sll x29, x28, x22
    slt x17, x19, x26
    xor x30, x8, x21
    lui x29, 0xD4E44
    remu x23, x8, x15
    sub x3, x8, x3
    rem x8, x24, x22
    sltu x7, x28, x28
    lh x21, 902(x1)
    sltu x6, x25, x30
    mulhsu x20, x21, x9
    lui x1, 0xC6528
    srli x21, x15, 3
    srl x2, x0, x0
    sra x13, x7, x26
    mulhu x4, x30, x16
    remu x21, x20, x28
    lb x23, -1855(x1)
    xori x1, x13, -163
    sltu x31, x3, x2
    srli x9, x7, 24
    sltu x28, x29, x0
    lh x19, 546(x1)
    and x19, x29, x8
    lui x7, 0x24134
    sub x3, x13, x21
    lb x12, 395(x1)
    andi x27, x15, -1615
    lb x21, 1319(x1)
    and x2, x2, x22
    div x9, x13, x22
    lui x4, 0xE18E9
    lui x9, 0xB8107
    slt x24, x0, x9
    mulhu x13, x20, x19
    add x30, x20, x8
    add x30, x8, x1
    lh x16, -358(x1)
    andi x16, x17, 952
    lui x8, 0xA70D
    div x23, x18, x27
    lui x21, 0x90AE7
    mul x15, x30, x2
    lb x20, 632(x1)
    lb x30, 1951(x1)
    slti x30, x12, -1771
    slti x2, x30, -541
    xori x7, x6, 1758
    lhu x6, 768(x1)
    slt x15, x6, x13
    lui x25, 0x329FE
    lui x22, 0xBD2E
    lh x23, -48(x1)
    mulhsu x23, x23, x4
    mulhsu x21, x31, x22
    lw x4, -1620(x1)
    slli x2, x23, 3
    sltiu x9, x15, -890
    slt x1, x12, x28
    srli x30, x6, 2
    div x6, x14, x30
    rem x14, x6, x22
    remu x9, x27, x3
    mul x8, x3, x7
    lui x19, 0x48282
    rem x31, x21, x14
    addi x6, x30, 255
    lbu x3, 1531(x1)
    div x18, x30, x13
    ori x31, x23, 1999
    srli x27, x3, 31
    or x21, x21, x14
    mulhu x20, x21, x1
    lui x19, 0xCED9C
    sra x22, x0, x6
    rem x19, x0, x19
    lhu x8, -1352(x1)
    sltiu x29, x24, -631
    lbu x29, -1748(x1)
    sll x25, x15, x1
    lui x20, 0xC18F5
    addi x20, x30, -111
    sltu x18, x29, x13
    mulhu x12, x7, x17
    andi x31, x23, 1440
    lb x18, 1690(x1)
    lui x25, 0xF3C79
    rem x4, x23, x31
    lui x23, 0xAA8A1
    lh x4, -964(x1)
    andi x31, x13, 128
    lb x29, 1750(x1)
    lui x23, 0x53DA4
    lui x17, 0x73D76
    divu x7, x3, x17
    lui x29, 0xB0FEB
    lui x9, 0x821FD
    lhu x12, -190(x1)
    addi x27, x2, 1903
    andi x26, x19, -723
    lui x14, 0xA50AF
    lh x12, 1364(x1)
    divu x6, x27, x25
    lb x1, -1366(x1)
    or x21, x21, x16
    lui x23, 0xBCBB
    lui x22, 0x9FF20
    add x31, x29, x31
    lhu x27, -328(x1)
    xor x14, x9, x2
    div x7, x17, x2
    lui x27, 0x9A2E7
    lh x21, -436(x1)
    addi x8, x24, 399
    lui x20, 0xF6272
    lui x13, 0xADBA2
    srai x20, x20, 23
    lbu x25, 970(x1)
    lhu x24, -538(x1)
    lbu x24, 1653(x1)
    sltiu x8, x6, -1740
    lui x20, 0x517BD
    xori x24, x18, 738
    divu x22, x4, x1
    mulhu x31, x1, x16
    mulh x17, x28, x27
    add x4, x4, x9
    slt x8, x7, x19
    and x29, x12, x17
    mul x19, x8, x6
    mulhsu x22, x0, x6
    andi x18, x14, 1614
    sltu x7, x1, x0
    rem x19, x7, x24
    srai x24, x27, 23
    slli x30, x29, 25
    lw x4, 516(x1)
    lw x25, 1636(x1)
    sltiu x26, x1, -1000
    xor x7, x4, x17
    lbu x27, 967(x1)
    lui x28, 0xC32BB
    ori x30, x13, -726
    lhu x6, 1270(x1)
    lui x9, 0x3C870
    addi x2, x24, -1135
    lbu x21, 1812(x1)
    mul x18, x4, x3
    lui x4, 0xC2AE0
    srai x23, x24, 16
    mul x8, x19, x30
    srl x2, x4, x19
    remu x31, x24, x1
    lw x15, -932(x1)
    lbu x20, -694(x1)
    slt x7, x15, x24
    lui x19, 0x7DC03
    sltu x12, x28, x13
    or x7, x2, x31
    div x23, x27, x26
    lw x13, -700(x1)
    mulhu x18, x20, x21
    lb x27, 1820(x1)
    sltu x8, x27, x27
    ori x25, x26, -552
    lhu x24, 1436(x1)
    and x26, x29, x2
    divu x19, x28, x0
    mulhu x13, x0, x22
    ori x16, x13, 1898
    srl x9, x24, x26
    slt x1, x22, x22
    slli x20, x15, 25
    lw x30, 228(x1)
    mulhu x26, x27, x21
    addi x19, x9, 609
    srli x27, x19, 27
    lhu x28, -1116(x1)
    slt x29, x15, x4
    lui x6, 0x404C
    mulhu x24, x26, x18
    sltiu x2, x21, -1743
    lh x14, -1330(x1)
    lui x29, 0xC47B7
    remu x27, x26, x14
    lb x2, 426(x1)
    slli x13, x4, 17
    lb x16, 1235(x1)
    lui x29, 0xE7CA0
    div x6, x30, x16
    slti x24, x20, 925
    div x14, x16, x14
    lui x1, 0xDB4CF
    lh x30, 338(x1)
    lui x14, 0xDA71F
    ori x15, x0, 828
    sub x16, x2, x1
    lui x18, 0xCDF2E
    srl x19, x29, x21
    lui x8, 0x2088C
    srai x30, x19, 6
    mulh x2, x29, x29
    lbu x17, -1666(x1)
    remu x12, x29, x4
    lui x24, 0x17227
    and x18, x9, x8
    sltiu x6, x3, 1382
    lb x22, -1878(x1)
    lui x3, 0xB128
    lui x22, 0x51B3A
    xori x14, x0, -1789
    lb x31, -845(x1)
    lui x6, 0x72F9C
    ori x28, x18, -261
    lw x16, 1812(x1)
    or x9, x1, x22
    lbu x16, 911(x1)
    srl x16, x18, x9
    lui x21, 0x6E651
    and x18, x30, x13
    andi x19, x23, 750
    xor x25, x27, x8
    mulh x27, x23, x12
    addi x24, x12, -305
    lui x16, 0xCEBF3
    lw x16, -1924(x1)
    sra x26, x1, x30
    lui x2, 0xDFEB3
    sltiu x19, x16, 1742
    mulhu x6, x15, x20
    slti x22, x28, -1739
    mulh x25, x19, x22
    sra x12, x17, x22
    add x26, x19, x1
    div x2, x19, x17
    and x13, x27, x12
    lw x29, 408(x1)
    mulhsu x29, x24, x21
    lui x16, 0x595A2
    srai x1, x19, 29
    lw x29, 688(x1)
    divu x15, x4, x0
    mulhsu x9, x6, x18
    srai x8, x19, 10
    ori x7, x9, 515
    rem x29, x19, x22
    lui x19, 0xA046E
    lui x26, 0x81960
    and x26, x0, x27
    lui x21, 0x4C632
    xor x17, x14, x1
    div x6, x27, x23
    mulhsu x29, x1, x18
    srli x16, x19, 13
    sll x12, x19, x25
    lhu x28, -298(x1)
    mulh x20, x4, x9
    lw x19, 1160(x1)
    ori x18, x23, 425
    sltu x25, x1, x23
    sub x31, x24, x27
    mulh x31, x14, x22
    divu x1, x13, x7
    lui x9, 0xC118A
    srai x9, x28, 7
    remu x27, x21, x15
    lui x19, 0x70619
    lui x17, 0x887DC
    or x9, x27, x0
    xori x23, x22, -1759
    slt x15, x21, x28
    lw x4, 1832(x1)
    lhu x1, -1006(x1)
    lui x8, 0x1AE1C
    and x7, x4, x31
    ori x15, x2, 1576
    xor x27, x4, x30
    mulhsu x28, x30, x3
    lui x21, 0x8F420
    slti x2, x31, 53
    lbu x1, 1129(x1)
    lui x27, 0x8E12
    slt x19, x0, x9
    lui x19, 0x9ECD1
    lhu x16, 1248(x1)
    divu x13, x1, x12
    lb x31, -1851(x1)
    sll x9, x6, x20
    slt x2, x25, x9
    sll x23, x0, x3
    lh x28, -430(x1)
    remu x2, x28, x20
    lw x1, -752(x1)
    addi x1, x18, -528
    lb x30, 1739(x1)
    lui x1, 0x1221B
    rem x8, x6, x18
    sub x26, x21, x15
    lw x8, 244(x1)
    sltiu x15, x28, 162
    lw x13, -1968(x1)
    ori x27, x27, 1453
    lui x24, 0x32FFD
    lui x8, 0x1A011
    srai x1, x8, 16
    sra x17, x30, x31
    lw x18, 1560(x1)
    ori x7, x13, -433
    mul x9, x21, x23
    lui x12, 0x4B9AE
    slt x3, x8, x15
    lh x28, 1404(x1)
    mulhu x2, x9, x2
    slt x22, x21, x6
    slt x13, x15, x24
    srl x24, x1, x31
    lb x16, 1127(x1)
    sra x20, x23, x24
    mulh x6, x12, x2
    lui x17, 0x743BE
    rem x22, x30, x2
    sub x19, x9, x6
    lui x30, 0x2424F
    lui x28, 0x51C43
    lbu x13, -155(x1)
    slli x16, x12, 7
    slt x20, x19, x25
    and x12, x8, x3
    lw x14, 532(x1)
    div x12, x13, x20
    sltiu x4, x30, 668
    mulh x14, x18, x22
    add x29, x3, x16
    lw x7, -1104(x1)
    sltiu x27, x27, 1854
    lui x9, 0xB7D0F
    sra x15, x22, x21
    xor x26, x19, x20
    sra x23, x25, x4
    rem x18, x25, x29
    lui x13, 0xBC6D0
    lb x2, -1508(x1)
    mulhu x16, x27, x13
    sll x3, x9, x8
    srli x25, x19, 15
    mulhsu x7, x12, x16
    lh x29, 1340(x1)
    mul x27, x3, x23
    xori x24, x0, 214
    div x23, x1, x16
    lbu x20, 1712(x1)
    or x15, x29, x3
    lui x18, 0xC5553
    remu x21, x4, x15
    lui x17, 0xE4EE9
    xori x1, x15, 58
    mulhsu x16, x25, x13
    slti x17, x0, 1029
    andi x30, x20, 1445
    lui x1, 0xF65D9
    slt x20, x7, x7
    ori x6, x16, -251
    sub x12, x0, x14
    lui x20, 0xD1EDC
    lw x17, -280(x1)
    div x21, x30, x16
    lui x28, 0x41DBC
    div x14, x4, x14
    mul x12, x25, x18
    div x7, x19, x8
    mul x9, x24, x8
    sltu x4, x26, x7
    mulhsu x25, x18, x15
    lui x23, 0x5EA57
    lbu x28, -683(x1)
    div x28, x8, x6
    lui x25, 0xEB28A
    lui x25, 0x84AF4
    slti x31, x19, -927
    lhu x17, 984(x1)
    add x24, x2, x1
    srli x13, x12, 17
    lh x20, 1420(x1)
    lui x18, 0xFFC67
    add x3, x26, x7
    mulh x3, x26, x6
    srl x25, x0, x17
    lui x16, 0x9AEA0
    mul x30, x22, x9
    andi x6, x4, 1649
    mulh x25, x15, x12
    or x14, x6, x25
    srai x29, x7, 17
    or x25, x15, x16
    srl x1, x27, x9
    lw x7, -1556(x1)
    lh x1, 804(x1)
    lui x28, 0x72DA3
    lui x18, 0x24410
    lui x31, 0x80DDF
    lui x29, 0xBAD78
    srl x25, x0, x18
    rem x23, x18, x19
    lh x6, -654(x1)
    rem x20, x17, x20
    rem x18, x3, x26
    sra x6, x1, x25
    div x24, x29, x16
    mulhsu x7, x0, x1
    lui x12, 0xE09B2
    divu x22, x6, x13
    divu x28, x30, x25
    lui x3, 0xD9F81
    lw x17, -1828(x1)
    rem x2, x18, x4
    lui x18, 0xE1C29
    srl x18, x30, x19
    xor x2, x19, x26
    lb x12, 1257(x1)
    div x26, x0, x13
    lw x13, -776(x1)
    andi x1, x18, -1318
    lb x17, -2029(x1)
    slti x27, x25, -1188
    lui x27, 0x58C77
    lw x27, -1176(x1)
    sltiu x6, x25, 516
    divu x29, x18, x30
    div x17, x21, x13
    lbu x29, 1761(x1)
    mulhsu x21, x13, x20
    rem x22, x19, x24
    lw x1, 1576(x1)
    lui x31, 0x51473
    lui x12, 0x75B3
    divu x22, x8, x16
    remu x21, x7, x20
    rem x22, x26, x7
    mulhsu x15, x6, x12
    sra x24, x28, x8
    lhu x26, -274(x1)
    sltu x15, x22, x13
    mulhu x30, x0, x1
    mulh x21, x22, x4
    lw x22, -2000(x1)
    lui x13, 0xC1A44
    sub x19, x12, x4
    lw x22, -1756(x1)
    lui x8, 0xE7317
    xori x25, x27, -7
    lhu x13, -184(x1)
    sltu x15, x6, x14
    mulhsu x7, x22, x23
    lui x16, 0x9A8D2
    srl x19, x26, x15
    sll x21, x24, x31
    lui x17, 0xD9394
    lui x31, 0xA3B5F
    andi x2, x23, -905
    lui x21, 0x98C4E
    lui x8, 0x56131
    andi x16, x25, -460
    div x14, x0, x16
    lb x24, -1774(x1)
    remu x4, x20, x9
    lui x20, 0x92117
    lui x16, 0xD338D
    srl x7, x0, x30
    srai x28, x30, 21
    lbu x6, -1232(x1)
    lui x2, 0x8F7C6
    lui x4, 0xC33EB
    sub x3, x27, x30
    div x9, x13, x12
    sra x8, x14, x30
    lbu x7, -1149(x1)
    lui x24, 0x4FF5C
    remu x12, x14, x23
    addi x28, x4, -643
    add x7, x27, x22
    mul x19, x20, x0
    mulhu x4, x23, x24
    lbu x21, 1328(x1)
    sub x25, x31, x0
    slli x25, x4, 21
    mulhsu x1, x1, x23
    srl x19, x2, x8
    and x14, x15, x7
    lui x7, 0xA722B
    lw x17, -528(x1)
    xori x12, x15, 222
    lhu x30, 1492(x1)
    lhu x19, 1756(x1)
    mulhsu x31, x28, x21
    div x1, x19, x31
    slli x2, x20, 23
    slt x30, x30, x4
    srl x19, x8, x6
    lui x27, 0xDC6B7
    lbu x29, -1811(x1)
    lw x14, -68(x1)
    lui x29, 0xCF1BB
    sub x2, x26, x3
    slt x30, x21, x30
    slti x25, x24, -2002
    lh x28, 2014(x1)
    lui x22, 0xD005F
    lui x29, 0x557F1
    xori x30, x3, 784
    sra x2, x7, x6
    lui x8, 0x840AC
    mul x1, x7, x13
    rem x26, x16, x21
    lhu x20, -1820(x1)
    srai x15, x12, 13
    divu x25, x26, x4
    lbu x29, -1923(x1)
    addi x17, x8, 735
    mulhu x13, x2, x4
    lhu x4, 534(x1)
    lui x7, 0x46E5F
    mulhu x26, x24, x9
    slt x9, x9, x3
    srli x13, x31, 1
    lui x17, 0xCB91B
    lui x14, 0x7F0D7
    slli x26, x19, 15
    and x12, x31, x30
    srli x4, x30, 22
    lui x22, 0x535CD
    mulhu x28, x21, x13
    lui x23, 0x4D1DB
    mulhu x2, x6, x1
    sltu x17, x2, x26
    mulh x8, x25, x3
    lui x22, 0xDD6DC
    xor x16, x24, x29
    lb x19, 1957(x1)
    lbu x8, 547(x1)
    mulhu x28, x9, x0
    add x18, x20, x24
    lui x16, 0x5CB14
    mulh x17, x0, x18
    mulhu x25, x17, x13
    addi x17, x0, -1391
    lh x18, -1506(x1)
    lb x18, 826(x1)
    remu x16, x17, x9
    lw x23, -316(x1)
    lui x24, 0x2F4F2
    addi x17, x1, -618
    srli x4, x16, 28
    lui x25, 0x50558
    mul x23, x28, x8
    lh x27, 194(x1)
    xor x22, x26, x31
    xori x1, x17, 1862
    mul x22, x15, x21
    lbu x18, 870(x1)
    lui x26, 0x96D3F
    xor x23, x31, x7
    lui x15, 0x120F7
    or x23, x17, x19
    xori x26, x17, 394
    sra x23, x8, x24
    and x23, x2, x22
    lui x31, 0x8EEC9
    lui x7, 0x4BA48
    srl x9, x16, x25
    lui x29, 0x3B6D
    lhu x30, -1970(x1)
    lw x15, 568(x1)
    and x3, x28, x3
    srl x26, x8, x13
    divu x29, x6, x4
    addi x30, x7, 1600
    slt x30, x8, x20
    sub x24, x4, x25
    lui x7, 0x77A
    lh x9, -1510(x1)
    lb x14, -151(x1)
    srl x21, x25, x9
    sll x27, x17, x16
    sub x3, x1, x1
    xori x1, x29, 1703
    lui x15, 0xF1263
    lw x6, -1628(x1)
    mulhu x21, x9, x15
    xor x25, x20, x9
    slt x3, x28, x14
    slti x29, x30, -1004
    lui x1, 0x5A36C
    remu x4, x15, x28
    sltiu x20, x3, -1139
    xori x15, x4, -68
    andi x18, x26, -1031
    mulh x18, x28, x13
    lb x14, -1564(x1)
    lui x1, 0x20EB4
    sra x14, x19, x1
    lhu x22, 1006(x1)
    lb x30, 235(x1)
    andi x24, x31, 1006
    lb x28, -450(x1)
    mulh x2, x23, x29
    sltu x23, x2, x0
    lui x26, 0xD0325
    lui x17, 0x9D29C
    mulhu x30, x31, x7
    lui x21, 0x11DA4
    lui x30, 0xDC2A5
    lui x17, 0xC575E
    mulh x29, x15, x6
    xori x20, x31, 1506
    lh x23, -1506(x1)
    lui x12, 0xE06F0
    lw x21, -1120(x1)
    sra x30, x8, x29
    div x22, x26, x28
    lh x20, -408(x1)
    lui x9, 0x29266
    or x2, x31, x4
    lui x31, 0x455C9
    sll x29, x4, x21
    lbu x22, 1210(x1)
    div x29, x25, x22
    lui x28, 0x29EDE
    lw x16, -1124(x1)
    mulh x2, x16, x3
    slti x30, x31, 1838
    lui x22, 0x6B4CB
    slli x29, x21, 15
    ori x8, x27, -613
    lui x23, 0xC315C
    sub x23, x9, x23
    or x28, x8, x2
    addi x13, x24, 87
    mulh x3, x18, x21
    addi x26, x21, -1885
    slt x22, x31, x29
    remu x26, x8, x20
    lui x3, 0xA6DF
    lui x13, 0xD2937
    slti x1, x4, -1799
    or x9, x24, x23
    mulh x21, x18, x26

    # Magic instruction to end the simulation
    slti x0, x0, -256

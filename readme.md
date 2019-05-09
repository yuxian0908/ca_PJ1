## connect to workstation
1. use NTU vpn
2. `ssh b5701207@140.112.20.72`

## scp
1. `scp -r ./ALU b5701207@140.112.20.72:~/ `

## test ALU
```
1. source /usr/cadence/cshrc
2. ncverilog HW1_alu.v
3. ncverilog HW1_test_alu.v HW1_alu.v
```

## test MIPS
```
1. source /usr/cadence/cshrc
2. ncverilog MIPS_tb.v MIPS.v HSs18n_128x32.v +access+r
```
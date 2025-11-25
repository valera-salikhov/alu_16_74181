# alu_16_74181

## How to start testbench?
1. Install [Verilator](https://verilator.org/guide/latest/install.html)
2. `git clone https://github.com/valera-salikhov/alu_16_74181.git`
3. In project folder use:

   `verilator --cc rtl/74181.v rtl/74182_CLA.v rtl/top_alu_16.v --binary tb/tb_alu_16.sv -Wall --timing`

   (later will make a script to automate this)

4. `cd obj_dir`
5. `make -f V__0374181.mk V__0374181`  (maybe names of mk file will be different)
6. Execute the V__0374181.exe

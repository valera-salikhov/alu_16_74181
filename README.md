# alu_16_74181

## How to run testbench on Windows?
1. Install [Verilator](https://verilator.org/guide/latest/install.html) (I used [MSYS2](https://www.msys2.org/))
3. `git clone https://github.com/valera-salikhov/alu_16_74181.git`
4. In project folder use:

   `verilator --cc rtl/74181.v rtl/74182_CLA.v rtl/top_alu_16.v --binary tb/tb_alu_16.sv -Wall --timing`

   (later will make a script to automate this)

5. `cd obj_dir`
6. `make -f V__0374181.mk V__0374181`  (maybe names of mk file will be different)
7. Execute the V__0374181.exe

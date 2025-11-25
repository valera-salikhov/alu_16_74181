package alu_consts;

	localparam [3:0]
		ALU_ADD				= 4'b1001,
		ALU_SUB_OR_XOR						= 4'b0110,
		ALU_A_ADD_A_OR_LOGIC_1		= 4'b1100,		// change
		ALU_MINUS_1					= 4'b0011,
		ALU_AND						= 4'b1011,
		ALU_OR						= 4'b1110,
		ALU_NOT_A_AND_B				= 4'b0100;
		// ALU_XOR						= 4'b0101;
		
	localparam
		MODE_ARIFMETIC	= 1'b0,
		MODE_LOGIC		= 1'b1;
		
	localparam
		CARRY_IN_0	= 1'b0,
		CARRY_IN_1	= 1'b1;

endpackage

import alu_consts::*;


// ALU Interface definition
interface alu_intf (input logic clk);
	import alu_consts::*;

	/*
	input [15:0] a, b,
    input Cin, mode,
    input [3:0] sel,
    output [15:0] result,
    output Cout, nBo, nGo
	*/
	
	logic reset;
	logic [15:0] operand_a;
	logic [15:0] operand_b;
	logic mode;
	logic [3:0] opcode;
	logic [15:0] result;
	logic carry_in;
	logic carry_out;
	logic nBo, nGo;

	// Modport for DUT (inputs are driven by testbench)
	modport dut_mp (
		input clk,
		input reset,
		input operand_a,
		input operand_b,
		input mode,
		input opcode,
		input carry_in,
		
		output result,
		output carry_out,
		output nBo,
		output nGo
	);
	
	// Modport for testbench (inputs are received from DUT)
	modport tb_mp (
		input result,
		input carry_out,
		input nBo,
		input nGo,
		
		output reset,
		output operand_a,
		output operand_b,
		output mode,
		output opcode,
		output carry_in
	);
	
	
	task automatic compute_result(
    input [15:0] a,
    input [15:0] b,
	input mode,
	input [3:0] operation,
	input carry_in,
	
	output [15:0] compute_result,
	output carry_out
	);
	
    begin     
		case (mode)
			MODE_ARIFMETIC	: begin
				case (operation)
					ALU_ADD  : begin		
						{carry_out, compute_result} = a + b + ((~carry_in) & 1'b1);
						/*
						$display("a=%h, b=%h, a+b=%h, a + b + (~carry_in)=%h, carry_in=%h, ~carry_in=%h", 
							a, b, a + b, a + b + (~carry_in), carry_in, (~carry_in));
						*/
						carry_out = ~carry_out;
					end
					ALU_SUB_OR_XOR  : begin
						
						reg borrow = (~carry_in) & 1'b1;		// clear reg borrow, use only carry_in
						
						if (borrow == 1'b0) begin
							{carry_out, compute_result} = {1'b0, a} + {1'b0, ~b};
						end else begin
							{carry_out, compute_result} = {1'b0, a} + {1'b0, ~b} + 17'd1;
						end
						carry_out = ~carry_out;
						
					end
					ALU_A_ADD_A_OR_LOGIC_1   : begin
						{carry_out, compute_result} = a + a + ((~carry_in) & 1'b1);
						carry_out = ~carry_out;
					end
					ALU_MINUS_1  : begin
						if (carry_in == 1'b1) begin
							compute_result = 16'hFFFF;	// -1 в обратном коде
						end else begin
							compute_result = 16'h0000;
						end
						carry_out = 1'b1;				// need c_out = 1 ???
					end
			
					default: begin
						compute_result = 16'h0000;
						carry_out = 1'b1;
					end
				endcase
			end
			
			MODE_LOGIC	: begin
				case(operation)
				
					ALU_SUB_OR_XOR	: begin
						compute_result = a ^ b;
						// carry_out = 1'b1;
					end
					
					ALU_AND	: begin
						compute_result = a & b;
					end
					
					ALU_OR	: begin
						compute_result = a | b;
					end
					
					ALU_NOT_A_AND_B	: begin
						compute_result = ~(a & b);
					end
					/*
					ALU_A_ADD_A_OR_LOGIC_1	: begin
						compute_result = 16'h0001;
						// carry_out = 1'b1;
					end
					*/
					default: begin
						compute_result = 16'h0000;
						// carry_out = 1'b1;
					end
				endcase
			end
			
		endcase
		
        
    end
endtask
	
	

// Универсальная функция тестирования ALU
task automatic test_alu_operation(
	input [15:0] test_a,
	input [15:0] test_b,
	input test_mode,
	input [3:0] test_opcode,
	input test_carry_in
    );
    
	reg [15:0] expected_result;
	reg expected_carry_out;
	
	
	compute_result(test_a, test_b, test_mode, test_opcode, test_carry_in, expected_result, expected_carry_out);
	
	// #10
	
	// string status;
        
	// Устанавливаем входные сигналы
	operand_a <= test_a;   
	operand_b <= test_b;
	mode <= test_mode;
	opcode <= test_opcode;
	carry_in <= test_carry_in;
        
	// Ждем стабилизации результата (для комбинационной логики)
	#20;
        
	// Проверяем результат
	case (mode)
	
		MODE_ARIFMETIC : begin
			if (result == expected_result && carry_out == expected_carry_out) begin
				// status = "PASS";
				$display("PASS  ✓ %b: mode=%b, a=%h, b=%h, carry_in=%h -> result=%h, carry_out=%h (expected: result=%h, carry_out=%h)", 
					test_opcode, mode, test_a, test_b, test_carry_in, result, carry_out, expected_result, expected_carry_out);
			end else begin
				// status = "FAIL";
				$display("FAIL  ✗ %b: mode=%b, a=%h, b=%h, carry_in=%h -> result=%h, carry_out=%h (expected: result=%h, carry_out=%h)", 
					test_opcode, mode, test_a, test_b, test_carry_in, result, carry_out, expected_result, expected_carry_out);
			end
		end

		MODE_LOGIC : begin
			if (result == expected_result) begin
				// status = "PASS";
				$display("PASS  ✓ %b: mode=%b, a=%h, b=%h -> result=%h (expected: result=%h)", 
					test_opcode, mode, test_a, test_b, result, expected_result);
			end else begin
				// status = "FAIL";
				$display("FAIL  ✗ %b: mode=%b, a=%h, b=%h -> result=%h, (expected: result=%h)", 
					test_opcode, mode, test_a, test_b, result, expected_result);
			end
		end
		
	endcase
	// return status;
endtask
	
	
endinterface






// Main testbench module
module tb_alu_16();
	logic clk;
	
	// Interface instantiation
	alu_intf alu_if(clk);
	
	// DUT instantiation using interface
	// top_alu_16 dut (alu_if.dut_mp);
	
	top_alu_16 dut (
	// .clk(clk),
	// .reset(alu_if.reset),
	.a(alu_if.operand_a),
	.b(alu_if.operand_b),
	.mode(alu_if.mode),
	.sel(alu_if.opcode),
	.Cin(alu_if.carry_in),
	.result(alu_if.result),
	.Cout(alu_if.carry_out),
	.nBo(alu_if.nBo),
	.nGo(alu_if.nGo)
	);
	
	
	// Clock generation
	initial begin
		clk = 0;
		forever #5 clk = ~clk;
	end

	// Test controller
	initial begin
		initialize_test();
		run_tests();
		test_all_alu_functions();
		report_results();
		$finish;
	end


	// Helper tasks

	task initialize_test();
		alu_if.reset <= 1;
		alu_if.operand_a <= 0;
		alu_if.operand_b <= 0;
		alu_if.mode <= 0;
		alu_if.opcode <= 0;
		alu_if.carry_in <= 0;
		#20 alu_if.reset <= 0;
		$display("Test initialization completed");
	endtask

	task run_tests();
		test_add_operation();
		// ...
		test_and_operation();
		// ...
	endtask

	// Individual test tasks
	task test_add_operation();
		$display("Testing ADD operation...");
		alu_if.opcode <= 4'b1001; // ADD
		alu_if.operand_a <= 16'h0005;
		alu_if.operand_b <= 16'h0003;
		alu_if.mode <= 1'b0;
		alu_if.carry_in <= 0;
		#20;
		// ...
		if (alu_if.result != 16'h0008) begin
			$display("ERROR: ADD failed: expected=8 got=%h", alu_if.result);
		end else begin
			$display("ADD correct");
		end
		// end
	endtask

	task test_and_operation();
	$display("Testing AND operation...");
		alu_if.opcode <= 4'b0101; // AND
		alu_if.operand_a <= 16'h00FF;
		alu_if.operand_b <= 16'h0F0F;
		alu_if.mode <= 1'b1;
		// ...
		#20;
		if (alu_if.result != 16'h000F) begin
			$display("ERROR: AND failed: expected=F got=%h", alu_if.result);
		end else begin
			$display("AND correct");
		end
	endtask


	task test_all_alu_functions();
		// test ALU_SUM
		alu_if.test_alu_operation(16'h0001, 16'h0003, MODE_ARIFMETIC, ALU_ADD, CARRY_IN_0);
		alu_if.test_alu_operation(16'hFFFF, 16'h0001, MODE_ARIFMETIC, ALU_ADD, CARRY_IN_0);
		alu_if.test_alu_operation(16'h1234, 16'h4321, MODE_ARIFMETIC, ALU_ADD, CARRY_IN_1);
		
		// test ALU_SUB_OR_XOR
		alu_if.test_alu_operation(16'h0001, 16'h0003, MODE_ARIFMETIC, ALU_SUB_OR_XOR, CARRY_IN_0);
		alu_if.test_alu_operation(16'hFFFF, 16'h0001, MODE_ARIFMETIC, ALU_SUB_OR_XOR, CARRY_IN_0);
		alu_if.test_alu_operation(16'h1234, 16'h4321, MODE_ARIFMETIC, ALU_SUB_OR_XOR, CARRY_IN_1);
		
		
		// test ALU_A_ADD_A
		alu_if.test_alu_operation(16'h0001, 16'h0003, MODE_ARIFMETIC, ALU_A_ADD_A_OR_LOGIC_1, CARRY_IN_0);
		alu_if.test_alu_operation(16'hFFFF, 16'h0001, MODE_ARIFMETIC, ALU_A_ADD_A_OR_LOGIC_1, CARRY_IN_0);
		alu_if.test_alu_operation(16'h1234, 16'h4321, MODE_ARIFMETIC, ALU_A_ADD_A_OR_LOGIC_1, CARRY_IN_1);
		
		
		// test ALU_MINUS_1				why carry_out change somehow????
		alu_if.test_alu_operation(16'h0001, 16'h0003, MODE_ARIFMETIC, ALU_MINUS_1, CARRY_IN_0);
		alu_if.test_alu_operation(16'hFFFF, 16'h0001, MODE_ARIFMETIC, ALU_MINUS_1, CARRY_IN_0);
		alu_if.test_alu_operation(16'h1234, 16'h4321, MODE_ARIFMETIC, ALU_MINUS_1, CARRY_IN_1);
		
		// test ALU_XOR
		alu_if.test_alu_operation(16'h0001, 16'h0003, MODE_LOGIC, ALU_SUB_OR_XOR, CARRY_IN_0);
		alu_if.test_alu_operation(16'hFFFF, 16'h0001, MODE_LOGIC, ALU_SUB_OR_XOR, CARRY_IN_0);
		alu_if.test_alu_operation(16'h1234, 16'h4321, MODE_LOGIC, ALU_SUB_OR_XOR, CARRY_IN_1);
		
		// test ALU_AND
		alu_if.test_alu_operation(16'h0001, 16'h0003, MODE_LOGIC, ALU_AND, CARRY_IN_0);
		alu_if.test_alu_operation(16'hFFFF, 16'h0001, MODE_LOGIC, ALU_AND, CARRY_IN_0);
		alu_if.test_alu_operation(16'h1234, 16'h4321, MODE_LOGIC, ALU_AND, CARRY_IN_1);
		
		// test ALU_AND
		alu_if.test_alu_operation(16'h0001, 16'h0003, MODE_LOGIC, ALU_OR, CARRY_IN_0);
		alu_if.test_alu_operation(16'hFFFF, 16'h0001, MODE_LOGIC, ALU_OR, CARRY_IN_0);
		alu_if.test_alu_operation(16'h1234, 16'h4321, MODE_LOGIC, ALU_OR, CARRY_IN_1);
		
		// test ALU_NOT_A_AND_B
		alu_if.test_alu_operation(16'h0001, 16'h0003, MODE_LOGIC, ALU_NOT_A_AND_B, CARRY_IN_0);
		alu_if.test_alu_operation(16'hFFFF, 16'h0001, MODE_LOGIC, ALU_NOT_A_AND_B, CARRY_IN_0);
		alu_if.test_alu_operation(16'h1234, 16'h4321, MODE_LOGIC, ALU_NOT_A_AND_B, CARRY_IN_1);
		
		// test 
		// alu_if.test_alu_operation(16'h0000, 16'h0000, MODE_ARIFMETIC, ALU_ADD, CARRY_IN_1);
		// alu_if.test_alu_operation(16'h0000, 16'h0000, MODE_ARIFMETIC, ALU_ADD, CARRY_IN_1);
	endtask




	// Results reporting
	task report_results();
		$display("\n=== TEST SUMMARY ===");
		$display("All basic operations tested");
		$display("Testbench completed successfully");
	endtask

	// Additional monitoring
	always @(posedge clk) begin
		if (!alu_if.reset) begin
		// Monitor can be extended here
			$display("Cycle: opcode=%h, a=%h, b=%h, result=%h, carry_out=%b",
			alu_if.opcode, alu_if.operand_a,
			alu_if.operand_b, alu_if.result,
			alu_if.carry_out);
		end
	end
endmodule

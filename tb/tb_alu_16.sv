package alu_consts;

	localparam [3:0]
		ALU_ADD						= 4'b1001,
		ALU_SUB_OR_XOR				= 4'b0110,
		ALU_A_ADD_A					= 4'b1100,
		ALU_MINUS_1					= 4'b0011,
		ALU_AND						= 4'b1011,
		ALU_OR						= 4'b1110,
		ALU_NOT_A_AND_B				= 4'b0100;
		
	localparam
		MODE_ARIFMETIC	= 1'b0,
		MODE_LOGIC		= 1'b1;
		
	localparam
		CARRY_IN_0	= 1'b0,
		CARRY_IN_1	= 1'b1;

endpackage

`define RUN_TEST(a_, b_, mode_, op_, cin_) \
    alu_if.test_alu_operation(a_, b_, mode_, op_, cin_, ok); \
    total_tests++; \
    if (ok) passed_tests++;


import alu_consts::*;


// ALU Interface definition
interface alu_intf (input logic clk);
	import alu_consts::*;
	
	
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
							carry_out = ~carry_out;
						end
						ALU_SUB_OR_XOR  : begin
							reg borrow = (~carry_in) & 1'b1;
							
							if (borrow == 1'b0) begin
								{carry_out, compute_result} = {1'b0, a} + {1'b0, ~b};
							end else begin
								{carry_out, compute_result} = {1'b0, a} + {1'b0, ~b} + 17'd1;
							end
							carry_out = ~carry_out;
						end
						ALU_A_ADD_A   : begin
							{carry_out, compute_result} = a + a + ((~carry_in) & 1'b1);
							carry_out = ~carry_out;
						end
						ALU_MINUS_1  : begin
							if (carry_in == 1'b1) begin
								compute_result = 16'hFFFF;
								carry_out = 1'b1;
							end else begin
								compute_result = 16'h0000;
								carry_out = 1'b0;
							end
						end
				
						default: begin
							$display("This operation has not been tested");
						end
					endcase
				end
				
				MODE_LOGIC	: begin
					case(operation)
					
						ALU_SUB_OR_XOR	: begin
							compute_result = a ^ b;
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

						default: begin
							$display("This operation has not been tested");
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
		input test_carry_in,	
		
		output passed_test	// 1'b0 = FAIL, 1'b1 = PASS
		);
		
		reg [15:0] expected_result;
		reg expected_carry_out;		
		compute_result(test_a, test_b, test_mode, test_opcode, test_carry_in, expected_result, expected_carry_out);
		
		#20
		
		// Setting up input signals
		operand_a <= test_a;   
		operand_b <= test_b;
		mode <= test_mode;
		opcode <= test_opcode;
		carry_in <= test_carry_in;
			
		// Wait for ALU result
		#20;
			
		// Check result
		case (mode)
			MODE_ARIFMETIC : begin
				if (result == expected_result && carry_out == expected_carry_out) begin
					passed_test = 1'b1;
					$display("TEST PASSED, opcode=%b: mode=%b, a=%h, b=%h, carry_in=%h -> result=%h, carry_out=%h (expected: result=%h, carry_out=%h)", 
						test_opcode, mode, test_a, test_b, test_carry_in, result, carry_out, expected_result, expected_carry_out);
				end else begin
					passed_test = 1'b0;
					$display("TEST FAILED, opcode=%b: mode=%b, a=%h, b=%h, carry_in=%h -> result=%h, carry_out=%h (expected: result=%h, carry_out=%h)", 
						test_opcode, mode, test_a, test_b, test_carry_in, result, carry_out, expected_result, expected_carry_out);
				end
			end

			MODE_LOGIC : begin
				if (result == expected_result) begin
					passed_test = 1'b1;
					$display("TEST PASSED, opcode=%b: mode=%b, a=%h, b=%h -> result=%h (expected: result=%h)", 
						test_opcode, mode, test_a, test_b, result, expected_result);
				end else begin
					passed_test = 1'b0;
					$display("TEST FAILED, opcode=%b: mode=%b, a=%h, b=%h -> result=%h, (expected: result=%h)", 
						test_opcode, mode, test_a, test_b, result, expected_result);
				end
			end
			
		endcase
		
	endtask
	
	
endinterface



// Main testbench module
module tb_alu_16();
	logic clk;
	
	// Interface instantiation
	alu_intf alu_if(clk);
	
	top_alu_16 dut (
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
		int passed_tests = 0, total_tests = 0;
		initialize_test();
		run_tests(passed_tests, total_tests);
		report_results(passed_tests, total_tests);
		$finish;
	end


	// Helper tasks

	task initialize_test();
		alu_if.reset <= 1;
		alu_if.operand_a <= 0;
		alu_if.operand_b <= 0;
		alu_if.mode <= 0;
		alu_if.opcode <= 0;
		alu_if.carry_in <= 1;
		#20 alu_if.reset <= 0;
		$display("Test initialization completed");
	endtask

	task run_tests(ref int passed_tests, ref int total_tests);
		
		test_SUM_operation(passed_tests, total_tests);
		test_SUB_operation(passed_tests, total_tests);
		test_A_ADD_A_operation(passed_tests, total_tests);
		test_MINUS_1_operation(passed_tests, total_tests);
		test_XOR_operation(passed_tests, total_tests);
		test_AND_operation(passed_tests, total_tests);
		test_OR_operation(passed_tests, total_tests);
		test_NOT_A_AND_B_operation(passed_tests, total_tests);
	
	endtask


	task test_SUM_operation(ref int passed_tests, ref int total_tests);
		reg ok;
		$display("=============start ALU_SUM test=============");
		`RUN_TEST(16'h0001, 16'h0003, MODE_ARIFMETIC, ALU_ADD, CARRY_IN_0);
		`RUN_TEST(16'hFFFF, 16'h0001, MODE_ARIFMETIC, ALU_ADD, CARRY_IN_0);
		`RUN_TEST(16'h1234, 16'h4321, MODE_ARIFMETIC, ALU_ADD, CARRY_IN_1);
		`RUN_TEST(16'h0000, 16'h0000, MODE_ARIFMETIC, ALU_ADD, CARRY_IN_1);
		$display("=============end ALU_SUM test=============\n");
	endtask
	
	task test_SUB_operation(ref int passed_tests, ref int total_tests);
		reg ok;
		$display("=============start ALU_SUB test=============");
		`RUN_TEST(16'h0001, 16'h0003, MODE_ARIFMETIC, ALU_SUB_OR_XOR, CARRY_IN_0);
		`RUN_TEST(16'hFFFF, 16'h0001, MODE_ARIFMETIC, ALU_SUB_OR_XOR, CARRY_IN_0);
		`RUN_TEST(16'h1234, 16'h4321, MODE_ARIFMETIC, ALU_SUB_OR_XOR, CARRY_IN_1);
		`RUN_TEST(16'h0000, 16'h0000, MODE_ARIFMETIC, ALU_SUB_OR_XOR, CARRY_IN_1);
		$display("=============end ALU_SUB test=============\n");
	endtask
	
	task test_A_ADD_A_operation(ref int passed_tests, ref int total_tests);
		reg ok;
		$display("=============start ALU_A_ADD_A test=============");
		`RUN_TEST(16'h0001, 16'h0003, MODE_ARIFMETIC, ALU_A_ADD_A, CARRY_IN_0);
		`RUN_TEST(16'hFFFF, 16'h0001, MODE_ARIFMETIC, ALU_A_ADD_A, CARRY_IN_0);
		`RUN_TEST(16'h1234, 16'h4321, MODE_ARIFMETIC, ALU_A_ADD_A, CARRY_IN_1);
		`RUN_TEST(16'h0000, 16'h0000, MODE_ARIFMETIC, ALU_A_ADD_A, CARRY_IN_1);
		$display("=============end ALU_A_ADD_A test=============\n");
	endtask
	
	task test_MINUS_1_operation(ref int passed_tests, ref int total_tests);
		reg ok;
		$display("=============start ALU_MINUS_1 test=============");
		`RUN_TEST(16'h0001, 16'h0003, MODE_ARIFMETIC, ALU_MINUS_1, CARRY_IN_0);
		`RUN_TEST(16'hFFFF, 16'h0001, MODE_ARIFMETIC, ALU_MINUS_1, CARRY_IN_0);
		`RUN_TEST(16'h1234, 16'h4321, MODE_ARIFMETIC, ALU_MINUS_1, CARRY_IN_1);
		`RUN_TEST(16'h0000, 16'h0000, MODE_ARIFMETIC, ALU_MINUS_1, CARRY_IN_1);
		$display("=============end ALU_MINUS_1 test=============\n");
	endtask
	
	task test_XOR_operation(ref int passed_tests, ref int total_tests);
		reg ok;
		$display("=============start ALU_XOR test=============");
		`RUN_TEST(16'h0001, 16'h0003, MODE_LOGIC, ALU_SUB_OR_XOR, CARRY_IN_0);
		`RUN_TEST(16'hFFFF, 16'h0001, MODE_LOGIC, ALU_SUB_OR_XOR, CARRY_IN_0);
		`RUN_TEST(16'h1234, 16'h4321, MODE_LOGIC, ALU_SUB_OR_XOR, CARRY_IN_1);
		`RUN_TEST(16'h0000, 16'h0000, MODE_LOGIC, ALU_SUB_OR_XOR, CARRY_IN_1);
		$display("=============end ALU_XOR test=============\n");
	endtask
	
	task test_AND_operation(ref int passed_tests, ref int total_tests);
		reg ok;
		$display("=============start ALU_AND test=============");
		`RUN_TEST(16'h0001, 16'h0003, MODE_LOGIC, ALU_AND, CARRY_IN_0);
		`RUN_TEST(16'hFFFF, 16'h0001, MODE_LOGIC, ALU_AND, CARRY_IN_0);
		`RUN_TEST(16'h1234, 16'h4321, MODE_LOGIC, ALU_AND, CARRY_IN_1);
		`RUN_TEST(16'h0000, 16'h0000, MODE_LOGIC, ALU_AND, CARRY_IN_1);
		$display("=============end ALU_AND test=============\n");
	endtask
	
	task test_OR_operation(ref int passed_tests, ref int total_tests);
		reg ok;
		$display("=============start ALU_OR test=============");
		`RUN_TEST(16'h0001, 16'h0003, MODE_LOGIC, ALU_OR, CARRY_IN_0);
		`RUN_TEST(16'hFFFF, 16'h0001, MODE_LOGIC, ALU_OR, CARRY_IN_0);
		`RUN_TEST(16'h1234, 16'h4321, MODE_LOGIC, ALU_OR, CARRY_IN_1);
		`RUN_TEST(16'h0000, 16'h0000, MODE_LOGIC, ALU_OR, CARRY_IN_1);
		$display("=============end ALU_OR test=============\n");
	endtask
	
	task test_NOT_A_AND_B_operation(ref int passed_tests, ref int total_tests);
		reg ok;
		$display("=============start ALU_NOT_A_AND_B test=============");
		`RUN_TEST(16'h0001, 16'h0003, MODE_LOGIC, ALU_NOT_A_AND_B, CARRY_IN_0);
		`RUN_TEST(16'hFFFF, 16'h0001, MODE_LOGIC, ALU_NOT_A_AND_B, CARRY_IN_0);
		`RUN_TEST(16'h1234, 16'h4321, MODE_LOGIC, ALU_NOT_A_AND_B, CARRY_IN_1);
		`RUN_TEST(16'h0000, 16'h0000, MODE_LOGIC, ALU_NOT_A_AND_B, CARRY_IN_1);
		$display("=============end ALU_NOT_A_AND_B test=============\n");
	endtask
	

	// Results reporting
	task report_results(ref int passed_tests, ref int total_tests);
		$display("\n=== TEST SUMMARY ===");
		$display("PASSED %0d/%0d tests", passed_tests, total_tests);
		$display("Testbench completed successfully");
	endtask

	// Additional monitoring
	always @(posedge clk) begin
		if (!alu_if.reset) begin
		// Monitor can be extended here
			/*
			$display("Cycle: opcode=%h, a=%h, b=%h, result=%h, carry_out=%b",
			alu_if.opcode, alu_if.operand_a,
			alu_if.operand_b, alu_if.result,
			alu_if.carry_out);
			*/
		end
	end
endmodule

module cache(
    input clk,
    input reset,
    input i_fetch_valid,
    input i_rfread_valid,
    input [5:0] i_current_pc,
    input i_is_br_instr_rfread,
    input [5:0] i_target_pc,
    output logic [5:0] o_prediction_pc,
	output logic o_prediction_fastcall,
	output logic fastz_d,
	output logic fastz_dd,
	input [15:0] i_ir_rfread
);
	localparam OP_MV_X = 4'b0000, OP_ADD_X = 4'b0001, OP_SUB_X = 4'b0010, OP_CMP_X = 4'b0011, OP_LD = 4'b0100, OP_ST = 4'b0101, OP_MVHI = 4'b0110, OP_J_X = 4'b1000, OP_JZ_X = 4'b1001, OP_JN_X = 4'b1010, OP_CALL_X = 4'b1100;
	
	logic [5:0][14:0] lut;
	logic [5:0] current_pc_rfread;
	logic [5:0] current_pc_rfread_d;
	logic is_br_instr_execute;
	logic [2:0] counter;
	logic [5:0] o_current_pc_execute;
	logic [5:0] o_current_pc_rfread_dd;
	logic [5:0] final_o_current_pc_execute;
	
	logic fastcall;
	logic fastz;
	
	logic o_prediction_fastz;
	
	always_ff @(posedge clk) begin
		if(reset) begin
			fastz_d <= 1'b0;
			fastz_dd <= 1'b0;
		end
		else begin
			fastz_d <= o_prediction_fastz;
			fastz_dd <= fastz_d;
		end
	end

	
	always_comb begin
		final_o_current_pc_execute = o_current_pc_execute;
		fastcall = 1'b0;
		fastz = 1'b0;
		case(i_ir_rfread[3:0])
			OP_J_X: begin
				if(i_ir_rfread[4]) final_o_current_pc_execute = o_current_pc_rfread_dd;
			end
			OP_JZ_X: begin
				if(i_ir_rfread[4]) begin 
					fastz = 1'b1; 
					final_o_current_pc_execute = o_current_pc_rfread_dd;
				end	
			end
			OP_CALL_X: begin 
				if(i_ir_rfread[4]) begin 
					fastcall = 1'b1; 
					final_o_current_pc_execute = o_current_pc_rfread_dd;
				end	
			end
		endcase  
	end	
	
	
	always_ff @(posedge clk) begin
		if (reset) begin
			current_pc_rfread <= 6'd0;
			current_pc_rfread_d <= 6'd0;
			o_current_pc_rfread_dd <= 6'd0;
		end
		else begin
			current_pc_rfread <= i_current_pc;
			current_pc_rfread_d <= current_pc_rfread;
			o_current_pc_rfread_dd <= current_pc_rfread_d;
		end
	end
	
	always_ff @(posedge clk) begin
		if (reset) begin
			o_current_pc_execute <= 6'd0;
			is_br_instr_execute <= 1'b0;
		end
		else begin			
			if (i_fetch_valid) begin
				is_br_instr_execute <= i_is_br_instr_rfread;
				o_current_pc_execute <= current_pc_rfread;
			end
		end
	end

	//check of the current pc matches existing entries
	always_comb begin
		if (lut[0][0] & (i_current_pc[5:0] == lut[0][6:1])) begin
			o_prediction_pc = lut[0][12:7];
			o_prediction_fastcall = lut[0][13];
			o_prediction_fastz = lut[0][14];
		end
		else if (lut[1][0] & (i_current_pc[5:0] == lut[1][6:1])) begin
			o_prediction_pc = lut[1][12:7];
			o_prediction_fastcall = lut[1][13];
			o_prediction_fastz = lut[1][14];
		end
		else if (lut[2][0] & (i_current_pc[5:0] == lut[2][6:1])) begin
			o_prediction_pc = lut[2][12:7];
			o_prediction_fastcall = lut[2][13];
			o_prediction_fastz = lut[2][14];
		end
		else if (lut[3][0] & (i_current_pc[5:0] == lut[3][6:1])) begin
			o_prediction_pc = lut[3][12:7];
			o_prediction_fastcall = lut[3][13];
			o_prediction_fastz = lut[3][14];
		end
		else if (lut[4][0] & (i_current_pc[5:0] == lut[4][6:1])) begin
			o_prediction_pc = lut[4][12:7];
			o_prediction_fastcall = lut[4][13];
			o_prediction_fastz = lut[4][14];
		end
		else if (lut[5][0] & (i_current_pc[5:0] == lut[5][6:1])) begin
			o_prediction_pc = lut[5][12:7];
			o_prediction_fastcall = lut[5][13];
			o_prediction_fastz = lut[5][14];
		end
		else begin
		//assume br not taken
			o_prediction_pc = i_current_pc + 1'b1;
			o_prediction_fastcall = 1'b0;
			o_prediction_fastz = 1'b0;
		end
	end

	//store prediction addr after the first execution of the br instruction
	always_ff @(posedge clk) begin
		if (reset) begin
			counter <= 3'd0;
			lut[0] <= 15'd0;
			lut[1] <= 15'd0;
			lut[2] <= 15'd0;
			lut[3] <= 15'd0;
			lut[4] <= 15'd0;
			lut[5] <= 15'd0;
		end
		else if (i_rfread_valid & is_br_instr_execute) begin
				if (counter == 3'd7) begin
					counter <= 3'd7;
				end
				else begin
					counter <= counter + 1'b1;
					case (counter)
						3'd0: begin
							lut[0][0] <= 1'b1;
							lut[0][6:1] <= final_o_current_pc_execute[5:0];
							lut[0][12:7] <= i_target_pc[5:0];
							lut[0][13] <= fastcall;
							lut[0][14] <= fastz;
						end
						3'd1: begin
							lut[1][0] <= 1'b1;
							lut[1][6:1] <= final_o_current_pc_execute[5:0];
							lut[1][12:7] <= i_target_pc[5:0];
							lut[1][13] <= fastcall;
							lut[1][14] <= fastz;
						end
						3'd2: begin
							lut[2][0] <= 1'b1;
							lut[2][6:1] <= final_o_current_pc_execute[5:0];
							lut[2][12:7] <= i_target_pc[5:0];
							lut[2][13] <= fastcall;
							lut[2][14] <= fastz;
						end
						3'd3: begin
							lut[3][0] <= 1'b1;
							lut[3][6:1] <= final_o_current_pc_execute[5:0];
							lut[3][12:7] <= i_target_pc[5:0];
							lut[3][13] <= fastcall;
							lut[3][14] <= fastz;
						end
						3'd4: begin
							lut[4][0] <= 1'b1;
							lut[4][6:1] <= final_o_current_pc_execute[5:0];
							lut[4][12:7] <= i_target_pc[5:0];
							lut[4][13] <= fastcall;
							lut[4][14] <= fastz;
						end
						3'd5: begin
							lut[5][0] <= 1'b1;
							lut[5][6:1] <=  final_o_current_pc_execute[5:0];
							lut[5][12:7] <= i_target_pc[5:0];
							lut[5][13] <= fastcall;
							lut[5][14] <= fastz;
						end
					endcase
				end
			end
		end
endmodule


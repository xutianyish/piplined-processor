module pc_addr_ctrl(
    input clk,
    input reset,
    input [5:0] i_pc_fetch,
    input [15:0] i_ir_rfread,
    input [15:0] i_ir_execute,
    input [5:0] i_rf_o_data1,
	 input [5:0] i_opa_out,
    input [5:0] i_alu_result_out,
    input i_fetch_valid,
    input i_rfread_valid,
    input [15:0] mem_data,
    input z,
    input n,
    output logic [5:0] o_pc_addr,
    output logic stall_fetch,
    output logic stall_rfread,
	output logic o_prediction_fastcall
);

	localparam OP_MV_X = 4'b0000, OP_ADD_X = 4'b0001, OP_SUB_X = 4'b0010, OP_CMP_X = 4'b0011, OP_LD = 4'b0100, OP_ST = 4'b0101, OP_MVHI = 4'b0110, OP_J_X = 4'b1000, OP_JZ_X = 4'b1001, OP_JN_X = 4'b1010, OP_CALL_X = 4'b1100;
	
	//outputs from br_predictor
	logic [5:0] predict_pc_addr;
	logic fastz_d;
	logic fastz_dd;
	logic jz_d;
	
	//logic br_sig_fetch_stage;
	logic fastcall;
	
	//rfread stage
	logic [5:0] ori_pc_rfread;
	logic [5:0] predict_pc_rfread;
	logic J_or_CALL_rfread;
	logic is_br_instr_rfread;
	logic [5:0] target_pc_rfread;
	
	logic correct_br_sig_rfread_stage;
	//execute stage
	logic [5:0] ori_pc_execute;
	logic [5:0] predict_pc_execute;
	logic J_or_CALL_execute;
	logic is_br_instr_execute;
	logic [5:0] opa_out;	
	logic [5:0] target_pc_execute_br_taken;
	logic correct_br_sig_execute_stage; 
	logic [5:0] target_pc_execute; 
	//test dependent logic
	logic hazard_execute;
	logic detect_hazard_br;
	
	//cache
	cache u_cache(
		.clk(clk),
		.reset(reset),
		.i_fetch_valid(i_fetch_valid),
		.i_rfread_valid(i_rfread_valid),
		.i_current_pc(i_pc_fetch),
		.i_is_br_instr_rfread(is_br_instr_rfread),
		.i_target_pc(target_pc_execute),
		.o_prediction_pc(predict_pc_addr),
		.o_prediction_fastcall(o_prediction_fastcall),
		.i_ir_rfread(i_ir_rfread),
		.fastz_d(fastz_d),
		.fastz_dd(fastz_dd)
	);
	
	//br_sel_contoller
	always_comb begin
		if(~J_or_CALL_execute & (~correct_br_sig_execute_stage)&i_rfread_valid&is_br_instr_execute) begin
			o_pc_addr = target_pc_execute;
			stall_fetch = 1'b1;
			stall_rfread = 1'b1;
		end
		else if( (~correct_br_sig_rfread_stage)&i_fetch_valid&is_br_instr_rfread) begin
			o_pc_addr = target_pc_rfread;
			stall_fetch = 1'b1;
			stall_rfread = 1'b0;
		end
		else begin
			o_pc_addr = predict_pc_addr;
			stall_fetch = 1'b0;
			stall_rfread = 1'b0;
		end    
	end
	
	//fetch
	always_ff @(posedge clk) begin
		if(reset) begin
			predict_pc_rfread <= 6'd0;
			ori_pc_rfread <= 6'd0;
		end
		else begin
			predict_pc_rfread <= predict_pc_addr;
			ori_pc_rfread <= i_pc_fetch;
		end
	end

	//rfread
	always_comb begin
		case(mem_data[3:0])
			OP_J_X,OP_JN_X,OP_JZ_X,OP_CALL_X: is_br_instr_rfread = 1'b1;
			default: is_br_instr_rfread = 1'b0;
		endcase  
	end

	always_comb begin
		case(mem_data[3:0])
			OP_J_X,OP_CALL_X: J_or_CALL_rfread = mem_data[4]; 
			default: J_or_CALL_rfread = 1'b0;
		endcase  
	end
	
	//can only test if jump or call is correct in rfread, assume other branch instructions are correct
	assign target_pc_rfread = ori_pc_rfread + 6'd1 + (mem_data[10:5]);
	assign correct_br_sig_rfread_stage = (~J_or_CALL_rfread)||((predict_pc_rfread == target_pc_rfread));
	
	always_ff @(posedge clk) begin
		if(reset) begin
			ori_pc_execute <= 6'd0;
			J_or_CALL_execute <= 1'd0;
			is_br_instr_execute <= 1'd0;
			opa_out <= 6'd0;
			predict_pc_execute <= 6'd0;
			target_pc_execute_br_taken <= 6'd0;
			jz_d <= 1'd0;
		end
		else if(i_fetch_valid) begin
			ori_pc_execute <= ori_pc_rfread;
			J_or_CALL_execute <= J_or_CALL_rfread;
			is_br_instr_execute <= fastz_d|is_br_instr_rfread;
			opa_out <= i_rf_o_data1;
			predict_pc_execute <= predict_pc_rfread;
			target_pc_execute_br_taken <= target_pc_rfread;
			jz_d <= fastz_d & ~(i_opa_out == 6'd0);
		end
	end

	//execute
	always_comb begin
		case(i_ir_execute[3:0])
			OP_MV_X,OP_ADD_X,OP_SUB_X,OP_LD,OP_MVHI,OP_CALL_X: hazard_execute = 1'b1;
			default: hazard_execute = 1'b0;
		endcase
	end

	dt_br _dt_br(
		.i_hazard(hazard_execute),
		.i_ir_before (i_ir_rfread),
		.i_ir_after(i_ir_execute),
		.dt(detect_hazard_br)
	);
	
	
	//check if prediction is correct in execute stage
	assign correct_br_sig_execute_stage = (jz_d)|(predict_pc_execute == target_pc_execute);

	//set target pc in execute stage
	always_comb begin
		target_pc_execute = ori_pc_execute + 1'b1;
		case(i_ir_rfread[3:0])
			OP_J_X: target_pc_execute = i_ir_rfread[4]?target_pc_execute_br_taken:(detect_hazard_br?i_alu_result_out:opa_out);
			OP_JN_X:begin 
				if(i_ir_rfread[4]) target_pc_execute = n? target_pc_execute_br_taken : ori_pc_execute + 1'b1;
				else target_pc_execute = n? (detect_hazard_br? i_alu_result_out:opa_out):(ori_pc_execute + 1'b1);
			end
			OP_JZ_X:begin
				if(i_ir_rfread[4]) target_pc_execute = z? target_pc_execute_br_taken:ori_pc_execute + 1'b1;
				else target_pc_execute = z?(detect_hazard_br? i_alu_result_out:opa_out):(ori_pc_execute + 1'b1);
			end
			OP_CALL_X: begin
				if(i_ir_rfread[4]) target_pc_execute = target_pc_execute_br_taken;
				else target_pc_execute = detect_hazard_br? i_alu_result_out:opa_out;
			end
		endcase  
	end

endmodule

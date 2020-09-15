module cpu(
	input clk,
	input reset,
	output [15:0] o_pc_addr,
	output o_pc_rd,
	input [15:0] i_pc_rddata,
	output [15:0] o_ldst_addr,
	output o_ldst_rd,
	output o_ldst_wr,
	input [15:0] i_ldst_rddata,
	output [15:0] o_ldst_wrdata,
	output [7:0][15:0] o_tb_regs
);
	//detecter logic
	logic [1:0] detect_rfread;
	logic [1:0] detect_execute;
	logic [15:0] execute_overwrite_data;
	logic [15:0] rfread_overwrite_data;
	logic [1:0] detect_ldst;
	logic [15:0] ldst_overwrite_data;
	
	//fetch stage logic
	logic [15:0] pc_jump_addr;
	logic fetch_valid;
	logic stall_fetch;
	
	//rfread stage logic
	logic [15:0] ir_rfread_stage;
	logic stall_rfread;
	logic rfread_valid;
	//regfile connections
	logic [15:0] rf_o_data1;
	logic [15:0] rf_o_data2;
	logic [2:0] rf_regw;
	logic [15:0] rf_dataw;
	logic rfwrite_mvhi;
	logic rfwrite_en;
	//opa, opb connections
	logic [15:0] opa_o_data;
	logic [15:0] opb_o_data;
	logic opa_en;
	logic opb_en;
	
	//execute stage
	logic execute_valid;
	logic [15:0] alu_result_in;
	logic [15:0] ir_execute_stage;
	logic flag_z;
	logic flag_n;
	logic [15:0] mem_reg_out;
	logic [15:0] alu_result_out;	
	
	forward_detect seq_detect(
		.clk(clk),
		.reset(reset),
		.i_fetch_valid(fetch_valid),
		.i_rfread_valid(rfread_valid),
		.i_execute_valid(execute_valid),
		.i_pc_rddata(i_pc_rddata),
		.i_ir_rfread_stage(ir_rfread_stage),
		.i_ir_execute_stage(ir_execute_stage),
		.i_rf_dataw(rf_dataw),
		.i_alu_result_in(alu_result_in),
		.o_detect_rfread(detect_rfread),
		.o_detect_execute(detect_execute),
		.o_execute_overwrite_data(execute_overwrite_data),
		.o_rfread_overwrite_data(rfread_overwrite_data),
		.o_detect_ldst(detect_ldst),
		.o_ldst_overwrite_data(ldst_overwrite_data)
	);
	
	//fetch stage
	stage_fetch u_stage_fetch(
		.clk(clk),
		.reset(reset),
		.i_pc_jump_addr(pc_jump_addr),
		.i_stall_fetch(stall_fetch),
		.o_pc_rd(o_pc_rd),
		.o_pc_addr(o_pc_addr),
		.o_fetch_valid(fetch_valid)
	);

	//rf_read stage
	rf regfile(
		.clk(clk),
		.reset(reset),
		.i_rf_write(rfwrite_en),
		.i_mvhi(rfwrite_mvhi),
		.i_reg1(i_pc_rddata[7:5]),
		.i_reg2(i_pc_rddata[10:8]),
		.i_regw(rf_regw),
		.i_dataw(rf_dataw),
		.o_data1(rf_o_data1),
		.o_data2(rf_o_data2),
		.o_regs(o_tb_regs)
	);
	
	stage_rfread u_stage_rf_read(
		.clk(clk),
		.reset(reset), 
		.i_pc_addr(o_pc_addr),
		.i_valid(fetch_valid),
		.mem_data(i_pc_rddata),
		.i_rf_data1(rf_o_data1),
		.i_rf_data2(rf_o_data2),
		.i_rfread_overwrite_data(rfread_overwrite_data),
		.i_detect_rfread(detect_rfread),
		.stall_rfread(stall_rfread),
		.i_detect_ldst(detect_ldst),
		.i_ldst_overwrite_data(ldst_overwrite_data),
		.o_ldst_addr(o_ldst_addr),
		.o_ldst_rd(o_ldst_rd),
		.o_ldst_wr(o_ldst_wr),
		.o_ldst_wrdata(o_ldst_wrdata),
		.o_opa_data(opa_o_data),
		.o_opb_data(opb_o_data),
		.o_ir_rfread_stage(ir_rfread_stage),
		.o_valid(rfread_valid)
	);
	
   //execute stage
	stage_execute u_stage_execute(
		.clk(clk),
		.reset(reset),
		.i_valid(rfread_valid),
		.i_opa_data(opa_o_data),
		.i_opb_data(opb_o_data),
		.i_ir_rfread_stage(ir_rfread_stage),
		.i_execute_overwrite_data(execute_overwrite_data),
		.i_detect_execute(detect_execute),
		.o_alu_result_in(alu_result_in),
		.mem_rddata(i_ldst_rddata),
		.o_flag_z(flag_z),
		.o_flag_n(flag_n),
		.o_valid(execute_valid),
		.o_ir_execute_stage(ir_execute_stage),
		.o_mem_reg_out(mem_reg_out),
		.o_alu_result_out(alu_result_out)
	);
	
	//writeback stage
	stage_rfwrite u_stage_rfwrite(
		.i_valid(execute_valid),
		.i_ir(ir_execute_stage),
		.i_alu_result(alu_result_out),
		.i_mem_data(mem_reg_out),
		.o_rf_write_en(rfwrite_en),
		.o_mvhi(rfwrite_mvhi),
		.o_rf_regw(rf_regw),
		.o_rf_dataw(rf_dataw)
	);

	pc_controller u_pc_controller(
		.clk(clk),
		.reset(reset),
		.i_pc_fetch_stage(o_pc_addr),
		.i_ir_rfread_stage(ir_rfread_stage),
		.i_ir_execute_stage(ir_execute_stage),
		.i_rf_o_data1(rf_o_data1),
		.i_alu_result_out(alu_result_out),
		.i_fetch_valid(fetch_valid),
		.i_rfread_valid(rfread_valid),
		.mem_data(i_pc_rddata),
		.z(flag_z),
		.n(flag_n),
		.o_pc_jump_addr(pc_jump_addr),
		.stall_fetch(stall_fetch),
		.stall_rfread(stall_rfread)
	);
	
	

endmodule
    
    

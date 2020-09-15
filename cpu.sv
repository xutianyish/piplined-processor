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
	logic [1:0] dt_rfread;
	logic [1:0] dt_execute;
	logic [15:0] execute_owd;
	logic [15:0] rfread_owd;
	logic [1:0] dt_ldst;
	logic [15:0] ldst_owd;
	
	//fetch stage logic
	logic [5:0] pc_jump_addr;
	logic fetch_valid;
	logic stall_fetch;
	
	//rfread stage logic
	logic [15:0] ir_rfread;
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
	logic [15:0] alu_in;
	logic [15:0] ir_execute;
	logic z;
	logic n;
	logic [15:0] mem_reg_out;
	logic [15:0] alu_out;	
	
	//pc_controller logic
	logic prediction_fastcall;
	
	dep_instr _dep_instr(
		.clk(clk),
		.reset(reset),
		.i_fetch_valid(fetch_valid),
		.i_rfread_valid(rfread_valid),
		.i_execute_valid(execute_valid),
		.i_pc_rddata(i_pc_rddata),
		.i_ir_rfread(ir_rfread),
		.i_ir_execute(ir_execute),
		.i_rf_dataw(rf_dataw),
		.i_alu_in(alu_in),
		.o_dt_rfread(dt_rfread),
		.o_dt_execute(dt_execute),
		.o_execute_owd(execute_owd),
		.o_rfread_owd(rfread_owd),
		.o_dt_ldst(dt_ldst),
		.o_ldst_owd(ldst_owd)
	);
	
	//fetch stage
	fetch _fetch(
		.clk(clk),
		.reset(reset),
		.i_pc_addr(pc_jump_addr),
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
		.o_regs(o_tb_regs),
		.i_fastcall(prediction_fastcall),
		.i_fastcallret_addr(o_pc_addr[6:1]+2'd2)
	);
	
	rfread _rfread(
		.clk(clk),
		.reset(reset), 
		.i_pc_addr(o_pc_addr),
		.i_valid(fetch_valid),
		.mem_data(i_pc_rddata),
		.i_rf_data1(rf_o_data1),
		.i_rf_data2(rf_o_data2),
		.i_rfread_owd(rfread_owd),
		.i_dt_rfread(dt_rfread),
		.stall_rfread(stall_rfread),
		.i_dt_ldst(dt_ldst),
		.i_ldst_owd(ldst_owd),
		.o_ldst_addr(o_ldst_addr),
		.o_ldst_rd(o_ldst_rd),
		.o_ldst_wr(o_ldst_wr),
		.o_ldst_wrdata(o_ldst_wrdata),
		.o_opa_data(opa_o_data),
		.o_opb_data(opb_o_data),
		.o_ir_rfread(ir_rfread),
		.o_valid(rfread_valid)
	);
	
   //execute stage
	execute _execute(
		.clk(clk),
		.reset(reset),
		.i_valid(rfread_valid),
		.i_opa_data(opa_o_data),
		.i_opb_data(opb_o_data),
		.i_ir_rfread(ir_rfread),
		.i_execute_owd(execute_owd),
		.i_dt_execute(dt_execute),
		.o_alu_in(alu_in),
		.mem_rddata(i_ldst_rddata),
		.o_z(z),
		.o_n(n),
		.o_valid(execute_valid),
		.o_ir_execute(ir_execute),
		.o_mem_reg_out(mem_reg_out),
		.o_alu_out(alu_out)
	);
	
	//writeback stage
	rfwrite _rfwrite(
		.i_valid(execute_valid),
		.i_ir(ir_execute),
		.i_alu_result(alu_out),
		.i_mem_data(mem_reg_out),
		.o_rf_write_en(rfwrite_en),
		.o_mvhi(rfwrite_mvhi),
		.o_rf_regw(rf_regw),
		.o_rf_dataw(rf_dataw)
	);
	
	//control pc_addr
	pc_addr_ctrl _pc_addr_ctrl(
		.clk(clk),
		.reset(reset),
		.i_pc_fetch(o_pc_addr[6:1]),
		.i_opa_out(alu_in[6:1]),
		.i_ir_rfread(ir_rfread),
		.i_ir_execute(ir_execute),
		.i_rf_o_data1(rf_o_data1[6:1]),
		.i_alu_result_out(alu_out[6:1]),
		.i_fetch_valid(fetch_valid),
		.i_rfread_valid(rfread_valid),
		.mem_data(i_pc_rddata),
		.z(z),
		.n(n),
		.o_pc_addr(pc_jump_addr),
		.stall_fetch(stall_fetch),
		.stall_rfread(stall_rfread),
		.o_prediction_fastcall(prediction_fastcall)
	);

endmodule
    
    

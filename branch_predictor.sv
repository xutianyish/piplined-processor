module branch_predictor(
    input clk,
    input reset,
    input valid_rf_read,
    input valid_execute,
    input [15:0] current_pc,
    input is_pc_jump,
    input jump,
    input [15:0] target_pc,
    output logic prediction,
    output logic [15:0] prediction_pc
);

// 8 Entry in prediction
// |33 jump|32:17 target_pc|16:1 pc|0 valid|
//logic [7:0][33:0] btb;
	logic [7:0][17:0] btb;
	logic [15:0] current_pc_reg;
	logic [15:0] current_pc_btb;
	logic is_pc_jump_reg;
	logic [2:0] counter;


	always_ff @(posedge clk) begin
		if (reset) begin
			current_pc_reg <= 16'd0;
		end
		else begin
			current_pc_reg <= current_pc;
		end
	end

	always_comb begin
		if (btb[0][0] & (current_pc[7:0] == btb[0][8:1])) begin
			prediction = btb[0][17];
			prediction_pc = {8'b0, btb[0][16:9]};
		end
		else if (btb[1][0] & (current_pc[7:0] == btb[1][8:1])) begin
			prediction = btb[1][17];
			prediction_pc = {8'b0, btb[1][16:9]};
		end
		else if (btb[2][0] & (current_pc[7:0] == btb[2][8:1])) begin
			prediction = btb[2][17];
			prediction_pc = {8'b0, btb[2][16:9]};
		end
		else if (btb[3][0] & (current_pc[7:0] == btb[3][8:1])) begin
			prediction = btb[3][17];
			prediction_pc = {8'b0, btb[3][16:9]};
		end
		else if (btb[4][0] & (current_pc[7:0] == btb[4][8:1])) begin
			prediction = btb[4][17];
			prediction_pc = {8'b0, btb[4][16:9]};
		end
		else if (btb[5][0] & (current_pc[7:0] == btb[5][8:1])) begin
			prediction = btb[5][17];
			prediction_pc = {8'b0, btb[5][16:9]};
		end
		else if (btb[6][0] & (current_pc == btb[6][16:1])) begin
			prediction = btb[6][17];
			prediction_pc = {8'b0, btb[6][16:9]};
		end
		else if (btb[7][0] & (current_pc == btb[7][16:1])) begin
			prediction = btb[7][17];
			prediction_pc = {8'b0, btb[7][16:9]};
		end
		else begin
			// Here we don't have the result just always predict branch not taken
			prediction = 1'b0;
			prediction_pc = current_pc + 2;
		end
	end

	// Second stage, we save current_pc_reg it is a jump instruction
	always_ff @(posedge clk) begin
		if (reset) begin
			current_pc_btb <= 16'd0;
			is_pc_jump_reg <= 1'b0;
		end
		else begin
			if (valid_rf_read) begin
				if (is_pc_jump) begin
					// Now we need to save this pc
					current_pc_btb <= current_pc_reg;
				end
				is_pc_jump_reg <= is_pc_jump;
			end
		end
	end

	// Third stage, now we update the btb to reflect the new branch

	always_ff @(posedge clk) begin
		if (reset) begin
			counter <= 3'd0;
			btb[0] <= 0;
			btb[1] <= 0;
			btb[2] <= 0;
			btb[3] <= 0;
			btb[4] <= 0;
			btb[5] <= 0;
			btb[6] <= 0;
			btb[7] <= 0;

		end
		else if (valid_execute & is_pc_jump_reg) begin
			// We try to update exsisting entries first
			if (btb[0][0] & (current_pc_btb == btb[0][16:1])) begin
				btb[0][17] <= jump;
				btb[0][16:9] <= target_pc[7:0];
			end
			else if (btb[1][0] & (current_pc_btb == btb[1][16:1])) begin
				btb[1][17] <= jump;
				btb[1][16:9] <= target_pc[7:0];
			end
			else if (btb[2][0] & (current_pc_btb == btb[2][16:1])) begin
				btb[2][17] <= jump;
				btb[2][16:9] <= target_pc[7:0];
			end
			else if (btb[3][0] & (current_pc_btb == btb[3][16:1])) begin
				btb[3][17] <= jump;
				btb[3][16:9] <= target_pc[7:0];
			end
			else if (btb[4][0] & (current_pc_btb == btb[4][16:1])) begin
				btb[4][17] <= jump;
				btb[4][16:9] <= target_pc[7:0];
			end
			else if (btb[5][0] & (current_pc_btb == btb[5][16:1])) begin
				btb[5][17] <= jump;
				btb[5][16:9] <= target_pc[7:0];
			end
			else if (btb[6][0] & (current_pc_btb == btb[6][16:1])) begin
				btb[6][17] <= jump;
				btb[6][16:9] <= target_pc[7:0];
			end
			else if (btb[7][0] & (current_pc_btb == btb[7][16:1])) begin
				btb[7][17] <= jump;
				btb[7][16:9] <= target_pc[7:0];
			end
			else begin
				// Here we don't have an matching entry, we try to insert new entry
				if (counter == 3'd7) begin
					// We can't insert any new entry -> just predict jump always
					// not taken
					counter <= 3'd7;
				end
				else begin
					counter <= counter + 1;
					case (counter)
						0: begin
							btb[0][0] <= 1'b1;
							btb[0][8:1] <= current_pc_btb[7:0];
							btb[0][16:9] <= target_pc[7:0];
							btb[0][17] <= jump;
						end
						1: begin
							btb[1][0] <= 1'b1;
							btb[1][8:1] <= current_pc_btb[7:0];
							btb[1][16:9] <= target_pc[7:0];
							btb[1][17] <= jump;
						end
						2: begin
							btb[2][0] <= 1'b1;
							btb[2][8:1] <= current_pc_btb[7:0];
							btb[2][16:9] <= target_pc[7:0];
							btb[2][17] <= jump;
						end
						3: begin
							btb[3][0] <= 1'b1;
							btb[3][8:1] <= current_pc_btb[7:0];
							btb[3][16:9] <= target_pc[7:0];
							btb[3][17] <= jump;
						end
						4: begin
							btb[4][0] <= 1'b1;
							btb[4][8:1] <= current_pc_btb[7:0];
							btb[4][16:9] <= target_pc[7:0];
							btb[4][17] <= jump;
						end
						5: begin
							btb[5][0] <= 1'b1;
							btb[5][8:1] <= current_pc_btb[7:0];
							btb[5][16:9] <= target_pc[7:0];
							btb[5][17] <= jump;

						end
						6: begin
							btb[6][0] <= 1'b1;
							btb[6][8:1] <= current_pc_btb[7:0];
							btb[6][16:9] <= target_pc[7:0];
							btb[6][17] <= jump;
						end
						7: begin
							btb[7][0] <= 1'b1;
							btb[7][8:1] <= current_pc_btb[7:0];
							btb[7][16:9] <= target_pc[7:0];
							btb[7][17] <= jump;
						end
					endcase
				end
			end
		end
	end
endmodule

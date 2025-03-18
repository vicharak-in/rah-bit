module rah_sha_bridge (
    input wire clk,
    input wire wr_fifo_empty,
    input wire [47:0] wr_fifo_read_data,
    output reg wr_fifo_read_en,
    output reg [47:0] wrdata,
    output send_data
);

// Parameters
parameter SHA_INPUT_WIDTH = 512;
parameter SHA_OUTPUT_WIDTH = 256;
parameter RAH_PACKET_WIDTH = 48;
parameter EMPTY_CYCLES = 16;
parameter REM_INPUT_BITS = SHA_INPUT_WIDTH % RAH_PACKET_WIDTH;
parameter REM_OUTPUT_BITS = SHA_OUTPUT_WIDTH % RAH_PACKET_WIDTH;

assign send_data = r_send_data;
// Registers
reg r_send_data = 0;
reg [2:0] rd_state = 0, wr_state = 0;
reg [8:0] rd_bit_count = 0, wr_bit_count = 0;
reg [3:0] empty_counter = 0;
reg [7:0] rd_counter = 0, wr_counter = 0;
reg data_request = 0;
reg [511:0] sha_input_data;
reg input_valid;
reg sha_en = 0;
reg sha_output_fifo_re;
wire sha_done;
wire sha_fifo_empty;
wire [255:0] hash1_out;
reg [255:0] hash_result; // Latched hash value
reg rst;
wire output_valid;
reg rst_latched = 1; // Start with reset high

// Sticky Reset Mechanism: Start high, then transition low permanently
always @(posedge clk) begin
    if (rst_latched) begin
        if (!wr_fifo_empty) begin
            rst <= 0;      // De-assert reset when first data is available
            rst_latched <= 0; // Latch to prevent re-asserting reset
        end else begin
            rst <= 1; // Keep reset high until data is available
        end
    end
end

// Convert Rah data to 512-bit SHA input data
always @(posedge clk) begin
    case (rd_state)
        0: begin
            rd_counter <= 0;
            rd_bit_count <= 0;
            sha_en <= 0;
            input_valid <= 0;
            if (!wr_fifo_empty) begin
                data_request <= 1;
                wr_fifo_read_en <= 1;
                rd_state <= 1;
            end
        end

        1: begin
            data_request <= 0;
            wr_fifo_read_en <= 0;
            rd_state <= 2;
        end

        2: begin
            if (rd_bit_count + RAH_PACKET_WIDTH < SHA_INPUT_WIDTH) begin
                sha_input_data[(SHA_INPUT_WIDTH - rd_bit_count) - 1 -: RAH_PACKET_WIDTH] <= wr_fifo_read_data;
                rd_bit_count <= rd_bit_count + RAH_PACKET_WIDTH;
                if (!wr_fifo_empty) begin
                    wr_fifo_read_en <= 1;
                    rd_state <= 1;
                    rd_counter <= rd_counter + 1;
                end else begin
                    rd_state <= 0; // Prevent stalling if FIFO is empty
                end
            end else begin
                sha_input_data[REM_INPUT_BITS-1:0] <= wr_fifo_read_data[RAH_PACKET_WIDTH-1 -: REM_INPUT_BITS];
                rd_state <= 3;
                sha_en <= 1;
            end
        end

        3: begin
            sha_en <= 0;
            input_valid <= 1; // Enable for one clock cycle
            rd_state <= 4;
        end

        4: begin
            input_valid <= 0; // Deassert on next cycle
            if (sha_done) begin
                rd_state <= 0;
            end
        end
    endcase
end

// Bitcoin Miner Module Instance
bitcoin_miner_top u_miner (
    .clk           (clk),  
    .rst           (rst),        
    .data_in       (sha_input_data[419:0]),
    .mined_hash    (hash1_out),
    .nonce_out     (),
    .valid         (output_valid)
);

// Latch hash output when output_valid is asserted
always @(posedge clk) begin
    if (output_valid) begin
        hash_result <= hash1_out; // Store hash output
    end
end

// Convert 256-bit SHA output data to Rah data
always @(posedge clk) begin
    case (wr_state)
        0: begin
            if (output_valid) begin
                wr_bit_count <= 0;
                wr_state <= 1;
            end
        end

        1: begin
            wrdata <= hash_result[(SHA_OUTPUT_WIDTH - wr_bit_count) - 1 -: RAH_PACKET_WIDTH];
            r_send_data <= 1; // Assert send_data for one cycle

            if (wr_bit_count + RAH_PACKET_WIDTH >= SHA_OUTPUT_WIDTH) begin
                wr_state <= 2; // Move to idle state after sending data
            end else begin
                wr_bit_count <= wr_bit_count + RAH_PACKET_WIDTH;
            end
        end

        2: begin
            r_send_data <= 0; // Deassert send_data
            if (input_valid) begin // Wait for new input_valid signal
                wr_state <= 0;
            end
        end
    endcase
end

endmodule

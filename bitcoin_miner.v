module bitcoin_miner (
    input clk,                        // Clock signal
    input rst,                        // Reset signal
    input [31:0] block_number,        // Block index
    input [255:0] prev_hash,          // Previous block hash
    input [127:0] transactions,       // Simplified transaction data
    input [3:0] difficulty,           // Number of leading zeros required (max 15)
    output reg [255:0] mined_hash,    // Valid mined hash
    output reg [31:0] nonce_out,      // Valid nonce
    output reg valid                  // High when a valid hash is found
);

    reg [31:0] nonce;
    wire [511:0] M_in [0:36];
    wire [255:0] H_out [0:36];
    wire output_valid [0:36];
    reg input_valid;
    reg rst_flag;
    
    reg [255:0] hash_pipeline [0:1]; // Pipelining registers for reducing timing delay
    reg [31:0] nonce_pipeline [0:1]; // Pipeline for nonce

    integer k;

    // Prepare 512-bit message: Block data + Nonce
    generate
        genvar i;
        for (i = 0; i < 37; i = i + 1) begin : sha_blocks
            assign M_in[i] = {block_number, transactions, prev_hash, nonce + i};
        end
    endgenerate

    // Instantiate 40 SHA-256 blocks with pipelining
    generate
        for (i = 0; i < 37; i = i + 1) begin: sha256_pipeline
            sha256_block sha256_inst (
                .clk(clk),
                .rst(rst),
                .H_in(256'h6a09e667bb67ae8563c1059a3c6ef372a54ff53a510e527fa9b05688c2b3e6c1),
                .M_in(M_in[i]),
                .input_valid(input_valid),
                .H_out(H_out[i]),
                .output_valid(output_valid[i])
            );
        end
    endgenerate

    // Optimized function for hash validation using bitwise operations
    function is_valid_hash;
        input [255:0] hash;
        input [3:0] diff;
        begin
            is_valid_hash = (hash >> (256 - diff)) == 0;
        end
    endfunction

    // Mining process with pipelining
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            nonce <= 0;
            valid <= 0;
            input_valid <= 1;
            rst_flag <= 1;
        end else begin
            if (rst_flag) begin
                input_valid <= 0;
                rst_flag <= 0;
            end
            if (!valid) begin
                for (k = 0; k < 37; k = k + 1) begin
                    if (output_valid[k] && is_valid_hash(H_out[k], difficulty)) begin
                        // Store result in pipeline register
                        hash_pipeline[1] <= hash_pipeline[0];
                        nonce_pipeline[1] <= nonce_pipeline[0];

                        hash_pipeline[0] <= H_out[k];
                        nonce_pipeline[0] <= nonce + k;

                        mined_hash <= hash_pipeline[1];
                        nonce_out <= nonce_pipeline[1];
                        valid <= 1;
                    end
                end
                if (!valid) begin
                    nonce <= nonce + 37;
                    input_valid <= 1;
                end
            end
        end
    end

endmodule

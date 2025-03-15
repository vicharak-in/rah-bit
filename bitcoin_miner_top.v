module bitcoin_miner_top (
    input clk,
    input rst,
    input [419:0] data_in, // 420-bit input containing all necessary fields
    output [255:0] mined_hash,
    output [31:0] nonce_out,
    output valid
);

    // Extracting fields from the 420-bit input data
    wire [31:0] block_number = data_in[419:388];  // 32-bit block number
    wire [255:0] prev_hash = data_in[387:132];    // 256-bit previous hash
    wire [127:0] transactions = data_in[131:4];   // 128-bit transaction data
    wire [3:0] difficulty = data_in[3:0];         // 4-bit difficulty level

    // Instantiating the bitcoin_miner module
    bitcoin_miner uut (
        .clk(clk),
        .rst(rst),
        .block_number(block_number),
        .prev_hash(prev_hash),
        .transactions(transactions),
        .difficulty(difficulty),
        .mined_hash(mined_hash),
        .nonce_out(nonce_out),
        .valid(valid)
    );

endmodule

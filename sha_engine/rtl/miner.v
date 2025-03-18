module miner (
    input clk,
    input rst,
    input input_valid,
    input [511:0] block_header,
    output [255:0] hash1_out,
    output [255:0] hash_result,
    output output_valid
);

    // Adjusting the index range to 0:51 for hash_out
    reg [255:0] hash_out [0:51]; 
    wire [255:0] hash_intermediate [0:52];
    wire hash_valid [0:52];

    integer i;

    // First SHA-256 block instance
    sha256_block sha256_block1 (
        .clk(clk),
        .rst(rst),
        .H_in(256'h6a09e667bb67ae85_3c6ef372a54ff53a_510e527f9b05688c_1f83d9ab5be0cd19),
        .M_in(block_header),
        .input_valid(input_valid),
        .H_out(hash1_out),
        .output_valid(hash_valid[0])
    );
    assign hash_intermediate[0] = hash1_out; // First hash assigned directly

    // Loop for generating the remaining SHA-256 block instances
    genvar j;
    generate
        for (j = 1; j < 53; j = j + 1) begin : sha256_block_gen
            sha256_block sha256_block_inst (
                .clk(clk),
                .rst(rst),
                .H_in(hash_intermediate[j-1]), // Feed previous hash as input
                .M_in(block_header),
                .input_valid(input_valid),
                .H_out(hash_intermediate[j]),
                .output_valid(hash_valid[j])
            );
        end
    endgenerate

    // Storing hash outputs into internal registers
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 52; i = i + 1) begin
                hash_out[i] <= 256'b0;
            end
        end else begin
            for (i = 0; i < 52; i = i + 1) begin
                if (hash_valid[i]) begin
                    hash_out[i] <= hash_intermediate[i];
                end
            end
        end
    end

    // Byte-swapping logic for hash_result
    assign hash_result = {
        hash_intermediate[52][7:0], hash_intermediate[52][15:8], hash_intermediate[52][23:16], hash_intermediate[52][31:24],
        hash_intermediate[52][39:32], hash_intermediate[52][47:40], hash_intermediate[52][55:48], hash_intermediate[52][63:56],
        hash_intermediate[52][71:64], hash_intermediate[52][79:72], hash_intermediate[52][87:80], hash_intermediate[52][95:88],
        hash_intermediate[52][103:96], hash_intermediate[52][111:104], hash_intermediate[52][119:112], hash_intermediate[52][127:120],
        hash_intermediate[52][135:128], hash_intermediate[52][143:136], hash_intermediate[52][151:144], hash_intermediate[52][159:152],
        hash_intermediate[52][167:160], hash_intermediate[52][175:168], hash_intermediate[52][183:176], hash_intermediate[52][191:184],
        hash_intermediate[52][199:192], hash_intermediate[52][207:200], hash_intermediate[52][215:208], hash_intermediate[52][223:216],
        hash_intermediate[52][231:224], hash_intermediate[52][239:232], hash_intermediate[52][247:240], hash_intermediate[52][255:248]
    };

    assign output_valid = hash_valid[52];

endmodule

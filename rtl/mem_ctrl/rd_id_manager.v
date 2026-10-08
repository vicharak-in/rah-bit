module rd_id_manager #(
    parameter ID_WIDTH      = 8,
    parameter NUM_PORTS_SEL = 4,
    parameter PORT_ID_WIDTH = 4
) (
    input                          clk,
    input                          rst,
    input                          valid,
    input [ID_WIDTH-1:0]           id_rd_in,
    input                          atype,
    input                          rvalid,
    input                          rlast,
    input [ID_WIDTH-1:0]           rid,
    output reg                     r_en_ack = 0,
    output reg [NUM_PORTS_SEL-1:0] select_rd =0,
    output reg                     rd_r_valid = 0,
    output reg                     rd_r_last = 0,
    output reg                     ack_rd = 0
);

// FIFO parameters
parameter FIFO_DEPTH = 4;

/* FSM Parameter Declaration */
reg [1:0] state = 0 ;
localparam IDLE         = 2'b00;
localparam STORED_RD_ID = 2'b01;

/* Internal registers */
reg [7:0] stored_rd_id = 0;
reg [7:0] current_sent = 0;

// Write operation
always @(posedge clk) begin
    if (!rst) begin 
        r_en_ack <= 0;
        state <= IDLE;
    end else  begin
        case (state)
            IDLE : begin
               if (valid && !atype) begin
                    r_en_ack <= 0;
                    current_sent <= id_rd_in;
                    state <= STORED_RD_ID;
                end else begin
                    r_en_ack <= 0;
                    current_sent <= current_sent;
                    state <= IDLE;
               end
            end

            STORED_RD_ID : begin
                if (rvalid ) begin
                    if (current_sent == rid ) begin
                        stored_rd_id <= rid;
                        r_en_ack <= 1'b1;
                        state <= IDLE;
                     end else begin
                        stored_rd_id <= stored_rd_id;
                        r_en_ack <= 0;
                        state <= STORED_RD_ID;
                     end
                end else  begin
                    stored_rd_id <= stored_rd_id;
                    r_en_ack <= 0;
                    state <= STORED_RD_ID;
                end
            end
        endcase
    end
end

integer i = 0;
always @(posedge clk) begin
    if (!rst) begin
        select_rd <= 0;
        ack_rd <= 1'b0;
    end else begin
        rd_r_valid <= rvalid;
        rd_r_last  <= rlast;

        for(i = 0; i < NUM_PORTS_SEL; i = i + 1) begin
            if((i == rid[PORT_ID_WIDTH - 1 : 0]) && rvalid) begin
                select_rd[i] <= 1;
            end else begin
                select_rd[i] <= 0;
            end
        end
    end
end

endmodule
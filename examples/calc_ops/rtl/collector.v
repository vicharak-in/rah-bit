module collector(
    input                    clk,
    input                    rstn,
    input [47:0]             datain,
    output reg signed [79:0] a=0,
    output reg signed [79:0] b=0,
    output reg [2:0]         app=0,
    output reg               sel=0,
    output reg               en=0
);
             
reg [2:0] packet=0;
reg a_b=0;
reg [39:0] data=0;
integer count=0;
always @(posedge clk)begin
    app=datain[47:45];
    a_b=datain[44];
    sel=datain[43];
    packet=datain[42:40];
    data=datain[39:0];
    if(a_b==0 && (app==3'b001 || app==3'b010 || app==3'b011))begin
        if(packet==3'b000)begin
            a[79:40]=data;
            en=1;
            count=0;
        end
        else if(packet==3'b001)begin
            a[39:0]=data;
            en=1;
        end
    end
    else if(a_b==1 && (app==3'b001 || app==3'b010 || app==3'b011))begin
        if(packet==3'b000)begin
            b[79:40]=data;
            en=1;
        end
        else if(packet==3'b001)begin
            b[39:0]=data;
            if(count<=7)begin
                en=1;
                count=count+1;
            end
            else en=0;
        end
    end
    else begin
        a=0;
        b=0;
        en=0;
    end
end    
endmodule
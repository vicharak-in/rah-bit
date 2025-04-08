module dout(
    input                clk,
    input signed [159:0] c,
    input [2:0]          app,
    input                sel,
    input                done,
    output reg [47:0]    dataout=48'b0,
    output reg           wren=0
);

integer count=0;
always @(posedge clk) begin
    case(app)
    //ADD
    3'b001:begin
        if(done)begin
            if(count==0)begin
                wren=1;
                dataout={app,1'b0,sel,3'b000,c[79:40]};
                count=count+1;
            end
            else if(count==1)begin
                wren=1;
                dataout={app,1'b0,sel,3'b001,c[39:0]};
                count=count+1;
            end
            else if(count==2)begin
                wren=0;
                count=count+1;
            end
            else if(count==3)begin
                wren=0;
                count=0;
            end
        end
        else begin
            wren=0;
            dataout=0;
        end
    end
    //MUL
    3'b010:begin
        if(done)begin
            if(count==0)begin
                wren=1;
                dataout={app,1'b0,sel,3'b001,c[159:120]};
                count=count+1;
            end
            else if(count==1)begin
                wren=1;
                dataout={app,1'b0,sel,3'b010,c[119:80]};
                count=count+1;
            end
            else if(count==2)begin
                wren=1;
                dataout={app,1'b0,sel,3'b011,c[79:40]};
                count=count+1;
            end
            else if(count==3)begin
                wren=1;
                dataout={app,1'b0,sel,3'b100,c[39:0]};
                count=0;
            end
        end
        else begin
            wren=0;
            dataout=0;
        end
    end
    //SHIFT
    3'b011:begin
        if(done)begin
            if(count==0)begin
                wren=1;
                dataout={app,1'b0,sel,3'b000,c[79:40]};
                count=count+1;
            end
            else if(count==1)begin
                wren=1;
                dataout={app,1'b0,sel,3'b001,c[39:0]};
                count=count+1;
            end
            else if(count==2)begin
                wren=0;
                count=count+1;
            end
            else if(count==3)begin
                wren=0;
                count=0;
            end
        end
        else begin
            wren=0;
            dataout=0;
        end
    end
    default:begin 
        dataout=0;
        wren=0;
    end
    endcase
end
endmodule
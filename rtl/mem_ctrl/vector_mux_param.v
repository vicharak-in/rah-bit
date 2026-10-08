////////////////////////////////////////////////////////////////////////////////
//
//   This is a parametrized multiplexer that accepts two parameters
//      1. PORT_SIZE = data width of input data to the mux
//      2. NO_PORT   = size of the mux (Ex: 8x1, 4x1)
//   Description of input and output ports
//   in :  data input port whose data width = PORT_SIZE*NO_PORT
//         Ex: 32-bit 8x1 mux, in_data_width = 32*8 = 256
//   out : data output whose data width = PORT_SIZE
//   sel : select line input of size NO_PORT. Here, the select line is in
//		   one-hot encoded mode (Ex:0001,0010,0100,1000)
//		   If sel=0000, out = 0
//
////////////////////////////////////////////////////////////////////////////////


module vector_mux_param #(
    parameter PORT_SIZE = 32,
    parameter NO_PORT   = 8
) (
    input       [PORT_SIZE*NO_PORT -1:0]    in,
    input       [ NO_PORT-1:0]              sel,
    output wor  [ PORT_SIZE-1:0]            out
);

genvar i;
generate
    for(i = 0; i < NO_PORT; i = i + 1) begin 
        assign out = (sel[(NO_PORT - i) - 1]) ?
                in[i * PORT_SIZE +: PORT_SIZE] : 0;
    end
endgenerate 
endmodule


module vector_mux_data #(
    parameter PORT_SIZE = 32,
    parameter NO_PORT   = 8
) (
    input       [PORT_SIZE*NO_PORT -1:0]    in,
    input       [PORT_SIZE*NO_PORT -1:0]    h_data,
    input       [ NO_PORT-1:0]              sel,
    input       [ NO_PORT-1:0]              header,
    output wor  [ PORT_SIZE-1:0]            out
);

genvar i;
generate
    for(i=0;i<NO_PORT;i=i+1) begin 
        assign out = (header[i]) ? ((sel[(NO_PORT - i) - 1]) ? 
                h_data[i * PORT_SIZE +: PORT_SIZE] : 0) :
                (sel[(NO_PORT - i) - 1]) ? in[i * PORT_SIZE +: PORT_SIZE] : 0;
	end
endgenerate 

endmodule
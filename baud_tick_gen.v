module baud_tick_gen (clk, enable, tick);
input clk, enable;
output tick;    //generate a tick at the specified baud rate * over_sampling

parameter clk_freq = 25000000;
parameter baud = 115200;
parameter over_sampling = 1;

function integer log2(input integer v); begin 
    log2=0; 
    while(v>>log2)
        log2=log2+1;
end
endfunction

localparam acc_width = log2(clk_freq/baud) + 8;
reg [acc_width:0] acc = 0;
localparam shift_limiter = log2(baud*over_sampling >> (31-acc_width));  //this makes sure inc calculation does not overflow
localparam inc = ((baud*over_sampling << (acc_width-shift_limiter)) + ( clk_freq >> (shift_limiter+1))) / (clk_freq >> shift_limiter);

always @(posedge clk) begin
    if(enable)
        acc <= acc[acc_width-1:0] + inc[acc_width:0];
    else
        acc <= inc[acc_width:0];
end

assign tick = acc[acc_width];

endmodule

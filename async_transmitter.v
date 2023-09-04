//TX: 8 bit data, 2 stop bits, no parity bit

module async_transmitter (clk, txd_start, txd_data, txd, txd_busy);

input clk;
input txd_start;
input [7:0] txd_data;
output txd;
output txd_busy;

//assert txd_start for (at least) one clock cycle to start transmission of txd_data
//txd_data is latched so it doesn't need to stay valid while it is being sent

parameter clk_freq = 25000000;
parameter baud = 115200;

`ifdef simulation
wire bit_tick = 1'b1;
`else
wire bit_tick;
baud_tick_gen #(clk_freq, baud) tickgen(.clk(clk), .enable(txd_busy), .tick(bit_tick));
`endif

reg [3:0] txd_state = 0;
wire txd_ready = (txd_state == 0);
assign txd_busy = ~txd_ready;

reg [7:0] txd_shift = 0;
always @(posedge clk) begin
    if(txd_ready & txd_start)
       txd_shift <= txd_data;
    else begin
        if(txd_state[3] & bit_tick)
            txd_shift <= (txd_shift >> 1);
    end

    case(txd_state)
        4'b0000: if(txd_start) txd_state <=4'b0100;
        4'b0100: if(bit_tick) txd_state <= 4'b1000; //start bit
        4'b1000: if(bit_tick) txd_state <= 4'b1001; //bit 0
        4'b1001: if(bit_tick) txd_state <= 4'b1010; //bit 1
        4'b1010: if(bit_tick) txd_state <= 4'b1011; //bit 2
        4'b1011: if(bit_tick) txd_state <= 4'b1100; //bit 3
        4'b1100: if(bit_tick) txd_state <= 4'b1101; //bit 4
        4'b1101: if(bit_tick) txd_state <= 4'b1110; //bit 5
        4'b1110: if(bit_tick) txd_state <= 4'b1111; //bit 6
        4'b1111: if(bit_tick) txd_state <= 4'b0010; //bit 7
        4'b0010: if(bit_tick) txd_state <= 4'b0011; //stop1
        4'b0010: if(bit_tick) txd_state <= 4'b0000; //stop2
        default: if(bit_tick) txd_state <= 4'b0000;
    endcase
end

// concatenate start, data, and stop bits to get a byte
assign txd = (txd_state<4) | (txd_state[3] & txd_shift[0]);

endmodule
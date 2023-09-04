module oscilloscope3 (clk, txd, clk_flash, data_flash);

input clk;
output txd;
input clk_flash;
input [7:0] data_flash;

wire rxd_data_ready;
wire [7:0] rxd_data;
async_receiver uut (.clk(clk),
                    .rxd(rxd),
                    .rxd_data_ready(rxd_data_ready),
                    .rxd_data(rxd_data));

reg start_acq;
wire acq_started;

always @(posedge clk) begin
    if(~start_acq)
        started_acq <= rxd_data_ready;
    else begin
        if(acq_started)
            start_acq <= 0;
    end
end

reg start_acq1, start_acq2;

always @(posedge clk_flash) begin
    start_acq1 <= start_acq;
end

always @(posedge clk_flash) begin
    start_acq2 <= start_acq1;
end

reg threshold1, threshold2;

always @(posedge clk_flash) begin
    threshold1 <= (data_flash_reg >= 8'h80);
end

always @(posedge clk_flash) begin
    threshold2 <= threshold1;
end

reg [8:0] sample_count;
reg pre_trig_pt;
always @(posedge clk_flash) begin
    pre_trig_pt <= (sample_count == 9'd256);
end

reg acquiring, pre_or_post_acq, acq_and_trig, trig, wraddress_trigpt;

always @(posedge clk_flash) begin
    if(~acquiring) begin
        acquiring <= start_acq2;
        pre_or_post_acq <= start_acq2;
    end
    else begin
        if(&sample_count) begin
            acquiring <= 0;
            acq_and_trig <= 0;
            pre_or_post_acq <= 0;
        end
        else begin
            if(pre_trig_pt)
                pre_or_post_acq <= 0;
            else begin
                if(~pre_or_post_acq) begin
                    acq_and_trig <= trig;
                    pre_or_post_acq <= trig;
                    if(trig)
                        wraddress_trigpt <= wraddress;
                end
            end
        end
    end
end

reg [8:0] wraddress;
always @(posedge clk_flash) begin
    if(acquiring)
        wraddress <= wraddress + 1;
end
always @(posedge clk_flash) begin
    if(pre_or_post_acq)
        sample_count <= sample_count + 1;
end

reg acquiring1, acquiring2;

always @(posedge clk) begin
    acquiring1 <= acquiring;
end

always @(posedge clk) begin
    acquiring2 <= acquiring1;
end

assign acq_started = acquiring2;

reg [8:0] rdaddress, send_count;
reg sending;
wire txd_busy;

always @(posedge clk) begin
    if(~sending) begin
        sending <= acq_started;
        if(acq_started)
            rdaddress <= (wraddress_trigpt ^ 9'h100);
    end
    else begin
        if(~txd_busy) begin
            rdaddress <= rdaddress + 1;
            send_count <= send_count + 1;
            if(&send_count)
                sending <= 0;
        end
    end
end

wire txd_start = ~txd_busy & sending;
wire rden = txd_start;

wire [7:0] ram_output;

async_transmitter uut2 (.clk(clk),
                        .txd(txd),
                        .txd_start(txd_start),
                        .txd_busy(txd_busy),
                        .txd_data(ram_output));

reg [7:0] data_flash_reg;
always @(posedge clk_flash) begin
    data_flash_reg <= data_flash_reg;
end

ram512 ram_flash (.data(data_flash_reg),
                    .wraddress(wraddress),
                    .wren(acquiring),
                    .wrclock(clk_flash),
                    .q(ram_flash),
                    .rdaddress(rdaddress),
                    .rden(rden),
                    .rdclock(clk));

//edge slope trigger
assign trig = (rxd_data[0] ^ threshold1) & (rxd_data[0] ^ ~threshold2);

endmodule

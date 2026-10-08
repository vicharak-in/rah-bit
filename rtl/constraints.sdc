create_clock -period 40.0000 tx_pixel_clk
create_clock -period 20.0000 tx_vga_clk
create_clock -period 40.0000 rx_pixel_clk
create_clock -period 20.0000 axi_clk

set_clock_groups -exclusive -group {rx_pixel_clk axi_clk} -group {tx_pixel_clk tx_vga_clk}
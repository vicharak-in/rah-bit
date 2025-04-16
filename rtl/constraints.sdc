create_clock -period 18.5185 tx_pixel_clk
create_clock -period 9.2593 tx_vga_clk
create_clock -period 9.2593 tx_esc_clk
create_clock -period 9.2593 mipi_rx_cal_clk
create_clock -period 18.5185 rx_pixel_clk
create_clock -period 20.0000 application_clk
set_clock_groups -exclusive -group {tx_pixel_clk tx_vga_clk tx_esc_clk} -group {rx_pixel_clk mipi_rx_cal_clk} -group {application_clk}

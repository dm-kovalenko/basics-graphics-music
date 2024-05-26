`include "config.svh"
`include "lab_specific_config.svh"

module board_specific_top
# (
    parameter   clk_mhz   = 27,
                pixel_mhz = 27,
                w_key     = 2,
                w_sw      = 0,
                w_led     = 3,
                w_digit   = 0,

                w_red     = 4,
                w_green   = 4,
                w_blue    = 4,

                w_gpio    = 5
)
(
    input                 clk,
    input  [w_key  - 1:0] key,
    output [w_led  - 1:0] led,
    inout  [w_gpio - 1:0] gpio
);

    //------------------------------------------------------------------------

    localparam w_tm_key    = 8,
               w_tm_led    = 8,
               w_tm_digit  = 8;

    //------------------------------------------------------------------------

    wire  [w_tm_key    - 1:0] tm_key;
    wire                      rst = tm_key [w_tm_key - 1];

    wire  [w_tm_led    - 1:0] tm_led;

    wire  [              7:0] abcdefgh;
    wire  [w_tm_digit  - 1:0] digit;

    //------------------------------------------------------------------------

    wire slow_clk;

    slow_clk_gen # (.fast_clk_mhz (clk_mhz), .slow_clk_hz (1))
    i_slow_clk_gen (.slow_clk (slow_clk), .*);

    //------------------------------------------------------------------------

    top
    # (
        .clk_mhz   ( clk_mhz    ),
        .pixel_mhz ( pixel_mhz  ), 

        .w_key     ( w_tm_key   ),
        .w_sw      ( w_tm_led   ),
        .w_led     ( w_tm_led   ), // typo? not important, same value
        .w_digit   ( w_tm_digit ),

        .w_red     ( w_red      ),
        .w_green   ( w_green    ),
        .w_blue    ( w_blue     ),

        .w_gpio    ( w_gpio     )
    )
    i_top
    (
        .clk       ( clk        ),
        .slow_clk  ( slow_clk   ),
        .rst       ( rst        ),

        .key       ( tm_key     ),
        .sw        ( tm_key     ),

        .led       ( tm_led     ),

        .abcdefgh  ( abcdefgh   ),
        .digit     ( digit      ),

        .vsync     (            ),
        .hsync     (            ),

        .red       (            ),
        .green     (            ),
        .blue      (            ),

        .uart_rx   (            ),
        .uart_tx   (            ),

        .mic       (            ),
        .gpio      ( gpio       ) 
    );

    //------------------------------------------------------------------------

    wire [$left (abcdefgh):0] hgfedcba;

    generate
        genvar i;

        for (i = 0; i < $bits (abcdefgh); i ++)
        begin : abc
            assign hgfedcba [i] = abcdefgh [$left (abcdefgh) - i];
        end
    endgenerate

    //------------------------------------------------------------------------
    // For pin numbers see the Tang Nano 1K PCB silkscreen.
    // There are errors on the wiki page!

    tm1638_board_controller
    # (
        .clk_mhz ( clk_mhz    ),
        .w_digit ( w_tm_digit )
    )
    i_tm1638
    (
        .clk        ( clk      ),
        .rst        ( rst      ),
        .hgfedcba   ( hgfedcba ),
        .digit      ( digit    ),
        .ledr       ( tm_led   ),
        .keys       ( tm_key   ),
        .sio_clk    ( gpio [2] ),  // Pin 18
        .sio_stb    ( gpio [3] ),  // Pin 22
        .sio_data   ( gpio [4] )   // Pin 23
    );

    assign gpio [1] = 1'b0;  // GND       Pin 17
    assign gpio [0] = 1'b1;  // VCC 3.3V  Pin 16

endmodule

module alu(
    input   logic        [7:0]   a, b,
    input   logic                operand,
    output  logic signed [8:0]   result,
    output  logic                overflow
);
    localparam ADD = 1'b0;
    localparam SUB = 1'b1;

    always_comb begin
        // calculation result
        case (operand)
            ADD: result = a + b; // addition
            SUB: result = a - b; // subtraction
        endcase

        // calculate overflow bit
        case (operand)
            ADD: overflow = result[8];
            // SUB: overflow = (a < b);
            SUB: overflow = 0;
        endcase
    end
endmodule
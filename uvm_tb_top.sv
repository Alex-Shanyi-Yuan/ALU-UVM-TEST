`include "uvm_macros.svh"

import uvm_pkg::*;

 

// test class is uvm object

class alu_sequence_item extends uvm_sequence_item;

    `uvm_object_utils(alu_sequence_item)

 

    rand logic unsigned [7:0] a, b;

    rand logic                operand;

         logic                overflow;

         logic signed [8:0]   result;

 

    // constrains

    constraint c_a_b {

        a inside {[0:50]};

        b >= 50;

    }

 

    constraint c_operand {

        operand dist {0:=9, 1:=1};

    }

 

    // standard constructor

    function new(string name = "alu_sequence_item");

        super.new(name);

    endfunction

 

    // no build phase

endclass

 

// Predictor class

class alu_predictor extends uvm_component;

    `uvm_component_utils(alu_predictor)

   

    // UVM analysis port to receive transactions from the monitor

    uvm_analysis_imp#(alu_sequence_item, alu_predictor) tx_input_port;

    uvm_analysis_port #(alu_sequence_item) expected_scb_port;

 

    // Constructor

    function new(string name, uvm_component parent);

        super.new(name, parent);

    endfunction

 

    // build phase

    function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        `uvm_info(get_type_name(), "in the build phase", UVM_MEDIUM);

 

        tx_input_port = new("tx_input_port", this);

        expected_scb_port = new("expected_scb_port", this);

        // create lower components

    endfunction

 

    // Write function to process incoming transactions

    function void write(alu_sequence_item txn);

        compute(txn.a, txn.b, txn.operand, txn.result, txn.overflow);

        `uvm_info(get_type_name(), $sformatf("Sending out data. a: %0d, b:%0d, operator: %0d, result: %0d, overflow: %0d", txn.a, txn.b, txn.operand, txn.result, txn.overflow), UVM_MEDIUM);

        expected_scb_port.write(txn);

    endfunction

 

    // Compute function to predict the result and overflow

    function void compute(

        input  logic unsigned [7:0] a,

        input  logic unsigned [7:0] b,

        input  logic                operand,

        output logic signed   [8:0] result,

        output logic                overflow

    );

        if (operand === 0) begin

            result = a + b;

            overflow = result[8]; // Overflow is the MSB of the 9-bit result

        end else begin

            result = a - b;

            overflow = 0; // Adjust this logic if needed for subtraction overflow

        end

    endfunction

 

endclass

 

// test class is uvm component

class alu_scoreboard extends uvm_scoreboard;

    `uvm_component_utils(alu_scoreboard)

 

    `uvm_analysis_imp_decl(_actual)

    `uvm_analysis_imp_decl(_expected)

 

    alu_sequence_item expected;

    alu_sequence_item actual;

 

    uvm_analysis_imp_actual #(alu_sequence_item, alu_scoreboard) actual_imp;

    uvm_tlm_analysis_fifo #(alu_sequence_item) actual_fifo;

 

    uvm_analysis_imp_expected #(alu_sequence_item, alu_scoreboard) expected_imp;

    uvm_tlm_analysis_fifo #(alu_sequence_item) expected_fifo;

 

    // standard constructor

    function new(string name = "alu_scoreboard", uvm_component parent);

        super.new(name, parent);

    endfunction

 

    // build phase

    function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        `uvm_info(get_type_name(), "in the build phase", UVM_MEDIUM);

 

        actual_imp = new("actual_imp", this);

        expected_imp = new("expected_imp", this);

 

        actual_fifo = new("actual_fifo", this);

        expected_fifo = new("expected_fifo", this);

        // create lower components

    endfunction

 

    // run phase

    virtual task run_phase(uvm_phase phase);

        forever begin

            expected_fifo.peek(expected);

            actual_fifo.peek(actual);

 

            void'(expected_fifo.try_get(expected));

            void'(actual_fifo.try_get(actual));

 

            compare_output(actual, expected);

        end

    endtask

 

    // recieve the pkt from monitro from alu and push to FIFO

    virtual function void write_actual(alu_sequence_item tx);

        actual_fifo.write(tx);

        `uvm_info(get_type_name(), $sformatf("Got actual data. a: %0d, b:%0d, operator: %0d, result: %0d, overflow: %0d", tx.a, tx.b, tx.operand, tx.result, tx.overflow), UVM_MEDIUM);

    endfunction: write_actual

 

    // recieve the pkt from monitro from predictor and push to FIFO

    virtual function void write_expected(alu_sequence_item tx);

        expected_fifo.write(tx);

        `uvm_info(get_type_name(), $sformatf("Got predictor data. a: %0d, b:%0d, operator: %0d, result: %0d, overflow: %0d", tx.a, tx.b, tx.operand, tx.result, tx.overflow), UVM_MEDIUM);

    endfunction: write_expected

 

    function void compare_output(alu_sequence_item act, alu_sequence_item exp);

        if (exp.result !== act.result || exp.overflow !== act.overflow) begin

            `uvm_error(get_name(), "Comparator Mismatch:");

            `uvm_error(get_name(), $sformatf("Expected: a=%0d, b=%0d, operand=%0d, result=%0d, overflow=%0d", exp.a, exp.b, exp.operand, exp.result, exp.overflow));

            `uvm_error(get_name(), $sformatf("Actural:  a=%0d, b=%0d, operand=%0d, result=%0d, overflow=%0d", act.a, act.b, act.operand, act.result, act.overflow));

        end

        else begin

            `uvm_info(get_name(), "Comparator Match: SUCCESS!!!", UVM_MEDIUM);            

            `uvm_error(get_name(), $sformatf("Expected: a=%0d, b=%0d, operand=%0d, result=%0d, overflow=%0d", exp.a, exp.b, exp.operand, exp.result, exp.overflow));

            `uvm_error(get_name(), $sformatf("Actural:  a=%0d, b=%0d, operand=%0d, result=%0d, overflow=%0d", act.a, act.b, act.operand, act.result, act.overflow));

        end

    endfunction: compare_output

endclass

 

// test class is uvm object

class alu_sequence extends uvm_sequence;

    `uvm_object_utils(alu_sequence)

 

    alu_sequence_item tx;

 

    // standard constructor

    function new(string name = "alu_sequence");

        super.new(name);

    endfunction

 

    // no phases

 

    // body task

    task body();

        tx = alu_sequence_item::type_id::create("tx");

 

        repeat(1000) begin

            tx = alu_sequence_item::type_id::create("tx");

            start_item(tx);

            if(!tx.randomize())

                `uvm_error(get_type_name(), "Randomization failed")

            finish_item(tx);

            `uvm_info(get_type_name(), $sformatf("Generated transaction: a=%0d, b=%0d, operand=%0d",

                tx.a, tx.b, tx.operand), UVM_DEBUG)

        end

    endtask

endclass

 

// test class is uvm component

class alu_sequencer extends uvm_sequencer #(alu_sequence_item);

    `uvm_component_utils(alu_sequencer)

 

    // standard constructor

    function new(string name = "alu_sequencer", uvm_component parent);

        super.new(name, parent);

    endfunction

   

endclass

 

// test class is uvm component

class alu_monitor extends uvm_monitor;

    `uvm_component_utils(alu_monitor)

 

    virtual alu_intf intf;

    uvm_analysis_port #(alu_sequence_item) actual_scb_port;

    uvm_analysis_port #(alu_sequence_item) pred_input_port;

 

    alu_sequence_item tx;

    alu_sequence_item pred_tx;

 

    // standard constructor

    function new(string name = "alu_monitor", uvm_component parent);

        super.new(name, parent);

    endfunction

 

    // build phase

    function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        `uvm_info(get_type_name(), "in the build phase", UVM_MEDIUM);

 

        actual_scb_port = new("actual_scb_port", this);

        pred_input_port = new("pred_input_port", this);

 

        if (!uvm_config_db #(virtual alu_intf)::get(this, "", "vif", intf))

            `uvm_fatal("no_inif in the dirver", "virtual interface get failed from config db")

        // create lower components

    endfunction

 

    // run phase, wait 1 posedge sample 1 posedge

    task run_phase(uvm_phase phase);

        // wait(!intf.rst) wait until reset is gone

 

        @(negedge intf.clk); // 0 clk = 0

        @(posedge intf.clk); // 10 clk = 1

 

        forever begin

            tx = alu_sequence_item::type_id::create("tx");

            pred_tx = alu_sequence_item::type_id::create("pred_tx");

           

            // sampling the output

            @(negedge intf.clk); // irst sample at 20, then 40, 60, 80

            tx.a = intf.a;

            tx.b = intf.b;

            tx.operand = intf.operand;

            // get copy input for prdictor

            pred_tx.a = tx.a;

            pred_tx.b = tx.b;

            pred_tx.operand = tx.operand;

 

            // sample the output

            tx.result = intf.result;

            tx.overflow = intf.overflow;

 

            actual_scb_port.write(tx);

            pred_input_port.write(pred_tx);

            @(posedge intf.clk);

        end

    endtask

endclass

 

// test class is uvm component

class alu_driver extends uvm_driver #(alu_sequence_item);

    `uvm_component_utils(alu_driver)

 

    virtual alu_intf intf;

    alu_sequence_item tx;

   

    // standard constructor

    function new(string name = "alu_driver", uvm_component parent);

        super.new(name, parent);

    endfunction

 

    // build phase

    function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        `uvm_info(get_type_name(), "in the build phase", UVM_MEDIUM);

        if (!uvm_config_db #(virtual alu_intf)::get(this, "*", "vif", intf))

            `uvm_fatal("no_inif in the dirver", "virtual interface get failed from config db")

        // create lower components

    endfunction

 

    // send 1 posedge wait 1 posedge

    task run_phase(uvm_phase phase);

    `uvm_info(get_type_name(), "in the run phase", UVM_MEDIUM);

        @(negedge intf.clk); // 0 clk = 0

 

        forever begin

            seq_item_port.get_next_item(tx);

            `uvm_info(get_type_name(), $sformatf("Driving transaction: a=%0d, b=%0d, operand=%0d",

                tx.a, tx.b, tx.operand), UVM_MEDIUM)

            drive(tx);

            seq_item_port.item_done();

            @(negedge intf.clk);

        end

    endtask

 

    task drive(alu_sequence_item tx);

        @(posedge intf.clk); // first drive at 10, then 30, 50, 70

        intf.a <= tx.a;

        intf.b <= tx.b;

        intf.operand <= tx.operand;

    endtask

endclass

 

// test class is uvm component

class alu_agent extends uvm_agent;

    `uvm_component_utils(alu_agent)

 

    alu_driver driver;

    alu_monitor mon;

    alu_sequencer seqr;

 

    // standard constructor

    function new(string name = "alu_agent", uvm_component parent);

        super.new(name, parent);

    endfunction

 

    // build phase

    function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        `uvm_info(get_type_name(), "in the build phase", UVM_MEDIUM);

 

        // create lower components

        driver = alu_driver::type_id::create("driver", this);

        mon = alu_monitor::type_id::create("mon", this);

        seqr = alu_sequencer::type_id::create("seqr", this);

    endfunction

 

    // connect phase

    function void connect_phase(uvm_phase phase);

        super.connect_phase(phase);

        `uvm_info(get_type_name(), "in the connect phase", UVM_MEDIUM);

 

        //connect the components

        driver.seq_item_port.connect(seqr.seq_item_export);

    endfunction

endclass

 

class alu_coverage extends uvm_subscriber #(alu_sequence_item);

    `uvm_component_utils(alu_coverage)

   

    alu_sequence_item tx;

    real cov;

 

    covergroup cg;

        operand: coverpoint tx.operand {

            bins add = {0};

            bins subtract = {1};

        }

        // Cover a > b, b > a, a == b

        a_and_b: coverpoint tx.a {

            ignore_bins a_gt_b = { [0:255] } iff (tx.a > tx.b);

            bins b_gt_a = { [0:255] } iff (tx.a < tx.b);

            bins a_eq_b = { [0:255] } iff (tx.a == tx.b);

        }

       

        // Then cross these three bins with add/sub coverage

        cross tx.operand, a_and_b;

    endgroup : cg

 

    function new(string name, uvm_component parent);

        super.new(name, parent);

        cg = new();

    endfunction

 

    function void build_phase(uvm_phase phase);

        `uvm_info(get_type_name(), "in the build phase", UVM_MEDIUM);

        super.build_phase(phase);

    endfunction

 

    function void write(alu_sequence_item t);

        tx=t;

        cg.sample();

    endfunction

 

    function void extract_phase(uvm_phase phase);    

        cov=cg.get_coverage();

    endfunction

 

    function void report_phase(uvm_phase phase);

        `uvm_info(get_full_name(), $sformatf("Coverage is %d", cov), UVM_MEDIUM)

    endfunction

endclass

 

// test class is uvm component

class alu_env extends uvm_env;

    `uvm_component_utils(alu_env)

 

    alu_agent agent;

    alu_scoreboard scb;

    alu_predictor pred;

    alu_coverage cov;

 

    // standard constructor

    function new(string name = "alu_env", uvm_component parent);

        super.new(name, parent);

    endfunction

 

    // build phase

    function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        `uvm_info(get_type_name(), "in the build phase", UVM_MEDIUM);

 

        // create lower components

        agent = alu_agent::type_id::create("agent", this);

        scb = alu_scoreboard::type_id::create("scb", this);

        pred = alu_predictor::type_id::create("pred", this);

        cov = alu_coverage::type_id::create("cov", this);

    endfunction

 

    // connect phase

    function void connect_phase(uvm_phase phase);

        super.connect_phase(phase);

        `uvm_info(get_type_name(), "in the connect phase", UVM_MEDIUM);

 

        //connect the components

        agent.mon.actual_scb_port.connect(scb.actual_imp); // analysis port

        agent.mon.pred_input_port.connect(pred.tx_input_port); // analysis port

        pred.expected_scb_port.connect(scb.expected_imp); // analysis port

        agent.mon.actual_scb_port.connect(cov.analysis_export);

    endfunction

endclass

 

// test class is uvm component

class alu_test extends uvm_test;

    `uvm_component_utils(alu_test)

 

    alu_env env;

    alu_sequence seq;

 

    // standard constructor

    function new(string name = "alu_test", uvm_component parent);

        super.new(name, parent);

    endfunction

 

    // build phase

    function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        `uvm_info(get_type_name(), "in the build phase", UVM_MEDIUM);

 

        // create lower components

        seq = alu_sequence::type_id::create("seq", this);

        env = alu_env::type_id::create("env", this);

    endfunction

 

    // connect phase

    function void connect_phase(uvm_phase phase);

        super.connect_phase(phase);

        `uvm_info(get_type_name(), "in the connect phase", UVM_MEDIUM);

 

        //connect the components

    endfunction

 

    // end of elaboration phase

    virtual function void end_of_elaboration();

        `uvm_info(get_type_name(), "in the elab phase", UVM_MEDIUM);

        print(); // give uvm harichy

    endfunction

 

    task run_phase(uvm_phase phase);

        phase.raise_objection(this);

       

        `uvm_info(get_type_name(), "Starting test sequence", UVM_MEDIUM)

        seq = alu_sequence::type_id::create("seq");

        seq.start(env.agent.seqr);

       

        // Allow some time for transactions to complete

        #100;

       

        phase.drop_objection(this);

    endtask

endclass

 

interface alu_intf(input logic clk);

    logic unsigned [7:0] a;

    logic unsigned [7:0] b;

    logic                operand;

    logic signed [8:0]   result;

    logic                overflow;

endinterface // alu_intf;

 

module top;

 

    logic clk;

 

    alu_intf intf(clk);

 

    alu dut (

        .a(intf.a),

        .b(intf.b),

        .operand(intf.operand),

        .result(intf.result),

        .overflow(intf.overflow)

    );

 

    initial begin

        uvm_config_db #(virtual alu_intf)::set(null, "*", "vif", intf);

    end

 

    initial begin

        #10000;  // Longer timeout

        `uvm_fatal("TIMEOUT", "Test did not complete in time")

    end

 

    initial begin

        clk = 0;

        forever #10 clk = ~clk;  // More standard clock generation

    end

 

    initial begin

        uvm_top.set_report_verbosity_level_hier(UVM_MEDIUM);

        run_test("alu_test");    

        $finish;    // Explicitly terminate the simulation

    end

 

    initial begin

        $monitor("%0t clk = %0d", $time, clk);

    end

endmodule
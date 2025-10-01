#define TOPLEVEL top_tb

#include <iostream>
#include <sstream>
#include <stdint.h>
#include <stdlib.h>

#include "Vtop_tb.h"
#include <verilated.h>

typedef Vtop_tb dut_t;

<<<<<<< HEAD
<<<<<<< HEAD
dut_t* dut;
trace_t* m_trace;

vluint64_t sim_time = 0;

uint64_t clk_half_period = 0;
uint64_t timeout = 0;
int64_t log_start_time = -1, log_end_time = -1;

VerilatedContext* contextp;

double sc_time_stamp() {
    return sim_time * clk_half_period;
}

void end(bool failed = false) {
    dut->final();

    if (m_trace != NULL) {
        m_trace->close();
    }

    delete dut;
    delete m_trace;

    contextp->statsPrintSummary();

    exit(failed ? EXIT_FAILURE : 0);
}

void tick(dut_t* dut) {
    if (m_trace != NULL) {
        if (sim_time * clk_half_period <= log_end_time && sim_time * clk_half_period >= log_start_time) {
            m_trace->dump(sim_time * clk_half_period);
        }
    }

=======
VerilatedContext* contextp;
dut_t* dut;
uint64_t clk_half_period = 0;

void tick(dut_t* dut) {
=======
VerilatedContext* contextp;
dut_t* dut;
uint64_t clk_half_period = 0;

void tick(dut_t* dut) {
>>>>>>> 00cc73e (mp_ooo patch 7)
    contextp->timeInc(clk_half_period);
>>>>>>> 00cc73e (mp_ooo patch 7)
    dut->clk ^= 1;
    dut->eval();
    sim_time++;
}

void tickn(dut_t* dut, int cycles) {
    for (int i = 0; i < cycles * 2; i++) {
        tick(dut);
    }
}

uint64_t get_int_plusarg(std::string arg) {
    std::string s(contextp->commandArgsPlusMatch(arg.c_str()));
    std::replace(s.begin(), s.end(), '=', ' ');
    std::stringstream ss(s);
    std::string p;
    uint64_t retval;
    ss >> p;
    ss >> retval;
    return retval;
}

int main(int argc, char** argv, char** env) {
    contextp = new VerilatedContext;

<<<<<<< HEAD
<<<<<<< HEAD
    if (argc < 3) {
        std::cerr << "ERR: Invalid argument count. This binary requires logging checkpoints as inline arguments. \n";
        exit(EXIT_FAILURE);
    }

    try {
        log_start_time = (int64_t)std::stoi(argv[1]);
        log_end_time = (int64_t)std::stoi(argv[2]);
    } catch (const std::exception& e) {
        std::cerr << "ERR: Invalid command line arg" << std::endl;
        exit(EXIT_FAILURE);
    }

    if (log_start_time != -1 && log_end_time == -1) {
        log_end_time = MAX_SIM_TIME * clk_half_period;
    }

    if (log_end_time < log_start_time) {
        std::cerr << "ERR: Invalid logging bounds" << std::endl;
        exit(EXIT_FAILURE);
    }

    if (log_start_time != -1) {
        std::cout << "Logging traces from " << log_start_time << " to " << log_end_time << std::endl;
=======
    contextp->traceEverOn(true);
    contextp->commandArgs(argc, argv);
    contextp->fatalOnError(false);

    try {
        clk_half_period = get_int_plusarg("CLOCK_PERIOD_PS_ECE411") / 2;
    } catch (const std::exception& e) {
        std::cerr << "TB Error: Invalid command line arg" << std::endl;
        return 1;
>>>>>>> 00cc73e (mp_ooo patch 7)
=======
    contextp->traceEverOn(true);
    contextp->commandArgs(argc, argv);
    contextp->fatalOnError(false);

    try {
        clk_half_period = get_int_plusarg("CLOCK_PERIOD_PS_ECE411") / 2;
    } catch (const std::exception& e) {
        std::cerr << "TB Error: Invalid command line arg" << std::endl;
        return 1;
>>>>>>> 00cc73e (mp_ooo patch 7)
    }

    contextp->commandArgs(argc, argv);

    clk_half_period = get_int_plusarg("CLOCK_PERIOD_PS_ECE411");
    timeout = 2 * get_int_plusarg("TIMEOUT_ECE411");

    dut = new dut_t;

    dut->clk = 1;
    dut->rst = 1;

    tickn(dut, 2);

    dut->rst = 0;

<<<<<<< HEAD
<<<<<<< HEAD
    while (true) {
        if (dut->error) {
            wait(dut, m_trace, 5);
            end(true);
        }

        if (dut->halt) {
            end(dut->error);
        }

        if (sim_time == timeout) {
            std::cout << "TB Error: Timed out" << std::endl;
            end(true);
        }

        wait(dut, m_trace, 1);
=======
    while (!contextp->gotFinish()) {
        tickn(dut, 1);
>>>>>>> 00cc73e (mp_ooo patch 7)
=======
    while (!contextp->gotFinish()) {
        tickn(dut, 1);
>>>>>>> 00cc73e (mp_ooo patch 7)
    }

    dut->final();
    contextp->statsPrintSummary();
    return contextp->gotError() ? EXIT_FAILURE : 0;
}

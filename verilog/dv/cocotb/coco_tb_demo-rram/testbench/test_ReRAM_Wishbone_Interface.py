import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
import random

@cocotb.test()
async def test_wishbone_interface_single(dut):
    """Single Wishbone write and read transaction"""
    # Start clock
    cocotb.start_soon(Clock(dut.wb_clk_i, 10, units="ns").start())

    import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
import random

@cocotb.test()
async def test_wishbone_interface_single(dut):
    """Single Wishbone write and read transaction"""
    # Start clock
    cocotb.start_soon(Clock(dut.wb_clk_i, 10, units="ns").start())

    # Initialize signals
    dut.wb_rst_i.value = 0
    dut.wbs_stb_i.value = 0
    dut.wbs_cyc_i.value = 0
    dut.wbs_we_i.value = 0
    dut.wbs_sel_i.value = 0
    dut.wbs_adr_i.value = 0
    dut.wbs_dat_i.value = 0

    # Apply reset
    await Timer(20, units="ns")
    dut.wb_rst_i.value = 1
    await Timer(20, units="ns")
    await RisingEdge(dut.wb_clk_i)

    # Scenario 1: Write 32 entries, Read 20
    await wishbone_write_mul(dut, 32)
    await Timer(3300, units="ns")
    await wishbone_read_mul(dut, 20)
    await Timer(100, units="ns")

    # Scenario 2: Write 10 entries, Read 20
    await RisingEdge(dut.wb_clk_i)
    await wishbone_write_mul(dut, 10)
    await Timer(1100, units="ns")
    await wishbone_read_mul(dut, 20)
    await Timer(100, units="ns")

    # Scenario 3: Write 30 entries, Read 32
    await RisingEdge(dut.wb_clk_i)
    await wishbone_write_mul(dut, 30)
    await Timer(2550, units="ns")
    await wishbone_read_mul(dut, 32)
    await Timer(100, units="ns")
    
    # Scenario 3: Write 10 entries, Read 8
    await RisingEdge(dut.wb_clk_i)
    await wishbone_write_mul(dut, 10)
    await Timer(1500, units="ns")
    await wishbone_read_mul(dut, 8)
    await Timer(100, units="ns")

    # Scenario 4: Reset mid-operation
    dut.wb_rst_i.value = 0
    await Timer(20, units="ns")
    dut.wb_rst_i.value = 1
    await RisingEdge(dut.wb_clk_i)

    # Scenario 5: Write 10 entries, Read 7
    await wishbone_write_mul(dut, 10)
    await Timer(900, units="ns")
    await wishbone_read_mul(dut, 7)
    await Timer(3000, units="ns")

    dut._log.info("Simulation complete.")

# Perform Wishbone Write(s)
async def wishbone_write_mul(dut, count):
    for _ in range(count):
        row_addr = random.randint(0, 31)
        col_addr = random.randint(0, 31)
        rand_data = random.randint(0, 255)

        # Compose data word
        composed_data = (0b00 << 30) | (row_addr << 25) | (col_addr << 20) | (0b0000 << 16) | (0x00 << 8) | rand_data
        dut.wbs_dat_i.value = composed_data

        # Set bus signals
        dut.wbs_stb_i.value = 1
        dut.wbs_cyc_i.value = 1
        dut.wbs_we_i.value = 0
        dut.wbs_adr_i.value = 0x3000000C
        dut.wbs_sel_i.value = 0b0010

        dut._log.info(f"[WRITE] row={row_addr}, col={col_addr}, data=0x{rand_data:02X}")

        # Wait for acknowledge (check immediately after clk edge)
        while True:
            await RisingEdge(dut.wb_clk_i)
            if dut.wbs_ack_o.value == 1:
                break

    # Deassert
    dut.wbs_stb_i.value = 0
    dut.wbs_cyc_i.value = 0

# Perform Wishbone Read(s)
async def wishbone_read_mul(dut, count):
    ack_count = 0
    dut.wbs_stb_i.value = 1
    dut.wbs_cyc_i.value = 1
    dut.wbs_we_i.value = 1
    dut.wbs_adr_i.value = 0x3000000C
    dut.wbs_sel_i.value = 0b0010

    while ack_count < count:
        await RisingEdge(dut.wb_clk_i)
        if dut.wbs_ack_o.value == 1:
            dat_o = dut.wbs_dat_o.value.integer
            sim_time = cocotb.utils.get_sim_time(units='ns')
            dut._log.info(f"[READ] dat_o = 0x{dat_o:08X} @ time {sim_time} ns")
            ack_count += 1

    # Deassert
    dut.wbs_stb_i.value = 0
    dut.wbs_cyc_i.value = 0



# Perform Wishbone Write(s)
async def wishbone_write_mul(dut, count):
    for _ in range(count):
        row_addr = random.randint(0, 31)
        col_addr = random.randint(0, 31)
        rand_data = random.randint(0, 255)

        # Compose data word
        composed_data = (0b00 << 30) | (row_addr << 25) | (col_addr << 20) | (0b0000 << 16) | (0x00 << 8) | rand_data
        dut.wbs_dat_i.value = composed_data

        # Set bus signals
        dut.wbs_stb_i.value = 1
        dut.wbs_cyc_i.value = 1
        dut.wbs_we_i.value = 0
        dut.wbs_adr_i.value = 0x3000000C
        dut.wbs_sel_i.value = 0b0010

        dut._log.info(f"[WRITE] row={row_addr}, col={col_addr}, data=0x{rand_data:02X}")

        # Wait for acknowledge
        await RisingEdge(dut.wb_clk_i)
        await Timer(1, units="ps")
        while dut.wbs_ack_o.value != 1:
            await RisingEdge(dut.wb_clk_i)

    # Deassert
    dut.wbs_stb_i.value = 0
    dut.wbs_cyc_i.value = 0

# Perform Wishbone Read(s)
async def wishbone_read_mul(dut, count):
    ack_count = 0
    dut.wbs_stb_i.value = 1
    dut.wbs_cyc_i.value = 1
    dut.wbs_we_i.value = 1
    dut.wbs_adr_i.value = 0x3000000C
    dut.wbs_sel_i.value = 0b0010

    while ack_count < count:
        await RisingEdge(dut.wb_clk_i)
        if dut.wbs_ack_o.value == 1:
            dat_o = dut.wbs_dat_o.value.integer
            sim_time = cocotb.utils.get_sim_time(units='ns')
            dut._log.info(f"[READ] dat_o = 0x{dat_o:08X} @ time {sim_time} ns")
            ack_count += 1

    # Deassert
    dut.wbs_stb_i.value = 0
    dut.wbs_cyc_i.value = 0


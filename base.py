#!/usr/bin/env python3
from migen import *
from migen.genlib.io import CRG
from litex.build.generic_platform import IOStandard, Subsignal, Pins
from platforms import tarjeta_luis as tarjeta
from litex.soc.integration.soc_core import *
from litex.soc.integration.builder import *
from ios import Led
from module import per_pantalla
# IOs ------------------------------------------------------------------------
_serial = [
    ("serial", 0,
        Subsignal("tx", Pins("C4")),  # J1.1
        Subsignal("rx", Pins("D4")),  # J1.2
        IOStandard("LVCMOS33")
     ),
]
_leds = [
    ("user_led", 0, Pins("P1"), IOStandard("LVCMOS33")),  # LED en la placa
    ("user_led", 1, Pins("F3"), IOStandard("LVCMOS33")),  # LED externo
]
_pantalla = [
    ("pads_pantalla", 0,
        Subsignal("o_data_clock", Pins("M3")),  # 
        Subsignal("o_data_latch", Pins("N1")),  # 
        Subsignal("o_data_blank", Pins("M4")),  # 
            
        Subsignal("led", Pins("T6")),  # J1.1
        Subsignal("o_row_select", Pins("N5 N3 P3 P4 N4")),  # J1.2
        
        Subsignal("o_data_r", Pins("P7 R8")),
        Subsignal("o_data_g", Pins("M7 M8")),
        Subsignal("o_data_b", Pins("P8 M9")),
        
        Subsignal("o_data_r2", Pins("T3 P5")),
        Subsignal("o_data_g2", Pins("R4 N6")),
        Subsignal("o_data_b2", Pins("M5 N7")),
        
        Subsignal("o_data_r3", Pins("L4 R2")),
        Subsignal("o_data_g3", Pins("L5 T2")),
        Subsignal("o_data_b3", Pins("P2 R3")),
        IOStandard("LVCMOS33")
     ),
]
# BaseSoC --------------------------------------------------------------------
class BaseSoC(SoCCore):
    def __init__(self):
        platform = tarjeta.Platform()
        sys_clk_freq = int(25e6)
        platform.add_extension(_serial)
        platform.add_extension(_leds)
        platform.add_extension(_pantalla)
        platform.add_source("module/ram/ram.v") #buscar los archivos .v
        platform.add_source("module/led_control.v")
        # SoC with CPU
        SoCCore.__init__(
            self, platform,
            cpu_type                 = "lm32",
            clk_freq                 = 25e6,
            ident                    = "LiteX CPU cain_test", ident_version=True,
            integrated_rom_size      = 0x8000,
            integrated_main_ram_size = 0x4000)
        # Clock Reset Generation
        self.submodules.crg = CRG( platform.request("clk25"),
            ~platform.request("user_btn_n")
        )
        # Led
        user_leds = Cat(*[platform.request("user_led", i) for i in range(1)])
        self.submodules.leds = Led(user_leds)
        self.add_csr("leds")
        
        SoCCore.add_csr(self,"pantalla")
        self.submodules.pantalla = per_pantalla.PANTALLA(platform.request("pads_pantalla",0))
# Build -----------------------------------------------------------------------
soc = BaseSoC()
builder = Builder(soc, output_dir="build", csr_csv="csr.csv", csr_svd="csr.svd")
builder.build()

// SPDX-FileCopyrightText: 2023 Efabless Corporation

// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at

//      http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#define USER_ADDR_SPACE_C_HEADER_FILE  // TODO disable using the other file until tag is updated and https://github.com/efabless/caravel_mgmt_soc_litex/pull/137 is merged

#include <firmware_apis.h>
#include <custom_user_space.h>
#include <ram_info.h>

#include <stdint.h>

uint32_t read_wishbone(uint32_t addr);

void main(){
    // Enable management GPIO as output to use as indicator for finishing configuration
    ManagmentGpio_outputEnable();
    ManagmentGpio_write(0);

    // Configure all user GPIOs as monitored outputs (bit[1] = running, bit[0] = failure)
    GPIOs_configureAll(GPIO_MODE_USER_STD_OUT_MONITORED);
    GPIOs_loadConfigs(); // load the configuration

    // Enable Wishbone <-> user project interface (otherwise no ack will be received)
    User_enableIF(1);

    // Signal "running"
    GPIOs_writeHigh(0b10);

    // ---- Single Write + Single Read demo ----
    volatile uint32_t addr  = 0x3000000C;
    volatile uint32_t wdata = 0x89ABCDEF;

    // Write
    *((volatile uint32_t*)(addr)) = wdata;

    // Read-back
    volatile uint32_t rdata = read_wishbone(addr);

    // Check and signal pass/fail
    //if (rdata != wdata) {
        // failure
     //   GPIOs_writeHigh(0b01);
     //   ManagmentGpio_write(1);
     //   return;
   // }

    // success (both bits high)
    GPIOs_writeHigh(0b11);
    ManagmentGpio_write(1);
}

// Read helper for Wishbone
uint32_t read_wishbone(uint32_t address)
{
    return (*(volatile uint32_t*)(address));
}



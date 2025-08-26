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

uint32_t read_wishbone(uint32_t);

void main(){
    // Enable management GPIOs as output to use as indicators for finishing configuration  
    ManagmentGpio_outputEnable();
    ManagmentGpio_write(0);
    GPIOs_configureAll(GPIO_MODE_USER_STD_OUT_MONITORED);
    GPIOs_loadConfigs(); // load the configuration 
    User_enableIF(1); // this necessary when reading or writing between wishbone and user project if interface isn't enabled no ack would be recieve and the command will be stuck
    ManagmentGpio_write(1);
    
    volatile int shifting;
    volatile int data_used;
    int start_address[3] = {0, (RAM_NUM_WORDS*4 /10), (RAM_NUM_WORDS*9 /10)};
    int end_address[3] = {(RAM_NUM_WORDS /10), (RAM_NUM_WORDS*5 /10), RAM_NUM_WORDS};
    
    // ---- Single Write + Single Read demo ----
    volatile uint32_t addr = 0x3000000C;
    volatile uint32_t wdata = 0xC21000FF; // [29:25] - Row Address, [24:20] - Column Address, [7:0] Data
    volatile uint32_t wdata1 = 0x42100000;
    volatile uint32_t wdata2 = 0xCA400000;
    volatile uint32_t wdata3 = 0x4A400000;
    
    // Performing Write Operation
    *((volatile uint32_t *) addr) = wdata;
    *((volatile uint32_t *) addr) = wdata1;
    // Performing Read Operation
    uint32_t temp = read_wishbone(addr);
    
    *((volatile uint32_t *) addr) = wdata2;
    *((volatile uint32_t *) addr) = wdata3;
    *((volatile uint32_t *) addr) = wdata1;
    
    uint32_t temp1 = read_wishbone(addr);
    uint32_t temp2 = read_wishbone(addr);
    
    ManagmentGpio_write(0);
}

static unsigned int lfsr = 0xACE1u;  // seed value

int rand(void) {
    // Simple LFSR-based RNG (XOR shift)
    lfsr = (lfsr >> 1) ^ (-(lfsr & 1u) & 0xB400u);
    return (int)(lfsr & 0xFF);  // Return 8-bit random number
}

uint32_t read_wishbone(uint32_t address)
{
    return *(volatile uint32_t *)address;
}


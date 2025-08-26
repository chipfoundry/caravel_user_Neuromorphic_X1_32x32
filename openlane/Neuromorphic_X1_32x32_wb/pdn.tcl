# Copyright 2020-2022 Efabless Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

source $::env(SCRIPTS_DIR)/openroad/common/set_global_connections.tcl
set_global_connections

# Ensure VDDC and VSS are defined correctly
if { ![info exists ::env(VDDC)] } {
    set VDDC "VDDC"
    puts "VDDC is not defined, setting default value: $VDDC"
}

if { ![info exists ::env(VSS)] } {
    set VSS "VSS"
    puts "VSS is not defined, setting default value: $VSS"
}

# Define VDDC and VSS as core voltage domains
set_voltage_domain -name CORE -power $::env(VDDC) -ground $::env(VSS)

# Define secondary power and ground nets if necessary
set secondary []
foreach vdd $::env(VDD_NETS) gnd $::env(GND_NETS) {
    if { $vdd != $::env(VDD_NET)} {
        lappend secondary $vdd

        set db_net [[ord::get_db_block] findNet $vdd]
        if {$db_net == "NULL"} {
            set net [odb::dbNet_create [ord::get_db_block] $vdd]
            $net setSpecial
            $net setSigType "POWER"
        }
    }

    if { $gnd != $::env(GND_NET)} {
        lappend secondary $gnd

        set db_net [[ord::get_db_block] findNet $gnd]
        if {$db_net == "NULL"} {
            set net [odb::dbNet_create [ord::get_db_block] $gnd]
            $net setSpecial
            $net setSigType "GROUND"
        }
    }
}

# Connect VDDC and VSS to the core domain
set_voltage_domain -name CORE -power $::env(VDDC) -ground $::env(VSS) -secondary_power $secondary

# Define the PDN grid for standard cells with CORE voltage domain
define_pdn_grid \
    -name stdcell_grid \
    -starts_with POWER \
    -voltage_domain CORE \
    -pins "$::env(FP_PDN_VERTICAL_LAYER) $::env(FP_PDN_HORIZONTAL_LAYER) met4"

# Insert PDN Stripes for vertical and horizontal connections
add_pdn_stripe \
    -grid stdcell_grid \
    -layer $::env(FP_PDN_VERTICAL_LAYER) \
    -width $::env(FP_PDN_VWIDTH) \
    -pitch $::env(FP_PDN_VPITCH) \
    -offset $::env(FP_PDN_VOFFSET) \
    -spacing $::env(FP_PDN_VSPACING) \
    -starts_with POWER -extend_to_core_ring

add_pdn_stripe \
    -grid stdcell_grid \
    -layer $::env(FP_PDN_HORIZONTAL_LAYER) \
    -width $::env(FP_PDN_HWIDTH) \
    -pitch $::env(FP_PDN_HPITCH) \
    -offset $::env(FP_PDN_HOFFSET) \
    -spacing $::env(FP_PDN_HSPACING) \
    -starts_with POWER -extend_to_core_ring

# Add Tapcells and Decaps after defining the power grid
tapcell -grid stdcell_grid -voltage_domain CORE

# Add the core ring if enabled (optional)
if { $::env(FP_PDN_CORE_RING) == 1 } {
    if { $::env(FP_PDN_MULTILAYER) == 1 } {
        add_pdn_ring \
            -grid stdcell_grid \
            -layers "$::env(FP_PDN_VERTICAL_LAYER) $::env(FP_PDN_HORIZONTAL_LAYER)" \
            -widths "$::env(FP_PDN_CORE_RING_VWIDTH) $::env(FP_PDN_CORE_RING_HWIDTH)" \
            -spacings "$::env(FP_PDN_CORE_RING_VSPACING) $::env(FP_PDN_CORE_RING_HSPACING)" \
            -core_offset "$::env(FP_PDN_CORE_RING_VOFFSET) $::env(FP_PDN_CORE_RING_HOFFSET)"
    } else {
        throw APPLICATION "FP_PDN_CORE_RING cannot be used when FP_PDN_MULTILAYER is set to false."
    }
}

# Additional PDN Stripe for connections to boundary
add_pdn_stripe \
    -grid stdcell_grid \
    -layer met4 \
    -width 3.1 \
    -pitch 60 \
    -offset 5 \
    -spacing 11.9 \
    -starts_with POWER -extend_to_boundary

# Power Grid Connectivity Check
add_pdn_connect \
    -grid stdcell_grid \
    -layers "met3 met4"

# Define a PDN grid for macro placements
define_pdn_grid \
    -macro \
    -default \
    -name macro \
    -starts_with POWER \
    -halo "$::env(FP_PDN_HORIZONTAL_HALO) $::env(FP_PDN_VERTICAL_HALO)"

# Add PDN connection for macro grid layers
add_pdn_connect \
    -grid macro \
    -layers "$::env(FP_PDN_VERTICAL_LAYER) $::env(FP_PDN_HORIZONTAL_LAYER)"

# Optionally, add rails if enabled
if { $::env(FP_PDN_ENABLE_RAILS) == 1 } {
    add_pdn_stripe \
        -grid stdcell_grid \
        -layer $::env(FP_PDN_RAIL_LAYER) \
        -width $::env(FP_PDN_RAIL_WIDTH) \
        -followpins \
        -starts_with POWER

    add_pdn_connect \
        -grid stdcell_grid \
        -layers "$::env(FP_PDN_RAIL_LAYER) $::env(FP_PDN_VERTICAL_LAYER)"
}


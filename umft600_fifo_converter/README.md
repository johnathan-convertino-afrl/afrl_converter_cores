# util_umft600_fifo_converter
## util_umft600_fifo_converter
---

   author: Jay Convertino   
   
   date: 2022.08.09  
   
   details: Interface .   
   
   license: MIT   
   
---

![rtl_img](./rtl.png)

### IP USAGE
#### INSTRUCTIONS
* untested DOES NOT WORK AT THE MOMENT

#### PARAMETERS


### COMPONENTS
#### SRC

* util_umft600_fifo_converter.v
  
#### TB

* tb_umft600.v

### Makefile

* Capable of generating simulations and ip cores for the project.

#### Usage

##### XSim (Vivado)

* make xsim      - Generate Vivado project for simulation.
* make xsim_view - Open Vivado to run simulation.
* make xsim_sim  - Run xsim for a certain amount of time.
  * STOP_TIME ... argument can be passed to change time that the simulation stops (+1000ns, default vivado run time).
  * TB_ARCH ... argument can be passed to change the target configuration for simulation.
* make xsim_gtkwave_view - Use gtkwave to view vcd dump file.

##### IP Core (Vivado)

* make - Create Packaged IP core for Vivado, also builds all sims.

RUN_DIR      := ${PWD}

RTL_V_FILES := ${RUN_DIR}/accelerator.v ${RUN_DIR}/pe3x3.v ${RUN_DIR}/mul.v ${RUN_DIR}/pe1x1.v ${RUN_DIR}/accumulator.v ${RUN_DIR}/chnl_acum.v ${RUN_DIR}/relu.v

FSDB_FILE := pe_tb.fsdb

VCS =   vcs -R -sverilog -j2 +v2k -timescale=1ns/1ns -fsdb +define+FSDB_ON -debug_pp \
-P /home/riscv/synopsys/verdi_2016.06-1/share/PLI/VCS/linux64/novas.tab /home/riscv/synopsys/verdi_2016.06-1/share/PLI/VCS/linux64/pli.a -Mupdate -l comp.log +acc +vpi +memcbk +notimingcheck ${RTL_V_FILES}

SIMV =  ./simv -l vcs.log

all: clean comp run view

comp:
	$(VCS) 

run:
	$(SIMV) 
        
clean:
	rm -rf *~ core csrc simv* vc_hdrs.h ucli.key *.log verdiLog novas.conf novas.rc

view:
	verdi

.PHONY: all comp run clean view


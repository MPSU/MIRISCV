proj: clean create_project.tcl
	module purge &&  \
	module load VIVADO &&  \
	vivado -mode batch -nojournal -nolog -source ./create_project.tcl

proj_open: clean create_project.tcl
	module purge &&  \
	module load VIVADO &&  \
	vivado -mode gui -nojournal -nolog -source ./create_project.tcl

clean:
	$(if $(wildcard .Xil), rm -r .Xil, @:)
	$(if $(wildcard tmp), rm -r tmp, @:)
	

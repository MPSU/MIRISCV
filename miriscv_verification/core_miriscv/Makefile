#-------------------------------------------------------------------
# This makefile was created to override Ibex core makefile for
# RTL-simulation and trace-log comparison with Spike simulator.
# Google RISCV-DV is used for test programs generation.
#-------------------------------------------------------------------

# Path to Ibex directory (relative to this file path)
PATH_TO_IBEX := ../ibex

# MABI variable (not defined in Ibex core Makefile)
MABI := ilp32

# Miriva core configuration select (see yaml/miriscv_configs.yaml)
MIRISCV_CONFIG := spike-compatitable

# ISS timeout
ISS_TIMEOUT := 1200

#-------------------------------------------------------------------
# Override variables
#-------------------------------------------------------------------

# Overriding Ibex core source files with Miriva core source files
override all-verilog = \
  $(shell find ./miriscv/rtl -name '*.v' -o -name '*.sv' -o -name '*.svh') \
  $(shell find $(PATH_TO_IBEX)/dv -name '*.v' -o -name '*.sv' -o -name '*.svh')

# Override project directory
override PRJ_DIR := $(realpath ../)

# Override instruction generator directory
override GEN_DIR  := $(realpath $(PATH_TO_IBEX)/vendor/google_riscv-dv)

# Override testlist path
ifeq ($(TESTLIST), )
	override TESTLIST := $(PRJ_DIR)/core_miriscv/riscv_dv_extension/testlist.yaml
else
	override TESTLIST := $(PRJ_DIR)/core_miriscv/$(TESTLIST)
endif

# Override instruction generator options
override RISCV_DV_OPTS=--custom_target=riscv_dv_extension \
                       --mabi=$(MABI) \

# Override seed, test name and test iterations variables
# It is neccessary for tests-and-seeds variable override
ifneq ($(SEED),)
	override SEED := $(SEED)
else
	override SEED := $(shell echo $$RANDOM)
endif

ifneq ($(TEST),)
	override TEST := $(TEST)
else
	override TEST := all
endif

ifneq ($(ITERATIONS),)
	override ITERATIONS := $(ITERATIONS)
else
	override ITERATIONS := 0
endif

ifneq ($(WAVES),)
	override WAVES := $(WAVES)
else
	override WAVES := 0
endif

ifneq ($(SIMULATOR),)
	override SIMULATOR := $(SIMULATOR)
else
	override SIMULATOR := questa
endif

# Override tests and seeds varibale (paths changes)
override tests-and-seeds := \
  $(shell python3 $(PATH_TO_IBEX)/dv/uvm/core_ibex/list_tests.py \
	--start_seed $(SEED) \
	--test "$(TEST)" \
	--testlist $(TESTLIST) \
	--iterations $(ITERATIONS) \
	--ibex-config $(MIRISCV_CONFIG) \
	--batch_size 1)

# Override output directories
override OUT      := $(PRJ_DIR)/core_miriscv/out
override OUT-SEED := $(OUT)/seed-$(SEED)
override OUT-DIR  := $(dir $(OUT)/)

# Include Ibex core Makefile
include $(PATH_TO_IBEX)/dv/uvm/core_ibex/Makefile


#-------------------------------------------------------------------
# Override goals and their dependencies
#-------------------------------------------------------------------

# Glitch for dependencies override
sim.py yaml/rtl_simulation.yaml run_rtl.py compare.py collect_results.py: ;

# Override simulation config makefile generation path
ifndef MAKE_RESTARTS
$(sim-cfg-mk): FORCE | $(OUT-DIR)
	python3 sim_makefrag_gen.py $(SIMULATOR) $(MIRISCV_CONFIG) $(PRJ_DIR)/ibex $@
endif

# Override instruction generator generation step (with custom program class)
$(metadata)/instr_gen.gen.stamp: \
  $(gen-vars-prereq) $(risc-dv-files) $(TESTLIST) | $(metadata)
	$(verb)rm -rf $(OUT-SEED)/instr_gen
	$(verb)python3 ${GEN_DIR}/run.py \
     --output=$(OUT-SEED)/instr_gen ${GEN_OPTS} \
     --steps=gen \
     --gen_timeout=${TIMEOUT} \
	 --batch_size=1 \
     --lsf_cmd="${LSF_CMD}" \
     --simulator="${SIMULATOR}" \
     ${RISCV_DV_OPTS} \
	 --isa=${ISA} \
     ${TEST_OPTS} \
     ${CSR_OPTS} \
     --sim_opts="+uvm_set_inst_override=riscv_asm_program_gen,miriscv_asm_program_gen,"uvm_test_top.asm_gen" \
                 +signature_addr=${SIGNATURE_ADDR} +pmp_num_regions=${PMP_REGIONS} \
                 +pmp_granularity=${PMP_GRANULARITY} +tvec_alignment=8"
	$(call dump-vars,$(metadata)/gen-vars.mk,gen,$(gen-var-deps))
	@touch $@

# Override RTL compilation process (paths changes)
$(OUT-DIR)rtl_sim/.compile.stamp: \
  $(compile-vars-prereq) $(all-verilog) $(risc-dv-files) \
  $(PATH_TO_IBEX)/dv/uvm/core_ibex/sim.py yaml/rtl_simulation.yaml \
  | $(OUT-DIR)rtl_sim
	$(verb)$(PATH_TO_IBEX)/dv/uvm/core_ibex/sim.py \
	 --o=${OUT-DIR} \
	 --steps=compile \
	 ${COMMON_OPTS} \
	 --simulator="${SIMULATOR}" --simulator_yaml=$(PRJ_DIR)/core_miriscv/yaml/rtl_simulation.yaml \
	 $(cov-arg) $(wave-arg) $(cosim-arg) $(lsf-arg) \
	 --cmp_opts="${COMPILE_OPTS}"
	$(call dump-vars,$(OUT-DIR)rtl_sim/.compile-vars.mk,comp,$(compile-var-deps))
	@touch $@

# Override ISS simulation process (custom timeout)
$(metadata)/instr_gen.iss.stamp: \
  $(iss-vars-prereq) $(TESTLIST) $(metadata)/instr_gen.compile.stamp
	$(verb)python3 ${GEN_DIR}/run.py \
     --o=$(OUT-SEED)/instr_gen ${GEN_OPTS} \
     --steps=iss_sim \
     ${TEST_OPTS} \
     --iss="${ISS}" \
     --iss_opts="${ISS_OPTS}" \
	 --iss_timeout=${ISS_TIMEOUT} \
     --isa="${ISA_ISS}" \
     ${RISCV_DV_OPTS}
	$(call dump-vars,$(metadata)/iss-vars.mk,iss,$(iss-var-deps))
	@touch $@

# Override RTL-simulation compilation process (paths changes)
$(rtl-sim-logs): \
  %/sim.log: \
  $(metadata)/rtl_sim.compile.stamp \
  $(metadata)/instr_gen.compile.stamp \
  $(PATH_TO_IBEX)/dv/uvm/core_ibex/run_rtl.py
	@echo Running RTL simulation at $@
	$(verb)mkdir -p $(@D)
	$(verb)python3 $(PATH_TO_IBEX)/dv/uvm/core_ibex/run_rtl.py \
	  --simulator $(SIMULATOR) \
	  --simulator_yaml $(PRJ_DIR)/core_miriscv/yaml/rtl_simulation.yaml \
      --testlist $(TESTLIST) \
	  $(cov-arg) $(wave-arg) $(lsf-arg) \
	  --start-seed $(SEED) \
	  --iterations $(ITERATIONS) \
	  --batch_size 1 \
      --sim-opts="+signature_addr=${SIGNATURE_ADDR} ${SIM_OPTS}" \
	  --test-dot-seed $(notdir $*) \
	  --bin-dir $(OUT-SEED)/instr_gen/asm_test \
	  --rtl-sim-dir $(OUT-SEED)/rtl_sim

# Override RTL and ISS simulation log files comparison process (paths changes)
$(comp-results): \
  %/test-result.yml: \
  $(PATH_TO_IBEX)/dv/uvm/core_ibex/compare.py \
  $(metadata)/instr_gen.iss.stamp $(rtl-sim-logs)
	@echo Comparing traces for $*
	$(verb)python3 $(PATH_TO_IBEX)/dv/uvm/core_ibex/compare.py \
      --instr-gen-bin-dir $(OUT-SEED)/instr_gen/asm_test \
      --iss $(ISS) \
	  --testlist $(TESTLIST) \
      --iss-log-dir $(OUT-SEED)/instr_gen/$(ISS)_sim \
      --start-seed $(SEED) \
	  --iterations $(ITERATIONS) \
	  --batch_size 1 \
      --test-dot-seed "$(notdir $*)" \
      --output $@ \
      --rtl-log-dir $(OUT-SEED)/rtl_sim/$(notdir $*)

$(OUT-SEED)/regr.log: $(PATH_TO_IBEX)/dv/uvm/core_ibex/collect_results.py $(comp-results)
	@echo "Collecting up results (report at $@)"
	$(verb)$(PATH_TO_IBEX)/dv/uvm/core_ibex/collect_results.py -o $(@D) $(comp-results)

# Override functional coverage processes (paths changes)
riscv_dv_cov:
	$(verb)python3 ${GEN_DIR}/cov.py \
          --core ibex \
          --dir ${OUT-SEED}/rtl_sim \
          -o ${OUT-SEED}/fcov \
          --isa rv32imcb \
          --custom_target $(PATH_TO_IBEX)/dv/uvm/core_ibex/riscv_dv_extension/

gen_cov: riscv_dv_fcov
	$(verb)rm -rf $(OUT-DIR)rtl_sim/test.vdb
	$(verb)$(PATH_TO_IBEX)/dv/uvm/core_ibex/sim.py \
	--steps=cov --simulator="${SIMULATOR}" $(lsf-arg) --o="$(OUT-DIR)"
	@if [ -d "test.vdb" ]; then \
		mv -f test.vdb $(OUT-DIR)rtl_sim/; \
	fi
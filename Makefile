.ONESHELL:
SHELL = /bin/bash
.SHELLFLAGS := -e -o pipefail -c
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules

# The conda env definition file "env.yml" is located in the project's root directory
CURRENT_CONDA_ENV_NAME = hydra
ACTIVATE_CONDA = source $$(conda info --base)/etc/profile.d/conda.sh
CONDA_ACTIVATE = $(ACTIVATE_CONDA) ; conda activate ; conda activate $(CURRENT_CONDA_ENV_NAME)

CPUS = 92
ARGS = --forceall #--keep-incomplete #
MAIN_SMK = workflow/Snakefile

SCRIPT = workflow/scripts/padd_target_regions.py
RULE = workflow/rules/padd_target_regions.smk
PY_SCRIPTS = workflow/scripts/*.py
FASTQ_INPUT_DIR =

.PHONY: \
singularity_run \
conda_run \
snakefmt \
snakefmt_fix \
test \
pycodestyle \
clean \
typing  \
snakelint \
format \
update_env \
pull \
hydra-help \
rule \
module \
create_inputs


## singularity_run: Run the pipeline with singularity
singularity_run:
	$(CONDA_ACTIVATE)
	export SINGULARITY_LOCALCACHEDIR=/data/Twist_Solid/cache_dir
	snakemake --cores $(CPUS) \
	--rerun-incomplete \
	--use-singularity \
	--configfile config/config.yaml \
	--singularity-args "--bind /data/ --bind /archive/" \
	--notemp \
	-s $(MAIN_SMK) \
	$(ARGS)


## conda_run: Run the pipeline with conda
conda_run:
	$(CONDA_ACTIVATE)
	snakemake --cores $(CPUS) \
	--rerun-incomplete \
	--configfile config/config.yaml \
	--use-conda \
	--notemp \
	-s $(MAIN_SMK) \
	$(ARGS)


## snakefmt: Check if there are shortcomings in snakemake files
snakefmt:
	$(CONDA_ACTIVATE)
	singularity exec temp/snakefmt.sif \
	snakefmt "-l 130" \
	--compact-diff \
	.


## snakefmt_fix: Fix shortcomings found by snakefmt
snakefmt_fix:
	$(CONDA_ACTIVATE)
	singularity exec temp/snakefmt.sif \
	snakefmt "-l 130" \
	.


## test: Run unittest:s with same settings as in CI
test:
	$(CONDA_ACTIVATE)
	pytest \
	workflow/scripts


## pycodestyle: Run pycodestyle with same settings as in CI
pycodestyle:
	$(CONDA_ACTIVATE)
	pycodestyle \
	--max-line-length=130 \
	--statistics workflow/scripts



# Not tested in CI but generally useful otherwise

## clean: Remove intermediary files
clean:
	rm -r \
	pgx \
	snv_indels \
	alignment/picard_mark_duplicates \
	alignment/samtools_extract_reads \
	alignment/bwa_mem/NA12878_T.bam.bai.benchmark.tsv \
	alignment/bwa_mem/NA12878_T.bam.bai.log



## typing: Run mypy on a Python script
typing:
	$(CONDA_ACTIVATE)
	mypy \
	--ignore-missing-imports \
	$(PY_SCRIPTS)

## snakelint: Lint snakemake scripts
snakelint:
	$(CONDA_ACTIVATE)
	snakemake \
	--lint
	$(MAIN_SMK) $(RULE)


## format: Format python scripts with yapf
format:
	$(CONDA_ACTIVATE)
	yapf --in-place --verbose $(PY_SCRIPTS)
	# @echo
	# black --verbose $(PY_SCRIPTS)


## update_env: Update conda env based on the env.yml file
update_env:
	$(ACTIVATE_CONDA)
	mamba env update --file env.yml --prune


## pull: Get a functioning version of snakefmt
pull:
	singularity pull temp/snakefmt.sif docker://quay.io/biocontainers/snakefmt:0.6.0--pyhdfd78af_0



# Creating new rules

## hydra-help: Get help for using hydra-genetics utilities
hydra-help:
	$(CONDA_ACTIVATE)
	hydra-genetics \
	--help


## rule: Create a new hydra rule
rule:
	$(CONDA_ACTIVATE)
	cd ..
	hydra-genetics create-rule \
	--name padd_target_regions \
	--module pgx \
	--author "Lauri Mesilaakso" \
	--email lauri.mesilaakso@regionostergotland.se


## module: Create module to start up the project
module:
	$(CONDA_ACTIVATE)
	hydra-genetics create-module \
    --name pgx \
    --description "Pharmacogenomics pipeline implemented in hydra" \
    --git-user ljmesi


## create_inputs: Create input metadata files based on files residing in a given fastq-file directory
create_inputs:
	$(CONDA_ACTIVATE)
	hydra-genetics create-input-files \
	-d $(FASTQ_INPUT_DIR) \
	--force

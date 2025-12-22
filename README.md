# structural-variant-calling-workflows
Modular Snakemake workflows for batch structural variant (SV) calling from short-read whole-genome resequencing (WGRS/WGS) data using mainstream callers (Manta, Smoove/LUMPY, DELLY, and more).


## Useage

## Setup (Conda)
To use the snakemake workflows on HPC, use the conda environment defined in `env/snakemake.yml`.

### Create the conda environment and activate it

```bash
conda env create -f env/snakemake.yml --prefix /path/to/conda_envs/sv_snakemake
conda activate /path/to/conda_envs/sv_snakemake



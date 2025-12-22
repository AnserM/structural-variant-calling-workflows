# structural-variant-calling-workflows
Modular Snakemake workflows for batch structural variant (SV) calling from short-read whole-genome resequencing (WGRS/WGS) data using mainstream callers (Manta, Smoove/LUMPY, DELLY, and more).


## User guide

### Setup (Conda)
To use the snakemake workflows on HPC, use the conda environment defined in `env/snakemake.yml`.

```bash
conda env create -f env/snakemake.yml --prefix /path/to/conda_envs/sv_snakemake
conda activate /path/to/conda_envs/sv_snakemake
```


## Run smoove population-level SV calling

Runs **smoove** in batch using Snakemake on a SLURM cluster with Singularity/Apptainer. Read more instructions and details for using smoove at: https://github.com/brentp/smoove?tab=readme-ov-file#population-calling

### 1) Update paths in the Snakefile
Before running, open `smoove.Snakefile` and adjust any site-specific paths, such as:
- Input BAM directory (and BAM index `.bai` expectations)
- Reference FASTA path 
- Output directories

> Tip: Make sure the paths used inside the container match what you bind with `-B`.

### 2) Adjust resources (recommended)
You can tune resources in `smoove.Snakefile` :
- `threads:` per rule
- `resources: mem_gb=...` and `resources: time=...`


Example resource fields assumed by the command below:
- `{threads}`
- `{resources.mem_gb}`
- `{resources.time}`

### 3) Run the workflow on SLURM
From the project directory:

```bash
snakemake \
  --snakefile smoove.Snakefile \
  --executor cluster-generic \
  --jobs 100 \
  --latency-wait 60 \
  --keep-going \
  --rerun-incomplete \
  --use-singularity \
  --singularity-args "--cleanenv -B /mnt/pixstor/joshitr-lab/amxfq/SVs/Soy640_SVs:/mnt/pixstor/joshitr-lab/amxfq/SVs/Soy640_SVs" \
  --cluster-generic-submit-cmd "sbatch --job-name=smoove.{rule} --cpus-per-task={threads} --mem={resources.mem_gb}G --time={resources.time}"
```


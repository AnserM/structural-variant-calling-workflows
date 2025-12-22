# structural-variant-calling-workflows
Modular Snakemake workflows for batch structural variant (SV) calling from short-read whole-genome resequencing (WGRS/WGS) data using mainstream callers (Manta, Smoove/LUMPY, DELLY, and more).


## User guide

### Setup (Conda)
To use the snakemake workflows on HPC, use the conda environment defined in `env/snakemake.yml`.

```bash
conda env create -f env/snakemake.yml --prefix /path/to/conda_envs/sv_snakemake
conda activate /path/to/conda_envs/sv_snakemake
```


## Run delly population-level SV calling

Runs **smoove** in batch using Snakemake on a SLURM cluster with Singularity/Apptainer. Outputs a single `.vcf.gz` file containing SV calls for a cohort of samples. Read more instructions and details for using smoove at: https://github.com/brentp/smoove?tab=readme-ov-file#population-calling

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
From the project directory that contains the snakefile:

```bash
snakemake \
  --snakefile smoove.Snakefile \
  --executor cluster-generic \
  --jobs 100 \
  --latency-wait 60 \
  --keep-going \
  --rerun-incomplete \
  --use-singularity \
  --singularity-args "--cleanenv -B /path/to/project/directory:/path/to/project/directory" \
  --cluster-generic-submit-cmd "sbatch --job-name=smoove.{rule} --cpus-per-task={threads} --mem={resources.mem_gb}G --time={resources.time}"
```


## Run delly germline SV calling

Runs **delly** by sample using Snakemake on a SLURM cluster with Singularity/Apptainer. Outputs a single `filtered.bcf` file containing SV calls for a cohort of samples. Read more instructions and details for using delly at: https://github.com/dellytools/delly?tab=readme-ov-file#germline-sv-calling

### 1) Update paths in the Snakefile
Before running, open `delly.Snakefile` and adjust any site-specific paths, such as:
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
From the project directory that contains the snakefile:

```bash
snakemake \
  --snakefile delly.Snakefile \
  --executor cluster-generic \
  --jobs 100 \
  --latency-wait 60 \
  --keep-going \
  --rerun-incomplete \
  --use-singularity \
  --singularity-args "--cleanenv -B /path/to/project/directory:/path/to/project/directory" \
  --cluster-generic-submit-cmd "sbatch --job-name=smoove.{rule} --cpus-per-task={threads} --mem={resources.mem_gb}G --time={resources.time}"
```

###################

## Run manta individual sample SV calling

Runs **manta** by sample in parallel using Snakemake on a SLURM cluster with Singularity/Apptainer. Outputs a vcf file containing SV calls for each of the samples. Read more instructions and details for using manta at: https://github.com/Illumina/manta/blob/master/docs/userGuide/README.md. Note: convert_inversion.py script included here has been edited to work with python3.

### 1) Update paths in the Snakefile
Before running, open `manta.Snakefile` and adjust any site-specific paths, such as:
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
From the project directory that contains the snakefile:

```bash
snakemake \
  --snakefile delly.Snakefile \
  --executor cluster-generic \
  --jobs 100 \
  --latency-wait 60 \
  --keep-going \
  --rerun-incomplete \
  --use-singularity \
  --singularity-args "--cleanenv -B /path/to/project/directory:/path/to/project/directory" \
  --cluster-generic-submit-cmd "sbatch --job-name=smoove.{rule} --cpus-per-task={threads} --mem={resources.mem_gb}G --time={resources.time}"
```

### 4) Merge individual file to generate a cohort merged VCF file
Use survivor to merge individual VCF files:

```bash
./SURVIVOR/Debug/SURVIVOR merge {sample_files} 100 1 1 1 0 30 ./output/merged.vcf

./SURVIVOR/Debug/SURVIVOR filter ./output/merged.vcf  NA 50 10000000 0.01 10 ./output/filtered.vcf
```
Note: `sample_files` contains the names of all sample files that need to be merged, read more instructions about using survivor at: https://github.com/fritzsedlazeck/SURVIVOR

# structural-variant-calling-workflows

Modular **Snakemake** workflows for batch structural variant (SV) calling from **short-read whole-genome sequencing / resequencing (WGS/WGRS)** data using mainstream callers (**Manta**, **Smoove/LUMPY**, **DELLY**, and more).

---

## What’s included
- Batch SV calling workflows designed for **many samples** (cohorts) and HPC execution
- SLURM submission via Snakemake with containerized execution (**Singularity/Apptainer**)
- Rule-level resource control (`threads`, `mem_gb`, `time`) inside Snakefiles

---

## Repository layout

- `env/snakemake.yml` — conda environment for running Snakemake + dependencies
- `smoove.Snakefile` — Smoove/LUMPY-based population calling workflow
- `delly.Snakefile` — DELLY germline SV calling workflow
- `manta.Snakefile` — Manta per-sample workflow

---

## Requirements
- Conda (or Mamba)
- Snakemake installed via `env/snakemake.yml`
- Singularity or Apptainer available on your HPC
- SLURM scheduler access
- Input BAMs: coordinate-sorted, duplicate-marked and indexed (`.bam` + `.bai`)
- Reference FASTA (and common indexes like `.fai` as required by tools)



---

## Setup (Conda)

Create the environment from `env/snakemake.yml`. Using a custom prefix is recommended on HPC.

```bash
conda env create -f env/snakemake.yml --prefix /path/to/conda_envs/sv_snakemake
conda activate /path/to/conda_envs/sv_snakemake
```

## General notes (applies to all workflows)

1) Update paths in the Snakefile

Before running, open the relevant Snakefile (smoove.Snakefile, delly.Snakefile, or manta.Snakefile) and adjust site-specific paths such as:

Input BAM directory (and BAM index .bai expectations)
Reference FASTA path
Output directories

2) Adjust resources (recommended)
Each Snakefile defines rule-level resources. You can tune:
threads: per rule
resources: mem_gb=...
resources: time=... (format like 02:00:00)

3) Bind paths into the container

Make sure the paths used inside the container match what you bind with -B. If your reference or input BAMs live outside the project directory, bind those too.

Example:
-B /path/to/project:/path/to/project
-B /path/to/ref:/path/to/ref
-B /path/to/bams:/path/to/bams

## Run Smoove population-level SV calling

Runs smoove (LUMPY-based) in batch using Snakemake on a SLURM cluster with Singularity/Apptainer. Produces a cohort-level VCF (often *.genotyped.vcf.gz, depending on your rules).
Docs: https://github.com/brentp/smoove?tab=readme-ov-file#population-calling

From the project directory that contains smoove.Snakefile:

```bash
snakemake \
  --snakefile smoove.Snakefile \
  --executor cluster-generic \
  --jobs 100 \
  --latency-wait 60 \
  --keep-going \
  --rerun-incomplete \
  --use-singularity \
  --singularity-args "--cleanenv -B /path/to/project:/path/to/project" \
  --cluster-generic-submit-cmd "sbatch --job-name=smoove.{rule} --cpus-per-task={threads} --mem={resources.mem_gb}G --time={resources.time}"
```

## Run DELLY germline SV calling

Runs DELLY per-sample using Snakemake on a SLURM cluster with Singularity/Apptainer. Output format depends on your Snakefile rules (commonly per-sample BCF/VCF and/or cohort-level files).
Docs: https://github.com/dellytools/delly?tab=readme-ov-file#germline-sv-calling

From the project directory that contains delly.Snakefile:

```bash
snakemake \
  --snakefile delly.Snakefile \
  --executor cluster-generic \
  --jobs 100 \
  --latency-wait 60 \
  --keep-going \
  --rerun-incomplete \
  --use-singularity \
  --singularity-args "--cleanenv -B /path/to/project:/path/to/project" \
  --cluster-generic-submit-cmd "sbatch --job-name=delly.{rule} --cpus-per-task={threads} --mem={resources.mem_gb}G --time={resources.time}"
```

## Run Manta individual-sample SV calling

Runs Manta per-sample in parallel using Snakemake on a SLURM cluster with Singularity/Apptainer. Produces per-sample VCF outputs.
Docs: https://github.com/Illumina/manta/blob/master/docs/userGuide/README.md

From the project directory that contains manta.Snakefile:

```bash
snakemake \
  --snakefile manta.Snakefile \
  --executor cluster-generic \
  --jobs 100 \
  --latency-wait 60 \
  --keep-going \
  --rerun-incomplete \
  --use-singularity \
  --singularity-args "--cleanenv -B /path/to/project:/path/to/project" \
  --cluster-generic-submit-cmd "sbatch --job-name=manta.{rule} --cpus-per-task={threads} --mem={resources.mem_gb}G --time={resources.time}"
```

## Merge per-sample VCFs into a cohort VCF (SURVIVOR)

Use SURVIVOR to merge individual VCFs into a cohort-level merged VCF.
Docs: https://github.com/fritzsedlazeck/SURVIVOR

1) Create a sample list file


```bash
ls /path/to/per_sample_vcfs/*.vcf > sample_files
```
2) Merge and filter (example)

Tune parameters to your project:
```bash
./SURVIVOR/Debug/SURVIVOR merge sample_files 100 1 1 1 0 30 output/merged.vcf
./SURVIVOR/Debug/SURVIVOR filter output/merged.vcf NA 50 10000000 0.01 10 output/filtered.vcf
```

## Troubleshooting

Missing .bai errors: confirm BAM index naming matches what the Snakefile expects (sample.bam.bai vs sample.bai).

Container can’t see files: bind all needed directories in --singularity-args "-B ...".

Scheduler limits: reduce --jobs if needed.

OOM/timeouts: increase resources: mem_gb and/or resources: time for the failing rule in the Snakefile.

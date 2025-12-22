
import glob
import os

# ---- paths / config ----
INPUT_BAMS = "/mnt/pixstor/joshitr-lab/amxfq/SVs/Soy640_SVs/inputs/GATK_mark_duplicates"
REF_FASTA  = "/mnt/pixstor/joshitr-lab/amxfq/SVs/Soy640_SVs/reference/Wm82.a2.v1.fa"
COHORT = "Soy600"                              # <-- set this

OUT_CALLS   = "output/smoove/results-smoove"
OUT_JOINT   = "output/smoove/results-genotyped"
OUT_SQUARED = "output/smoove/results-squared"

# ---- discover BAMs (your way) ----
BAM_FILES = glob.glob(os.path.join(INPUT_BAMS, "*.bam"))
BAM_PREFIXES = [os.path.basename(bam).replace(".bam", "") for bam in BAM_FILES]
if not BAM_PREFIXES:
    raise ValueError(f"No BAMs found in {INPUT_BAMS}")

rule all:
    input:
        os.path.join(OUT_SQUARED, f"{COHORT}.smoove.square.vcf.gz")

# 1) per-sample call+genotype
rule smoove_call:
    input:
        bam=os.path.join(INPUT_BAMS, "{bam_prefix}.bam"),
        bai=os.path.join(INPUT_BAMS, "{bam_prefix}.bai"),
        fasta=REF_FASTA,
        fai=REF_FASTA + ".fai"
    output:
        vcf=os.path.join(OUT_CALLS, "{bam_prefix}-smoove.genotyped.vcf.gz")
    container:
        "docker://brentp/smoove"
    threads: 10
    resources:
        mem_gb=20,
        time="3:00:00"
    shell:
        r"""
        mkdir -p {OUT_CALLS}
        smoove call \
          --outdir {OUT_CALLS} \
          --name {wildcards.bam_prefix} \
          --fasta {input.fasta} \
          -p {threads} \
          --genotype {input.bam}
        """

# 2) merge sites across samples -> merged.sites.vcf.gz
rule smoove_merge:
    input:
        vcfs=expand(os.path.join(OUT_CALLS, "{bam_prefix}-smoove.genotyped.vcf.gz"),
                    bam_prefix=BAM_PREFIXES),
        fasta=REF_FASTA,
        fai=REF_FASTA + ".fai"
    output:
        sites="output/smoove/merged.sites.vcf.gz"
    container:
        "docker://brentp/smoove"
    threads: 50
    resources:
        mem_gb=80,
        time="6:00:00"
    shell:
        r"""
        mkdir -p output/smoove
        smoove merge --name merged -f {input.fasta} --outdir output/smoove {input.vcfs}
        test -s {output.sites}
        """

# 3) genotype each sample at merged sites
rule smoove_genotype:
    input:
        bam=os.path.join(INPUT_BAMS, "{bam_prefix}.bam"),
        bai=os.path.join(INPUT_BAMS, "{bam_prefix}.bai"),
        fasta=REF_FASTA,
        fai=REF_FASTA + ".fai",
        sites="output/smoove/merged.sites.vcf.gz"
    output:
        vcf=os.path.join(OUT_JOINT, "{bam_prefix}-joint-smoove.genotyped.vcf.gz")
    container:
        "docker://brentp/smoove"
    threads: 1
    resources:
        mem_gb=16,
        time="6:00:00"
    shell:
        r"""
        mkdir -p {OUT_JOINT}
        smoove genotype -d -x -p {threads} \
          --name {wildcards.bam_prefix}-joint \
          --outdir {OUT_JOINT} \
          --fasta {input.fasta} \
          --vcf {input.sites} \
          {input.bam}

        """


# 4) paste into one cohort VCF
rule smoove_paste:
    input:
        vcfs=expand(os.path.join(OUT_JOINT, "{bam_prefix}-joint-smoove.genotyped.vcf.gz"), bam_prefix=BAM_PREFIXES)
    output:
        squared=os.path.join(OUT_SQUARED, f"{COHORT}.smoove.square.vcf.gz")
    container:
        "docker://brentp/smoove"
    threads: 20
    resources:
        mem_gb=40,
        time="6:00:00"
    log:
        os.path.join(OUT_SQUARED, "smoove_paste.log")
    shell:
        r"""
        mkdir -p {OUT_SQUARED}
        cd {OUT_SQUARED}
        printf "%s\n" {input.vcfs} > vcfs.list
        smoove paste --name {COHORT} ../results-genotyped/*-joint-smoove.genotyped.vcf.gz
	"""

import glob, os

INPUT_FA   = "/mnt/pixstor/joshitr-lab/amxfq/SVs/Soy640_SVs/reference"   # no trailing /
INPUT_BAMS = "/mnt/pixstor/joshitr-lab/amxfq/SVs/Soy640_SVs/inputs/GATK_mark_duplicates"
FASTA      = os.path.join(INPUT_FA, "Wm82.a2.v1.fa")

BAM_FILES = glob.glob(os.path.join(INPUT_BAMS, "*.bam"))
SAMPLES = [os.path.basename(b)[:-4] for b in BAM_FILES]

rule all:
    input:
        expand("output/manta/{s}/results/variants/{s}_diploidSV_inv.vcf", s=SAMPLES)

rule manta_run:
    input:
        bam=os.path.join(INPUT_BAMS, "{s}.bam"),
        fasta=FASTA
    output:
        diploid="output/manta/{s}/results/variants/diploidSV.vcf.gz"
    singularity:
        "docker://dceoy/manta"
    params:
        rundir="output/manta/{s}"
    threads: 10
    resources:
        mem_gb=20,
        time="1:00:00"
    shell:
        r"""
        mkdir -p {params.rundir}
        configManta.py --bam {input.bam} --referenceFasta {input.fasta} --runDir {params.rundir}
        python {params.rundir}/runWorkflow.py -m local -j {threads}
        """

rule manta_convert_inv:
    input:
        vcf="output/manta/{s}/results/variants/diploidSV.vcf.gz",
        fasta=FASTA
    output:
        inv="output/manta/{s}/results/variants/{s}_diploidSV_inv.vcf"
    shell:
        r"""
        python scripts/convertInversion.py samtools {input.fasta} {input.vcf} > {output.inv}
        """


import os
import glob

# Define paths
INPUT_FA = "/mnt/pixstor/joshitr-lab/amxfq/SVs/Soy640_SVs/reference/"
INPUT_BAMS = "/mnt/pixstor/joshitr-lab/amxfq/SVs/Soy640_SVs/inputs/GATK_mark_duplicates/"
FASTA = f"{INPUT_FA}Wm82.a2.v1.fa"

# Get BAM files in the INPUT_BAM directory
BAM_FILES = glob.glob(os.path.join(INPUT_BAMS, "*.bam"))

# Extract BAM prefixes
BAM_PREFIXES = [os.path.basename(bam).replace(".bam", "") for bam in BAM_FILES]

#Workflow
rule all:
    input:
        "./output/delly/delly/filtered.bcf"

rule delly_call:
    input:
        bam=f"{INPUT_BAMS}/{{bam_prefix}}.bam",
        fasta=FASTA
    output:
        bcf="./output/delly/calls/{bam_prefix}_delly.bcf"
    singularity:
        "docker://dellytools/delly"
    threads: 10

    resources:
        mem_gb=15,
        time="2:00:00"
    shell:
        """
        delly call -g {input.fasta} -o {output.bcf} {input.bam}

        """


rule delly_merge:
    input:
        bcf_files=expand("./output/delly/calls/{bam_prefix}_delly.bcf", bam_prefix=BAM_PREFIXES)
    output:
        merged_sites="./output/delly/tmp/sites.bcf"
    singularity:
        "docker://dellytools/delly"  # Use the delly Docker container
    threads: 20

    resources:
        mem_gb=30,
        time="5:00:00"

    shell:
        """
        delly merge -o {output.merged_sites} {input.bcf_files}
        """

rule delly_genotype:
    input:
        merged_sites="./output/delly/tmp/sites.bcf",
        fasta=FASTA,
        bam=f"{INPUT_BAMS}/{{bam_prefix}}.bam"
    output:
        bcf="./output/delly/delly/{bam_prefix}.bcf"
    singularity:
        "docker://dellytools/delly"
    threads: 20
    resources:
        mem_gb=30,
        time="5:00:00"
    shell:
        """
        delly call -g {input.fasta} -v {input.merged_sites} -o {output.bcf} {input.bam}

        """

rule delly_merge_bcf:
    input:
        bcf_files=expand("./output/delly/delly/{bam_prefix}.bcf", bam_prefix=BAM_PREFIXES)
    output:
        merged_bcf="./output/delly/delly/merged.bcf"
    threads: 20

    resources:
        mem_gb=30,
        time="5:00:00"

    shell:
        """
        bcftools merge -m id -O b -o {output.merged_bcf} {input.bcf_files}
        """

rule delly_filter:
    input:
        merged_bcf="./output/delly/delly/merged.bcf"
    output:
        filtered_bcf="./output/delly/delly/filtered.bcf"
    threads: 20
    singularity:
        "docker://dellytools/delly"
    resources:
        mem_gb=30,
        time="5:00:00"

    shell:
        """
        delly filter -f germline -o {output.filtered_bcf} {input.merged_bcf}
        """

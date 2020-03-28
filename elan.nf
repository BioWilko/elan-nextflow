#!/usr/bin/env nextflow

Channel
    .fromPath(params.manifest)
    .splitCsv(header:['dir', 'site', 'coguk_id', 'fasta', 'bam'], sep:'\t')
    .filter { row -> row.fasta.size() > 0 }
    .filter { row -> row.bam.size() > 0 }
    .map { row-> tuple(row.dir, row.site, row.coguk_id, file([row.dir, row.fasta].join('/')), file([row.dir, row.bam].join('/'))) }
    .set { manifest_ch }

process samtools_quickcheck {
    tag { bam }
    conda "environments/samtools.yaml"
    label 'bear'

    errorStrategy 'ignore'

    input:
    tuple dir, site, coguk_id, file(fasta), file(bam) from manifest_ch

    output:
    tuple dir, site, coguk_id, file(fasta), file(bam) into valid_manifest_ch

    """
    samtools quickcheck $bam
    """
}

process samtools_filter_and_sort {
    tag { bam_name }
    conda "environments/samtools.yaml"
    label 'bear'

    input:
    tuple dir, site, coguk_id, file(fasta), file(bam) from valid_manifest_ch

    output:
    publishDir path: params.publish
    file "${coguk_id}.climb.bam"

    cpus 4
    memory '5 GB'
    time '25m'

    """
    samtools view -h -F4 ${bam} | samtools sort -m1G -@ ${task.cpus} -o ${coguk_id}.climb.bam
    """
}


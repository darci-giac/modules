process STAR_ALIGN {
    tag "$meta.id"
    label 'process_high'

    // Note: 2.7X indices incompatible with AWS iGenomes.
    conda (params.enable_conda ? 'bioconda::star=2.7.9a' : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/star:2.7.9a--h9ee0642_0' :
        'quay.io/biocontainers/star:2.7.9a--h9ee0642_0' }"

    input:
    tuple val(meta), path(reads)
    path  index
    path  gtf
    val star_ignore_sjdbgtf
    val seq_platform
    val seq_center

    output:
    tuple val(meta), path('*d.out.bam')       , emit: bam
    tuple val(meta), path('*Log.final.out')   , emit: log_final
    tuple val(meta), path('*Log.out')         , emit: log_out
    tuple val(meta), path('*Log.progress.out'), emit: log_progress
    path  "versions.yml"                      , emit: versions

    tuple val(meta), path('*sortedByCoord.out.bam')  , optional:true, emit: bam_sorted
    tuple val(meta), path('*toTranscriptome.out.bam'), optional:true, emit: bam_transcript
    tuple val(meta), path('*Aligned.unsort.out.bam') , optional:true, emit: bam_unsorted
    tuple val(meta), path('*fastq.gz')               , optional:true, emit: fastq
    tuple val(meta), path('*.tab')                   , optional:true, emit: tab
    tuple val(meta), path('*.out.junction')          , optional:true, emit: junction

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def ignore_gtf      = star_ignore_sjdbgtf ? '' : "--sjdbGTFfile $gtf"
    def seq_platform    = seq_platform ? "'PL:$seq_platform'" : ""
    def seq_center      = seq_center ? "--outSAMattrRGline ID:$prefix 'CN:$seq_center' 'SM:$prefix' $seq_platform " : "--outSAMattrRGline ID:$prefix 'SM:$prefix' $seq_platform "
    def out_sam_type    = (args.contains('--outSAMtype')) ? '' : '--outSAMtype BAM Unsorted'
    def mv_unsorted_bam = (args.contains('--outSAMtype BAM Unsorted SortedByCoordinate')) ? "mv ${prefix}.Aligned.out.bam ${prefix}.Aligned.unsort.out.bam" : ''
    """
    STAR \\
        --genomeDir $index \\
        --readFilesIn $reads  \\
        --runThreadN $task.cpus \\
        --outFileNamePrefix $prefix. \\
        $out_sam_type \\
        $ignore_gtf \\
        $seq_center \\
        $args

    $mv_unsorted_bam

    if [ -f ${prefix}.Unmapped.out.mate1 ]; then
        mv ${prefix}.Unmapped.out.mate1 ${prefix}.unmapped_1.fastq
        gzip ${prefix}.unmapped_1.fastq
    fi
    if [ -f ${prefix}.Unmapped.out.mate2 ]; then
        mv ${prefix}.Unmapped.out.mate2 ${prefix}.unmapped_2.fastq
        gzip ${prefix}.unmapped_2.fastq
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        star: \$(STAR --version | sed -e "s/STAR_//g")
    END_VERSIONS
    """
}

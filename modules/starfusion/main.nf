process STARFUSION {
    tag "$meta.id"
    label 'process_high'

    conda (params.enable_conda ? "bioconda::star-fusion=1.10.0" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/star-fusion:1.10.0--hdfd78af_1':
        'quay.io/biocontainers/star-fusion:1.10.0--hdfd78af_1' }"

    input:
    // TODO nf-core: Where applicable all sample-specific information e.g. "id", "single_end", "read_group"
    //               MUST be provided as an input via a Groovy Map called "meta".
    //               This information may not be required in some instances e.g. indexing reference genome files:
    //               https://github.com/nf-core/modules/blob/master/modules/bwa/index/main.nf
    // TODO nf-core: Where applicable please provide/convert compressed files as input/output
    //               e.g. "*.fastq.gz" and NOT "*.fastq", "*.bam" and NOT "*.sam" etc.
    tuple val(meta), path(reads)
    path index
    path reference
    path gtf
    val star_ignore_sjdbgtf
    val seq_platform
    val seq_center

    output:
    tuple val(meta), path("*.bam"), emit: bam
    tuple val(meta), path("*.fusion_predictions.tsv"), emit: fusion_predictions
    tuple val(meta), path("*abridged.tsv")           , emit: abridged_fusion_predictions
    path "versions.yml"                              , emit: versions

    tuple val(meta), path('*sortedByCoord.out.bam')  , optional:true, emit: bam_sorted
    tuple val(meta), path('*toTranscriptome.out.bam'), optional:true, emit: bam_transcript
    tuple val(meta), path('*Aligned.unsort.out.bam') , optional:true, emit: bam_unsorted
    tuple val(meta), path('*fastq.gz')               , optional:true, emit: fastq
    tuple val(meta), path('*.tab')                   , optional:true, emit: tab
    tuple val(meta), path('*.out.junction')          , optional:true, emit: junction
    
    script:
    def args = task.ext.args ?: ''
    def args2 = task.ext.args2 ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def ignore_gtf      = star_ignore_sjdbgtf ? '' : "--sjdbGTFfile $gtf"
    def seq_platform    = seq_platform ? "'PL:$seq_platform'" : ""
    def seq_center      = seq_center ? "--outSAMattrRGline ID:$prefix 'CN:$seq_center' 'SM:$prefix' $seq_platform " : "--outSAMattrRGline ID:$prefix 'SM:$prefix' $seq_platform "
    def out_sam_type    = (args.contains('--outSAMtype')) ? '' : '--outSAMtype BAM Unsorted'
    """
    STAR \\
        --genomeDir $index \\
        --readFilesIn $reads \\
        --runThreadN $task.cpus \\
        --outFileNamePrefix $prefix. \\
        $out_sam_type \\
        $ignore_gtf \\
        $seq_center \\
        $args \\

    STAR-Fusion \\
        --genome_lib_dir $reference \\
        -J Chimeric.out.junction \\
        --output_dir star_fusion_outdir \\
        --runThreadN $task.cpus \\
        $args2 \\

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        starfusion: \$(STAR-Fusion --version | sed -e "s/STAR-Fusion//g" )
    END_VERSIONS
    """
}

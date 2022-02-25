#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include { STARFUSION } from '../../../modules/starfusion/main.nf'

workflow test_starfusion {
    
    input = [
        [ id:'test', single_end:false ], // meta map
        [
            file(params.test_data['homo_sapiens']['illumina']['test_rnaseq_1_fastq_gz'], checkIfExists: true),
            file(params.test_data['homo_sapiens']['illumina']['test_rnaseq_2_fastq_gz'], checkIfExists: true)
        ]
    ]
    index = file('s3://rnd-complexome-data/NextFlow_Genome/GRCh37/STARIndex/*')
    gtf   = file(params.test_data['homo_sapiens']['genome']['genome_gtf'], checkIfExists: true)
    reference = file('s3://rnd-complexome-data/NextFlow_Genome/GRCh37/Star-Fusion/ctat_genome_lib_build_dir/*')
    star_ignore_sjdbgtf = false
    seq_platform = false
    seq_center = false

    STARFUSION ( input, index, reference, gtf, star_ignore_sjdbgtf, seq_platform, seq_center )
}

#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include { STARFUSION } from '../../../modules/starfusion/main.nf'

workflow test_starfusion {
    
    input = [ 
        [ id:'test', single_end:false ], // meta map
        file(params.test_data['sarscov2']['illumina']['test_paired_end_bam'], checkIfExists: true) 
    ]

    STARFUSION ( input )
}

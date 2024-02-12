#!/usr/bin/env nextflow 

// Enable DSL 2
nextflow.enable.dsl=2

// import processes for main workflow
include { validate } from "$projectDir/modules/validate.nf"
include { hairpinFilter } from "$projectDir/modules/hairpin.nf"
include { pindelFilter } from "$projectDir/modules/pindelFilter.nf"
include { cgpVaf } from "$projectDir/modules/cgpVaf.nf"
include { betaBinomFilterIndex } from "$projectDir/modules/betaBinomFilterIndex.nf"
include { betaBinomFilter } from "$projectDir/modules/betaBinomFilter.nf"

// validate parameters
validate(params)

workflow {
    String sample_paths = new File(params.sample_paths).getText('UTF-8')

    // Hairpin filtering for SNVs 
    if (params.mut_type=='snv') {
        vcfilter_config = (params.vcfilter_config=="") ? "${projectDir}/data/snv_default.filter" : params.vcfilter_config
        hairpin_input_ch = Channel.of(sample_paths)
            .splitCsv( header: true, sep : '\t' )
            .map { row -> tuple( row.sample_id, row.match_normal_id, row.pdid, row.vcf, row.vcf_tbi, row.bam, row.bai, row.bas, row.met, row.bam_match, row.bai_match ) }
        vcfiltered_ch = hairpinFilter(hairpin_input_ch, vcfilter_config)
    }
    
    // Quality filtering based on Pindel for Indels 
    if (params.mut_type=='indel') {
        vcfilter_config = (params.vcfilter_config=="") ? "${projectDir}/data/indel_default.filter" : params.vcfilter_config
        indel_input_ch = Channel.of(sample_paths)
            .splitCsv( header: true, sep : '\t' )
            .map { row -> tuple( row.sample_id, row.match_normal_id, row.pdid, row.vcf, row.bam, row.bai, row.bam_match, row.bai_match ) }
        vcfiltered_ch = pindelFilter(indel_input_ch, vcfilter_config)
    }

    // cgpVaf 
    cgpvaf_input_ch = vcfiltered_ch.groupTuple( by: 0 ) // group by PDID for cgpVaf
    cgpVaf_out_ch = cgpVaf(cgpvaf_input_ch, params.mut_type)
    // cgpVaf_out_ch = cgpVaf(cgpvaf_input_ch, params.mut_type, params.reference_genome, params.high_depth_region) // keeping this in case cgpVaf module changes such that absolute path is no longer required

    // BetaBinomial filtering for germline and LCM artefacts based on cgpVaf (methods by Tim Coorens)
    (beta_binom_index_ch, germline, somatic, rho) = betaBinomFilterIndex(cgpVaf_out_ch) // get the indices for the filtering 
    // use hairpin or pindel vcfiltered output to recover the donor-based channels from cgpVaf
    vcfiltered_relevant_ch = vcfiltered_ch
        .map( sample -> tuple(sample[0], sample[1], sample[2], sample[3], sample[4]) )
    beta_binom_filter_input_ch = beta_binom_index_ch.cross(vcfiltered_relevant_ch)
        .map( sample -> tuple(sample[0][0], sample[1][1], sample[1][2], sample[1][3], sample[1][4], sample[0][1]) )
    out = betaBinomFilter(beta_binom_filter_input_ch)
    out.subscribe onNext: { println "Finished ${it[0]}" }, onComplete: { println "Done" }

}
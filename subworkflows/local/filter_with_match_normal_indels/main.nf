include { pindelFilter } from "../../../modules/local/pindelFilter/main.nf"
include { cgpVaf } from "../../../modules/local/cgpVaf/main.nf"
include { betaBinomFilterIndexIndel } from "../../../modules/local/betaBinomFilterIndexIndel/main.nf"
include { betaBinomFilter } from "../../../modules/local/betaBinomFilter/main.nf"
include { matrixGeneratorOnSamples } from "../../../modules/local/matrixGeneratorOnSamples/main.nf"
include { sigprofilerPlotSnpBySamples } from "../../../modules/local/sigprofilerPlotSnpBySamples/main.nf"



workflow FILTER_WITH_MATCH_NORMAL_INDEL {
    take:
    sample_paths_content_ch
    vcfilter_config
    rho_threshold

    main:
    // setup
    mut_type = 'indel'
    

    // FILTER
    vcfiltered_ch = pindelFilter(sample_paths_content_ch, vcfilter_config, mut_type)


    // cgpVaf 
    cgpVaf_out_ch = cgpVaf(vcfiltered_ch.groupTuple( by: 0 ), mut_type)
    // cgpVaf_out_ch = cgpVaf(cgpvaf_input_ch, params.mut_type, params.reference_genome, params.high_depth_region) // keeping this in case cgpVaf module changes such that absolute path is no longer required

    // BetaBinomial filtering for germline and LCM artefacts based on cgpVaf (methods by Tim Coorens)
    (beta_binom_index_ch, germline, somatic, rho, phylogenetics_input_ch) = betaBinomFilterIndexIndel(cgpVaf.out, mut_type, rho_threshold) // get the indices for the filtering 
    // use hairpin vcfiltered output to recover the donor-based channels from cgpVaf
    vcfiltered_relevant_ch = vcfiltered_ch
        .map( sample -> tuple(sample[0], sample[1], sample[2], sample[3], sample[4]) )
    beta_binom_filter_input_ch = beta_binom_index_ch.cross(vcfiltered_relevant_ch)
        .map( sample -> tuple(sample[0][0], sample[1][1], sample[1][2], sample[1][3], sample[1][4], sample[0][1]) )
    betaBinomFilter(beta_binom_filter_input_ch, mut_type)

    betaBinomFilter.out.view()

    // generate mutation matrix for the samples by SigProfilerMatrixGenerator
    matrixGeneratorOnSamples(betaBinomFilter.out.toList(), mut_type)

    // plot spectra
    sigprofilerPlotSnpBySamples(matrixGeneratorOnSamples.out, mut_type)

    emit:
    phylogenetics_input_ch 
}
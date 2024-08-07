include { conpairPileup as conpairPileupSample } from "$projectDir/modules/conpairPileup.nf"
include { conpairPileup as conpairPileupMatch } from "$projectDir/modules/conpairPileup.nf"
include { conpairFilter } from "$projectDir/modules/conpairFilter.nf"
include { verifyConcordance } from "$projectDir/modules/verifyConcordance.nf"
include { conpairContamination } from "$projectDir/modules/conpairContamination.nf"

workflow CONPAIR_FILTER_WITH_MATCH_NORMAL {
    take:
    sample_paths

    main:
    sample_paths = new File(sample_paths).getText('UTF-8')

    // pileup
    // sample
    sample_pileup_input_ch = Channel.of(sample_paths)
            .splitCsv( header: true, sep : '\t' )
            .map { row -> tuple( row.match_normal_id, row.sample_id, row.bam, row.bai ) }
    pileup_sample = conpairPileupSample(sample_pileup_input_ch)
    // normal
    match_pileup_input_ch = Channel.of(sample_paths)
            .splitCsv( header: true, sep : '\t' )
            .map { row -> tuple( row.match_normal_id, row.match_normal_id, row.bam_match, row.bai_match ) }
            .unique()
    pileup_match = conpairPileupMatch(match_pileup_input_ch)

    // Concordance between sample and match normal
    concordance_input_ch = pileup_sample.combine(pileup_match)
        .map { sample -> tuple(sample[1], sample[2], sample[3], sample[5]) }
    concordance_output_ch = verifyConcordance(concordance_input_ch)
        .collectFile( name: 'conpair_out/concordance.txt', newLine: true )

    // Contamination 
    contamination_input_ch = pileup_match.cross(pileup_sample)
        .map { sample -> tuple(sample[0][0], sample[0][2], sample[1][1], sample[1][2]) }
    contamination_output_ch = conpairContamination(contamination_input_ch)
        .collectFile( name: 'conpair_out/contamination.txt', newLine: true )

    // Filtering contamination based on concordance and contamination
    (sample_paths_conpaired, conpair_log, concordance_path, contamination_path) = conpairFilter(concordance_output_ch, contamination_output_ch, params.sample_paths)


    emit: 
    sample_paths_conpaired
} 
include { conpairPileup as conpairPileupSample } from "../../../modules/local/conpairPileup/main.nf"
include { conpairPileup as conpairPileupMatch } from "../../../modules/local/conpairPileup/main.nf"
include { conpairFilter } from "../../../modules/local/conpairFilter/main.nf"
include { verifyConcordance } from "../../../modules/local/verifyConcordance/main.nf"
include { conpairContamination } from "../../../modules/local/conpairContamination/main.nf"

workflow CONPAIR_FILTER_WITH_MATCH_NORMAL {
    take:
    input
    marker_txt
    marker_bed
    fasta
    fasta_fai
    dict
    concordance_threshold
    contamination_threshold_samples
    contamination_threshold_match

    main:

    // pileup
    // sample
    sample_pileup_input_ch = Channel.of(input)
            .splitCsv( header: true )
            .map { row -> tuple( row.match_normal_id, row.sample_id, row.bam, row.bai ) }
    pileup_sample = conpairPileupSample(sample_pileup_input_ch, marker_bed, fasta, dict, fasta_fai)
    // normal
    match_pileup_input_ch = Channel.of(input)
            .splitCsv( header: true )
            .map { row -> tuple( row.match_normal_id, row.match_normal_id, row.bam_match, row.bai_match ) }
            .unique()
    pileup_match = conpairPileupMatch(match_pileup_input_ch, marker_bed, fasta, dict, fasta_fai)

    // concordance between sample and match normal
    concordance_input_ch = pileup_sample.combine(pileup_match)
        .map { sample -> tuple(sample[1], sample[2], sample[3], sample[5]) }
    concordance_output_ch = verifyConcordance(concordance_input_ch, marker_txt)
        .collectFile( name: 'conpair_out/concordance.txt', newLine: true )

    // contamination 
    contamination_input_ch = pileup_match.cross(pileup_sample)
        .map { sample -> tuple(sample[0][0], sample[0][2], sample[1][1], sample[1][2]) }
    contamination_output_ch = conpairContamination(contamination_input_ch, marker_txt)
        .collectFile( name: 'conpair_out/contamination.txt', newLine: true )

    // filtering contamination based on concordance and contamination
    (sample_paths_conpaired, conpair_log, concordance_path, contamination_path) = conpairFilter(concordance_output_ch, contamination_output_ch, input, concordance_threshold, contamination_threshold_samples, contamination_threshold_match)


    emit: 
    sample_paths_conpaired
} 
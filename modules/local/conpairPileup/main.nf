process conpairPileup {
    publishDir "${params.outdir}/conpair_out/pileup", overwrite: false

    input:
    tuple val(match_normal_id), val(sample_id), path(bam), path(bai)
    path(marker_bed)
    path(fasta)
    path(dict)
    path(fasta_fai)

    output:
    tuple val(match_normal_id), val(sample_id), path(pileup)

    script:
    pileup = "${sample_id}.pileup"
    """
    gatk --java-options -Xmx10g Pileup -R ${fasta} -I ${bam} -L ${marker_bed} -O ${pileup} -verbose -RF NotDuplicateReadFilter -RF CigarContainsNoNOperator -RF MatchingBasesAndQualsReadFilter
    """

}
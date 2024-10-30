process hairpin2Filter {
    publishDir "${params.outdir}/filter_snp_out/${pdid}",
        overwrite: false,
        pattern: "*.filter.vcf.gz"

    input:
    tuple val(sample_id), val(match_normal_id), val(pdid), path(vcf), 
          path(vcf_tbi), path(bam), path(bai), path(bas), path(bam_match),
          path(bai_match)
    path vcfilter_config

    output: 
    tuple val(pdid), val(sample_id), val(match_normal_id),
          path("${sample_id}_hairpin2.filter.vcf.gz"),
          path("${sample_id}_hairpin2.filter.vcf.gz.tbi"),
          path(bam), path(bai), path(bam_match), path(bai_match)

    script:
    """
    # modules
    module load hairpin2-alpha/hairpin2-0.0.2a-img-0.0.2
    module load vcfilter/1.0.4
    module load tabix/1.18

    # hairpin2
    hairpin2-alpha \\
        --vcf-in ${vcf} \\
        --vcf-out ${sample_id}_hairpin2.vcf \\
        --alignments ${bam} \\
        --format b \\
        --name-mapping TUMOUR:${sample_id}
    
    # filter
    vcfilter filter -o . -i ${vcfilter_config} ${sample_id}_hairpin2.vcf

    # bgzip and index
    bgzip ${sample_id}_hairpin2.filter.vcf
    tabix -p vcf ${sample_id}_hairpin2.filter.vcf.gz
    """
}
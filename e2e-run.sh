nextflow run . \
    --input test-data/samplesheet.csv \
    --outdir out/lowinputtrees/ \
    --marker_bed test-data/GRCh38.autosomes.phase3_shapeit2_mvncall_integrated.20130502.SNV.genotype.sselect_v4_MAF_0.4_LD_0.8.liftover.bed \
    --marker_txt test-data/GRCh38.autosomes.phase3_shapeit2_mvncall_integrated.20130502.SNV.genotype.sselect_v4_MAF_0.4_LD_0.8.liftover.txt \
    --genome GRCh38

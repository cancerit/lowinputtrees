include { getPhylogeny } from "../../../modules/local/getPhylogeny"
include { matrixGeneratorOnBranches } from "../../../modules/local/matrixGeneratorOnBranches"
include { concatMatrices } from "../../../modules/local/concatMatrices"
include { sigprofilerPlotSnpByBranches } from "../../../modules/local/sigprofilerPlotSnpByBranches"


workflow PHYLOGENETICS { // phylogenetics workflow for SNVs
    take: 
    phylogenetics_input_ch
    outdir_basename

    main: 
    (branched_vcf_with_header, topology, other_files, mpboot_log) = getPhylogeny(phylogenetics_input_ch, outdir_basename)

    // generate mutation matrix for the branches by SigProfilerMatrixGenerator
    matrixGeneratorOnBranches(branched_vcf_with_header, outdir_basename)
    concatMatrices(matrixGeneratorOnBranches.out.toList(), outdir_basename)
    // plotting
    // sigprofilerPlotSnpByBranches(concatMatrices.out, outdir_basename)

    emit:
    topology

}


rule abricate:
    input: 
        metadata = "{results_directory}/metadata.tsv",
        fasta = df["input_file_fasta"].tolist(),
    output:
        ncbi_detailed = "{results_directory}/abricate/ncbi_detailed.tsv",
        ncbi_sum = "{results_directory}/abricate/ncbi_summarized.tsv",
        card_detailed = "{results_directory}/abricate/card_detailed.tsv",
        card_sum = "{results_directory}/abricate/card_summarized.tsv",
        plasmidfinder_detailed = "{results_directory}/abricate/plasmidfinder_detailed.tsv",
        plasmidfinder_sum = "{results_directory}/abricate/plasmidfinder_summarized.tsv",
        vfdb_detailed = "{results_directory}/abricate/vfdb_detailed.tsv",
        vfdb_sum = "{results_directory}/abricate/vfdb_summarized.tsv",
    conda: "../envs/abricate.yaml"
    benchmark: "{results_directory}/benchmarks/benchmark.abricate.tsv"
    shell: """

        # TODO: update these databases

        abricate --db ncbi {input.fasta:q} > {output.ncbi_detailed:q}
        abricate --summary {output.ncbi_detailed:q} > {output.ncbi_sum:q}

        abricate --db card {input.fasta:q} > {output.card_detailed:q}
        abricate --summary {output.card_detailed:q} > {output.card_sum:q}
        
        abricate --db plasmidfinder {input.fasta:q} > {output.plasmidfinder_detailed:q}
        abricate --summary {output.plasmidfinder_detailed:q} > {output.plasmidfinder_sum:q}

        abricate --db vfdb {input.fasta:q} > {output.vfdb_detailed:q}
        abricate --summary {output.vfdb_detailed:q} > {output.vfdb_sum:q}

        {void_report}
    """
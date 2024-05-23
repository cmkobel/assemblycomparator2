
    
        
        
def get_mem_panaroo(wildcards, attempt): 
    return [32000, 64000, 128000][attempt-1]


# Maybe it shouldn't be panaroo which is the checkpoint, but rather every rule that uses the core genome, like rule snp_dists? Let me try!
checkpoint panaroo: # Checkpoint, because some rules i.e. fasttree, iqtree, snp-dists should only run if the core genome is non-empty.
    input: 
        metadata = "{results_directory}/metadata.tsv",
        gff = expand("{results_directory}/samples/{sample}/prokka/{sample}.gff", sample = df["sample"], results_directory = results_directory),
    output:
        summary = "{results_directory}/panaroo/summary_statistics.txt",
        presence = "{results_directory}/panaroo/gene_presence_absence.csv",
        alignment = "{results_directory}/panaroo/core_gene_alignment.aln",
        #analyses = ["{results_directory}/panaroo/summary_statistics.txt", "{results_directory}/panaroo/core_gene_alignment.aln", "{results_directory}/panaroo/gene_presence_absence.csv"]
    params: # Possibly make this editable from the CLI.
        sequence_identity_threshold = "0.98", # default
        core_genome_sample_threshold = "0.95", # default
        clean_mode = "sensitive", # default
        protein_family_sequence_identity_threshold = "0.7", # default
        
    benchmark: "{results_directory}/benchmarks/benchmark.panaroo.tsv"
    threads: 16
    #retries: 2
    resources:
        #mem_mb = 32768,
        mem_mb = get_mem_panaroo,
        runtime = "24h",
    conda: "../envs/panaroo.yaml" # deactivated 
    shell: """
    

        # Collect version number.
        panaroo --version > "$(dirname {output.summary})/.software_version.txt"

        panaroo \
            -i {input.gff:q} \
            -o {wildcards.results_directory}/panaroo \
            -a core \
            --threshold {params.sequence_identity_threshold} \
            --clean-mode {params.clean_mode} \
            --core_threshold {params.core_genome_sample_threshold} \
            -f {params.protein_family_sequence_identity_threshold} \
            -t {threads}
            
            
        #touch {output} # DEBUG
            
        {void_report}

    """
    

def core_genome_if_exists(wildcards): 
    
    summary_file = checkpoints.panaroo.get(**wildcards).output["summary"]
    alignment_file = checkpoints.panaroo.get(**wildcards).output["alignment"]
    
    try:   
        with summary_file.open() as f:
        #with open(file) as f: 

            for line in f:
                line = line.strip()
                #print(f"line: {line}")
                
                # Find the line that states the size of the core genome.
                if "Core genes" in line:
                    #print(f"Pipeline: Parsing Panaroo core genome from line \"{line}\"")
                    splitted = line.split("\t")
                    #print(splitted)
                    core_genome_size = int(splitted[-1])
                    
                    #print(f"Pipeline: Parsed core genome size is: {repr(core_genome_size)}")
                    break
                
            # Return alignment file when there is a core genome.
            if core_genome_size > 0:
                print(f"Pipeline: Core genome exists ({core_genome_size} genes).")
                return [alignment_file]
                
            # Otherwise, return an empty list.
            else:
                print(f"Pipeline: Core genome is empty ({core_genome_size} genes).")
                return list()
                
                
    # In case the file cannot be parsed, we're assuming that there is no core genome. Hence return empty list.
    except Exception as e: 
        print(f"Pipeline Error: {e}") # Show errors in parsing the panaroo summary, but don't fail.
        print("Pipeline: Core genome size not known?")
        return list() # Empty list
        



rule compute_snp_dists:
    input: 
        metadata = "{results_directory}/metadata.tsv",
        aln = core_genome_if_exists,
    output: "{results_directory}/snp-dists/snp-dists.tsv"
    conda: "../envs/snp-dists.yaml"
    benchmark: "{results_directory}/benchmarks/benchmark.snp_dists.tsv"
    threads: 4
    shell: """
    
        # Collect version number.
        snp-dists -v > "$(dirname {output})/.software_version.txt"

        snp-dists \
            -j {threads} \
            {input.aln:q} > {output:q}

        {void_report}
        
    """

# This is a dummy rule that forces recomputation of the DAG after the core genome alignment has been produced. It solves a possibly known error in snakemake which I could possibly mitigate by updating snakemake. But since I'm already testing a lot of other features, I cannot take the burden of also changing snakemake version so this is the workaround for now.
rule snp_dists:
    input: "{results_directory}/snp-dists/snp-dists.tsv"
    output: touch("{results_directory}/snp-dists/.done.flag")
    shell: """
        exit 0
    """

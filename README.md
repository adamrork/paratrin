# Paratrin
A Bash wrapper for the Trinity RNA-Seq transcriptome assembler that dynamically generates and executes commands in parallel.

# Installation
Paratrin is a Bash script and requires no installation. You can obtain Paratrin by cloning this repository with the following command:

```
git clone https://github.com/adamrork/Paratrin.git
```

# Dependencies
Paratrin was developed for Linux operating systems and should work on most distributions. It has been tested on CentOS 7 and Ubuntu 19.04, specifically. Besides Bash and the standard GNU/Linux utilities, it has the following dependencies:<br/>

**Required:**
```
  GNU Parallel (tested w/ 20220522)
  Trinity RNA-Seq (tested w/ 2.15.1 & 2.15.2)
```

**Optional:**
```
  Apptainer (tested w/ 1.3.0)
  or
  Singularity (tested w/ 3.8.6)
```

### Installation
Please consult [the official GNU Parallel documentation](https://www.gnu.org/software/parallel/), [the official Trinity RNA-Seq documentation](https://github.com/trinityrnaseq/trinityrnaseq/wiki), and [the official Singularity documentation](https://docs.sylabs.io/guides/3.0/user-guide/index.html) or [the official Apptainer documentation](https://apptainer.org/docs/user/latest/) for information on how to install each program.

You may also choose to install these programs and their dependencies via conda:
```
conda install -c conda-forge parallel
conda install -c bioconda trinity

conda install -c conda-forge apptainer
or
conda install -c conda-forge singularity
```

If you wish to run Trinity via Apptainer/Singularity, the official Trinity Singularity Image can be downloaded from the Broad Institute's [Trinity Singularity Image Archive](https://data.broadinstitute.org/Trinity/TRINITY_SINGULARITY/). Hereafter, Apptainer/Singularity will be referred to as Singularity.

# Introduction
Trinity RNA-Seq is among the most popular transcriptome assemblers due to its user-friendliness and the high-quality assemblies it produces. Like many such programs, Trinity is often used to assemble multiple datasets for large biomedical, ecological, and evolutionary projects. Sequentially assembling several transcriptomes requires carefully crafting and curating commands and may require significant runtime. It is not unusual for such projects to take hours, days, or even weeks to complete, depending on their size, complexity, and the computational resources available.

Paratrin can significantly reduce the time spent creating and running Trinity RNA-Seq commands by dynamically generating and executing several simultaneously via GNU Parallel. It supports all Trinity assembly modes, including single-end, paired-end, samples files, genome-guided, and short/long reads hybrid assemblies. Practically all Trinity options are settable through the command line, most mirroring Trinity naming conventions for ease of use. Paratrin can use either a local installation of Trinity or Trinity via Singularity. In dry run mode, results directories and a file of Trinity commands are created, usually in a matter of seconds, for review before full runs.

Paratrin v0.5.0 is the first public beta release and is under active development. Please feel free to fork this repository, contribute your thoughts and suggestions, and report bugs in the Issues tab. Paratrin is neither affiliated with, endorsed by, nor supported by the official Trinity RNA-Seq project, the official GNU Parallel project, or their authors.

# Basic Command Formatting
Your commands may only contain alphanumerics, spaces, and the following characters: `_ - / \ " ' : , .`

Dollar signs (`$`) are allowed insofar as they are used to specify environmental variables (e.g., `"$FOO"`)

Path names should ideally contain only alphanumerics, hyphens, underscores, periods, and forward slashes. Although data filenames are not explicitly provided as arguments to Paratrin, they must also conform to these standards and will ideally consist of alphanumerics, hyphens, underscores, and periods only.

# Input Data Organization

### Single-end, samples files, and bam data
For standard assemblies, all files to be analyzed in a single Paratrin run must be within a single input directory. All single-end files, samples files, and bam files in a directory must have unique basenames and identical filename suffixes. Consider the following three directories containing single-end data, samples files, and bam data:

```
single_dir/           samples_dir/          bam_dir/
  species_A.fq          sample_D.txt          species_G.bam
  species_B.fq          sample_E.txt          species_H.bam
  species_C.fq          sample_F.txt          species_I.bam
```
Here,
- The single-end basenames are species_A - species_C
- The samples file basenames are sample_D - sample_F
- The bam file basenames are species_G - species_I
- The common single-end suffix is ".fq"
- The common samples file suffix is ".txt"
- The common bam file suffix is ".bam"

### Paired-end data
For paired-end data, each pair of files must have a unique basename shared by both files in each pair. Filename suffixes must contain information identifying which file is first in each pair (left) and which is second in each pair (right), such as "_R1.fq" and "_R2.fq", respectively. All first/left file suffixes in a directory must be identical, as should all second/right file suffixes. Consider the following directory containing paired-end data:

```
paired_dir/
  species_J_R1.fq  species_J_R2.fq
  species_K_R1.fq  species_K_R2.fq
  species_L_R1.fq  species_L_R2.fq
```
Here,
- The basenames are species_J - species_L
- The common left-file suffix is "_R1.fq"
- The common right-file suffix is "_R2.fq"

### Long, error-corrected data
For hybrid assemblies, long reads data and short reads data should ideally be in separate directories. The same file naming conventions that apply to single-end and bam data apply to long reads fasta and long bam data. The filename suffixes for long reads and long bam data may differ from those of the short reads data, but the basenames of the files to be co-assembled must match. Consider the following directories containing long reads data and long bam data:
```
long_reads_dir/          long_bam_dir/
  species_A.LR.fa          species_G.LR.bam
  species_B.LR.fa          species_H.LR.bam
  species_C.LR.fa          species_I.LR.bam
```
Here,
- The long reads basenames are species_A - species_C
- The long bam basenames are species_G - species_I
- The common long reads suffix is ".LR.fa"
- The common long bam suffix is ".LR.bam"

Since the basenames of the long reads data mirror their short reads counterparts, one would be able to co-assemble the above single-end data with the corresponding long reads data and the same for the short and long bam data. If, however, the long reads file species_A.LR.fa were renamed species_X.LR.fa, it would cease to have a short-read counterpart in species_A.fq. As a result, no assembly would occur using either file, although assemblies would proceed for species_B and species_C.

# Options
```
Wrapper Options                 Arguments         Descriptions
 --input_dir                     <str>             Path to input short reads data or samples files directory
 --long_data_dir                 <str>             Path to input long reads data directory
 --output_dir                    <str>             Path to preferred output directory
 --single_suffix                 <str>             Suffix for single end files
 --left_suffix                   <str>             Suffix for 'left' paired-end files
 --right_suffix                  <str>             Suffix for 'right' paired-end files
 --samples_suffix                <str>             Suffix for samples files
 --bam_suffix                    <str>             Suffix for bam files
 --long_reads_suffix             <str>             Suffix for long reads files
 --long_bam_suffix               <str>             Suffix for long bam files
 --jobs                          <int>             Number of jobs to run in parallel
 --extra_options                 <str>             Additional options & arguments to pass to Trinity, between ""
 --singularity_image             <str>             Path to a Trinity Singularity Image File
 --dry_run                       none              Set to generate directories and commands only - do not run Trinity
 --help                          none              Print a help message
 --version                       none              Print version and license information

Standard Trinity Options
 --seqType                       <str>             Specify whether your data are in FASTA (fa) or FASTQ (fq) format
 --SS_lib_type                   <str>             If your data are stranded, specify how (R, F, RF, or FR)
 --min_contig_length             <int>             Minimum assembled contig length to report
 --genome_guided_max_intron      <int>             Maximum allowed intron length / fragment span
 --jaccard_clip                  none              Set to run jaccard clip
 --trimmomatic                   none              Set to run trimmomatic before assembly
 --full_cleanup                  none              Set to retain only the Trinity fasta file
 --run_as_paired                 none              Set to analyze interleaved paired-end data in single-end mode
 --CPU                           <int>             Number of CPUs per Trinity job
 --max_memory                    <str>             Maximum amount of memory per Trinity job

Special Trinity Options
 --quality_trimming_params       <str>             Options & arguments to pass to Trimmomatic, between '' or ""
 --bfly_opts                     <str>             Options & arguments to pass to Butterfly, between '' or ""
 --grid_exec                     <str>             Options & arguments to pass to HPC GridRunner, between '' or ""
 --singularity_extra_params      <str>             Options & arguments to pass to Singularity, between '' or ""

Required Options
 For all analyses:               --input_dir, --output_dir, --jobs, --seqType, --max_memory
 For single-end mode:            --single_suffix
 For paired-end mode:            --left_suffix, --right_suffix
 For samples file mode:          --samples_suffix
 For genome-guided mode:         --bam_suffix, --genome_guided_max_intron
```

Please consult [the official Trinity RNA-Seq documentation](https://github.com/trinityrnaseq/trinityrnaseq/wiki) or run `Trinity --show_full_usage_info` from your terminal for more information on setting various Trinity options.

# Usage Examples

Please note, the options and arguments passed to Paratrin will populate all generated commands with the same arguments aside from the input files and results directories. If you wish to assemble various datasets, each with different arguments, you will need to start multiple runs, one per argument set. For example, if you aim to assemble a stranded dataset and an unstranded dataset, you will need two commands: one with `--SS_lib_type <ARG>` set and one without.

## Basic Usage
The following examples reference the directories and files in the **Input Data Organization** section.

### Single-end assembly mode
The following command would start three parallel assemblies for the species_A, species_B, and species_C data in `single_end_dir/`:
```
bash Paratrin.sh \
        --input_dir /path/to/single_end_dir/ --output_dir /path/to/single_outdir/ \
        --single_suffix .fq --jobs 3 --seqType fq --max_memory 4G
```

### Paired-end assembly mode
The following command would start three parallel assemblies for the species_J, species_K, and species_L data in `paired_end_dir/`:
```
bash Paratrin.sh \
        --input_dir /path/to/paired_end_dir/ --output_dir /path/to/paired_outdir/ \
        --left_suffix _R1.fq --right_suffix _R2.fq --jobs 3 --seqType fq --max_memory 4G
```

### Samples file assembly mode
The following command would start three parallel assemblies for the sample_D, sample_E, and sample_F data in `samples_dir/`:
```
bash Paratrin.sh \
        --input_dir /path/to/samples_dir/ --output_dir /path/to/sample_outdir/ \
        --samples_suffix .txt --jobs 3 --seqType fq --max_memory 4G
```

### Genome-guided assembly mode
The following command would start three parallel assemblies for the species_G, species_H, and species_I data in `bam_dir/`:
```
bash Paratrin.sh \
        --input_dir /path/to/bam_dir/ --output_dir /path/to/bam_outdir/ \
        --bam_suffix .bam  --genome_guided_max_intron 10000 --jobs 3 --seqType fq --max_memory 4G
```

## Other Usage Strategies

### Hybrid assembly
To incorporate long reads data into single-end, paired-end, or samples files analyses, you may add the options:
```
bash Paratrin.sh [core opts] --long_data_dir /path/to/long_reads_dir/ --long_reads_suffix .LR.fa
```

To incorporate long bam data into genome-guided analyses, you may add the options:
```
bash Paratrin.sh [core opts] --long_data_dir /path/to/long_bam_dir/ --long_bam_suffix .LR.bam
```

### Performing dry runs
Before starting full Trinity runs, it is strongly recommended that a dry run of Paratrin first be performed by setting the `--dry_run` option. Dry runs should only take a few seconds and generate all Trinity commands and results directories without running Trinity itself. You may review these outputs, and if satisfactory, you may delete them, unset `--dry_run`, and restart your analysis.
```
bash Paratrin.sh [core opts] --dry_run
```

### Running Trinity via Singularity
Paratrin looks for Trinity in your PATH by default. If you would prefer to run Trinity via Singularity, you may do so by providing the path to your Trinity Singularity Image File to the `--singularity_image` option:
```
bash Paratrin.sh [core opts] --singularity_image /path/to/trinityrnaseq.v2.15.2.simg
```

### Using extra Trinity options
If you wish to run Trinity using options not listed in the **Options** section, you may use the `--extra_options` option. Importantly, the argument passed to `--extra_options` must be within double quotes. Consider the following example, which sets both `--min_kmer_cov 2` and `--min_glue 3`:
```
bash Paratrin.sh [core opts] --extra_options "--min_kmer_cov 2 --min_glue 3"
```
The requirement to enclose arguments within double quotes also applies to the four options: `--quality_trimming_params`, `--bfly_opts`, `--grid_exec`, and `--singularity_extra_params`


### Help messages and version information
To print a help message or version and license information, you may use the commands below, respectively:
```
bash Paratrin.sh --help
bash Paratrin.sh --version
```

# Results
Your results will be at the path passed to `--output_dir`. Within this directory, you should find one or more Trinity results directories named `basename_trinity_assembly/`, where *basename* is the basename of the data file(s) assembled. You will also find a `Paratrin_output/` directory that contains a file named `mode_trinity_commands.txt`, where *mode* is either paired, single, samples, or bam. This file will contain each Trinity command generated, one per line. For example, as written, the example under **Single-end assembly mode** would produce the following directories in `/path/to/single_outdir/`:
```
single_outdir/
  Paratrin_output/
  species_A_trinity_assembly/
  species_B_trinity_assembly/
  species_C_trinity_assembly/
```

The Trinity commands generated by this Paratrin command would be as follows, wrapped here for clarity:
```
Trinity --single /path/to/single_end_dir/species_A.fq \
        --output /path/to/single_outdir/species_A_trinity_assembly/ \
        --seqType fq --max_memory 4G

Trinity --single /path/to/single_end_dir/species_B.fq \
        --output /path/to/single_outdir/species_B_trinity_assembly/ \
        --seqType fq --max_memory 4G

Trinity --single /path/to/single_end_dir/species_C.fq \
        --output /path/to/single_outdir/species_C_trinity_assembly/ \
        --seqType fq --max_memory 4G
```

For more information on the contents of Trinity results directories, please consult [the official Trinity RNA-Seq documentation](https://github.com/trinityrnaseq/trinityrnaseq/wiki).

# Considerations
- Trinity can be resource-intensive, and running several jobs in parallel may use significant computational resources. It is recommended that users carefully consider the resources available on their systems before running Trinity through Paratrin. Running Paratrin on a high-performance computing cluster or a desktop built for such tasks is recommended for massively parallelized projects.

- Paratrin does not currently support running Trinity via Docker. For now, please consider using the official Singularity Trinity Image if you need to use a container.

- Standard Trinity users may specify comma-delimited lists of files as inputs, which will be co-assembled. This convention is useful for assembling data split across multiple sequencing lanes. For example, consider the following directory of gzipped FASTQ data:
```
data_dir/
  species_A_L001.fq.gz
  species_A_L002.fq.gz
```

A typical Trinity command to co-assemble these files may look like:
```
Trinity --single species_A_L001.fq.gz,species_A_L002.fq.gz --output /path/to/outdir/ --seqType fq --max_memory 4G
```

Currently, there is no analogous feature in Paratrin, although there are workarounds such as concatenating files pre-assembly. Concatenation is arguably better practice than creating comma-delimited lists, as it reduces command complexity. The `cat` command may be used to concatenate gzipped files directly. Using `zcat` to pipe uncompressed data into gzip will yield slightly better compression. Examples of each strategy are below:
```
cat species_A_L001.fq.gz species_A_L002.fq.gz > species_A.fq.gz
zcat species_A_L001.fq.gz species_A_L002.fq.gz | gzip > species_A.fq.gz
```
Alternatively, you may create a samples file with the above files specified within.

- Currently, data specified in samples files must include the full paths to said data files.
```
cond_A  A_BR1  /path/to/A_BR1.fq
cond_A  A_BR2  /path/to/A_BR2.fq
cond_B  B_BR1  /path/to/B_BR1.fq
cond_B  B_BR2  /path/to/B_BR2.fq
```

# Future Development
The following features are planned for future releases:
- Add a feature to group sets of files into one command based on common filename patterns.
- Add a feature to run Trinity through Docker, similar to how Singularity is invoked.
- Add a feature to auto-detect filename suffixes given a directory of files.
- Add a feature to easily restart failed Trinity runs in parallel.
- Allow for samples files without full file paths to be used.
- Upload small test datasets for users to perform analyses with.
- Test on Rocky Linux 8, RHEL 8, and add support and documentation for macOS.
- Test with older versions of dependencies.

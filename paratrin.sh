#!/bin/bash

#######################################
##          PARATRIN v0.5.0          ##
##        BSD 3-Clause License       ##
##  Copyright (C) 2025 Adam M. Rork  ##
#######################################

##############################################################
#                           NOTICE                           #
##############################################################
#                                                            #
# This wrapper script is in no way affiliated with, endorsed #
# by, or supported by the official Trinity RNA-Seq project,  #
# the official GNU Parallel project, or their authors. It is #
# an independent project that aims to streamline the batch   #
# assembly of RNA-Seq data by facilitating the automated     #
# generation and parallelized execution of Trinity commands  #
# using GNU Parallel.                                        #
#                                                            #
##############################################################

##############################################################
#                 Paratrin Design Philosophy                 #
##############################################################
#                                                            #
#  1. There has been a genuine effort to sanitize and        #
#     otherwise validate user inputs and final commands.     #
#  2. There is a strong preference for positive logic,       #
#     explicitness, and clarity over brevity.                #
#  3. There is an ongoing effort to support as many          #
#     features of Trinity RNA-Seq v2.X.X as possible.        #
#  4. There is an ongoing effort to make the use of this     #
#     script seamless for regular Trinity RNA-Seq users.     #
#  5. The advanced error handling of Trinity is relied       #
#     upon to handle most option incompatibilities, etc.     #
#                                                            #
#     Please note that this is a beta release (v0.5.0).      #
#                                                            #
##############################################################

############################
### SETTINGS & VARIABLES ###
############################

## NOTE ##
## Within GNU parallel subshells, the invocation of set below is seemingly not respected. ##
## Therefore, we will re-enable it within each GNU parallel subshell, independently. ##
## We also briefly disable and re-enable set -e in the parameter parsing section. ##

# Exit the script if any commands fail, pipes fail, or if undefined variables are referenced. #
set -eou pipefail

# Whitelist of characters allowed in your arguments and commands. #
export CHAR_WHITELIST="A-Za-z0-9\"\'\ \-_:,./\\\\"

# Set most getopt-settable variables to empty strings by default. #
INPUT_DIR=""
LONG_DATA_DIR=""
OUTPUT_DIR=""
SINGLE_SUFFIX=""
LEFT_SUFFIX=""
RIGHT_SUFFIX=""
SAMPLES_SUFFIX=""
BAM_SUFFIX=""
LONG_READS_SUFFIX=""
LONG_BAM_SUFFIX=""
NUM_JOBS=""
EXTRA_OPTIONS=""
SINGULARITY_IMAGE=""
SEQ_TYPE=""
SS_LIB_TYPE=""
MIN_CONTIG_LENGTH=""
GG_MAX_INTRON=""
JACCARD_CLIP=""
TRIMMOMATIC=""
FULL_CLEANUP=""
RUN_AS_PAIRED=""
CPU=""
MAX_MEMORY=""
QT_PARAMETERS=""
BFLY_OPTS=""
GRID_EXEC=""
SINGULARITY_PARAMETERS=""

# Assume users want their Trinity commands to be run by default. #
DRY_RUN="OFF"

# Assume users are working with a standard installation of Trinity by default. #
TRINITY_EXEC="Trinity"

##########################
### DEFINING FUNCTIONS ###
##########################

# Function that prints a comprehensive, well-formatted help message to stdout. #
help_message() {
  printf "\n%s\n\n" "PARATRIN v0.5.0"

  printf "%s\n" "Please consult the official Trinity RNA-Seq documentation for information on how to set Trinity parameters."
  printf "%s\n\n" " Official Trinity RNA-Seq documentation: https://github.com/trinityrnaseq/trinityrnaseq/wiki"

  printf "%-30s\n" "##########################"
  printf "%-30s\n" "## BASIC USAGE EXAMPLES ##"
  printf "%-30s\n\n" "##########################"

  printf "%s\n" " # All commands must contain the following core options. #"
  printf "%s\n" " #"
  printf "%-30s%s\n" " # Core options:" "$0 --input_dir <ARG> --output_dir <ARG> --jobs <ARG> --seqType <ARG> --max_memory <ARG> [mode opts] [opts]"
  printf "%s\n\n" " #"

  printf "%s\n" " # In addition to the core options, all commands must include options of one of the following analysis modes. #"
  printf "%s\n" " #"
  printf "%-30s%s\n" " # Single-end mode:" "$0 [core opts] --single_suffix <ARG> [opts]"
  printf "%-30s%s\n" " # Paired-end mode:" "$0 [core opts] --left_suffix <ARG> --right_suffix <ARG> [opts]"
  printf "%-30s%s\n" " # Samples file mode:" "$0 [core opts] --samples_suffix <ARG> [opts]"
  printf "%-30s%s\n" " # Genome-guided mode:" "$0 [core opts] --bam_suffix <ARG> --genome_guided_max_intron <ARG> [opts]"
  printf "%s\n\n" " #"

  printf "%s\n" " # You may incorporate long, error-corrected read data into your analyses using the options below. #"
  printf "%s\n" " #"
  printf "%-30s%s\n" " # Long mapped reads:" "$0 [core opts] [mode opts] --long_data_dir <ARG> --long_reads_suffix <ARG> [opts]"
  printf "%-30s%s\n" " # Long unmapped reads:" "$0 [core opts] [mode opts] --long_data_dir <ARG> --long_bam_suffix <ARG> [opts]"
  printf "%s\n\n" " #"

  printf "%s\n" " # To perform a dry run in which commands and directories are generated but Trinity is not run. #"
  printf "%s\n" " #"
  printf "%-30s%s\n" " # Using dry run mode:" "$0 [core opts] [mode opts] --dry_run [opts]"
  printf "%s\n\n" " #"

  printf "%s\n" " # You may run Trinity using Singularity by providing the path to your Trinity Singularity Image file, as seen below. #"
  printf "%s\n" " #"
  printf "%-30s%s\n" " # Using Singularity:" "$0 [core opts] [mode opts] --singularity_image /path/to/trinityrnaseq.simg [opts]"
  printf "%s\n\n" " #"

  printf "%s\n" " # You may set any Trinity options not found in this help message using --extra_options, as seen below. #"
  printf "%s\n" " #"
  printf "%-30s%s\n" " # Using extra options:" "$0 [core opts] [mode opts] --extra_options \"--trinity_opt_A <ARG> --trinity_opt_B <ARG>\" [opts]"
  printf "%s\n\n" " #"

  printf "%-30s\n" "######################"
  printf "%-30s\n" "## PARATRIN OPTIONS ##"
  printf "%-30s\n\n" "######################"

  printf "%-30s%-20s%-50s\n" "WRAPPER OPTIONS" "ARGUMENTS" "DESCRIPTIONS"
  printf "%-30s%-20s%-50s\n" " --input_dir" " <str>" " Path to the directory containing short reads FASTA, FASTQ, BAM, or samples files"
  printf "%-30s%-20s%-50s\n" " --long_data_dir" " <str>" " Path to the directory containing long reads data or long bam data, if applicable"
  printf "%-30s%-20s%-50s\n" " --output_dir" " <str>" " Path to your preferred output directory"
  printf "%-30s%-20s%-50s\n" " --single_suffix" " <str>" " Suffix for single-end files"
  printf "%-30s%-20s%-50s\n" " --left_suffix" " <str>" " Suffix for 'left' paired-end files"
  printf "%-30s%-20s%-50s\n" " --right_suffix" " <str>" " Suffix for 'right' paired-end files"
  printf "%-30s%-20s%-50s\n" " --samples_suffix" " <str>" " Suffix for samples files"
  printf "%-30s%-20s%-50s\n" " --bam_suffix" " <str>" " Suffix for bam files"
  printf "%-30s%-20s%-50s\n" " --long_reads_suffix" " <str>" " Suffix for long, error-corrected reads files"
  printf "%-30s%-20s%-50s\n" " --long_bam_suffix" " <str>" " Suffix for long, error-corrected bam files"
  printf "%-30s%-20s%-50s\n" " --jobs" " <int>" " Number of jobs to run in parallel"
  printf "%-30s%-20s%-50s\n" " --extra_options" " <str>" " Specify additional options and arguments for Trinity within \"\""
  printf "%-30s%-20s%-50s\n" " --singularity_image" " <str>" " Path to a Trinity singularity image file"
  printf "%-30s%-20s%-50s\n" " --dry_run" " none" " Set to generate directories and commands only - do not run Trinity"
  printf "%-30s%-20s%-50s\n" " --help" " none" " Print this help message"
  printf "%-30s%-20s%-50s\n\n" " --version" " none" " Print version and license information"

  printf "%-30s%-20s%-50s\n" "STANDARD TRINITY OPTIONS" "ARGUMENTS" "DESCRIPTIONS"
  printf "%-30s%-20s%-50s\n" " --seqType" " <str>" " Specify whether your reads are in FASTA (fa) or FASTQ (fq) format"
  printf "%-30s%-20s%-50s\n" " --SS_lib_type" " <str>" " If your data are stranded, specify orientation (R, F, RF, or FR)"
  printf "%-30s%-20s%-50s\n" " --min_contig_length" " <int>" " Minimum assembled contig length to report"
  printf "%-30s%-20s%-50s\n" " --genome_guided_max_intron" " <int>" " Maximum allowed intron length / fragment span"
  printf "%-30s%-20s%-50s\n" " --jaccard_clip" " none" " Set to run jaccard_clip"
  printf "%-30s%-20s%-50s\n" " --trimmomatic" " none" " Set to run Trimmomatic before assembly"
  printf "%-30s%-20s%-50s\n" " --full_cleanup" " none" " Set to retain only the Trinity fasta file"
  printf "%-30s%-20s%-50s\n" " --run_as_paired" " none" " Set to analyze interleaved paired-end data in single-end mode"
  printf "%-30s%-20s%-50s\n" " --CPU" " <int>" " Number of CPUs per Trinity job"
  printf "%-30s%-20s%-50s\n\n" " --max_memory" " <str>" " Maximum amount of memory per Trinity job"

  printf "%-30s%-20s%-50s\n" "SPECIAL TRINITY OPTIONS" "ARGUMENTS" "DESCRIPTIONS"
  printf "%-30s%-20s%-50s\n" " --quality_trimming_params" " <str>" " Options & arguments to pass to Trimmomatic within '' or \"\""
  printf "%-30s%-20s%-50s\n" " --bfly_opts" " <str>" " Options & arguments to pass to Butterfly within '' or \"\""
  printf "%-30s%-20s%-50s\n" " --grid_exec" " <str>" " Options & arguments to pass to HPC GridRunner within '' or \"\""
  printf "%-30s%-20s%-50s\n\n" " --singularity_extra_params" " <str>" " Options & arguments to pass to Singularity within '' or \"\""

  printf "%s\n" "REQUIRED OPTIONS SUMMARY"
  printf "%-30s%s\n" " For all analyses:" " --input_dir, --output_dir, --jobs, --seqType, --max_memory"
  printf "%-30s%s\n" " For single-end mode:" " --single_suffix"
  printf "%-30s%s\n" " For paired-end mode:" " --left_suffix, --right_suffix"
  printf "%-30s%s\n" " For samples file mode:" " --samples_suffix"
  printf "%-30s%s\n\n" " For genome-guided mode:" " --bam_suffix, --genome_guided_max_intron"

  printf "%-30s\n" "#################"
  printf "%-30s\n" "## USAGE NOTES ##"
  printf "%-30s\n\n" "#################"

  printf "%s\n" " - It is strongly recommended to set the --dry_run option and to check all generated commands before running full analyses."
  printf "%s\n" " - The options used in each analysis mode are mutually exclusive with the options used in the other three analysis modes."
  printf "%s\n" " - For now, all samples files must include the full paths to short reads data, not just the filenames themselves."
  printf "%s\n" " - The --long_reads_suffix option is only compatible with paired-end, single-end, and samples file mode."
  printf "%s\n" " - The --long_bam_suffix option is only compatible with genome-guided mode."
  printf "%s\n\n" " - The --run_as_paired option is only compatible with single-end mode."

}

# Function that prints version, license, and authorship information to stdout. #
version_message() {
  printf "\n%s\n" "paratrin v0.5.0"
  printf "%s\n" "BSD 3-Clause License"
  printf "%s\n\n" "Copyright (C) 2025 Adam M. Rork"
}

# Function that ensures all core options have been set. #
core_settings() {
  [[ -d "$INPUT_DIR" && -d "$OUTPUT_DIR" \
  && -n "$NUM_JOBS" && -n "$SEQ_TYPE" && -n "$MAX_MEMORY" ]]
}

## NOTE ##
## It is possible to run Trinity with [--samples AND --single] or [--samples AND --left/--right] set. ##
## However, it is far better practice to include all data files to be assembled in one samples file. ##
## The functions below will help enforce the mutual exclusivity of these and other option pairings. ##

# Function that evaluates to true if single-end mode options and no mutually exclusive options are set. #
single_settings() {
  [[ -n "$INPUT_DIR" \
  && -n "$SINGLE_SUFFIX" \
  && -z "$LEFT_SUFFIX" && -z "$RIGHT_SUFFIX" \
  && -z "$SAMPLES_SUFFIX" \
  && -z "$BAM_SUFFIX" && -z "$GG_MAX_INTRON" ]]
}

# Function that evaluates to true if paired-end mode options and no mutually exclusive options are set. #
paired_settings() {
  [[ -n "$INPUT_DIR" \
  && -z "$SINGLE_SUFFIX" \
  && -n "$LEFT_SUFFIX" && -n "$RIGHT_SUFFIX" \
  && -z "$SAMPLES_SUFFIX" \
  && -z "$BAM_SUFFIX" && -z "$GG_MAX_INTRON" ]]
}

# Function that evaluates to true if samples file mode options and no mutually exclusive options are set. #
samples_settings() {
  [[ -n "$INPUT_DIR" \
  && -z "$SINGLE_SUFFIX" \
  && -z "$LEFT_SUFFIX" && -z "$RIGHT_SUFFIX" \
  && -n "$SAMPLES_SUFFIX" \
  && -z "$BAM_SUFFIX" && -z "$GG_MAX_INTRON" ]]
}

# Function that evaluates to true if genome-guided mode options and no mutually exclusive options are set. #
bam_settings() {
  [[ -n "$INPUT_DIR" \
  && -z "$SINGLE_SUFFIX" \
  && -z "$LEFT_SUFFIX" && -z "$RIGHT_SUFFIX" \
  && -z "$SAMPLES_SUFFIX" \
  && -n "$BAM_SUFFIX" && -n "$GG_MAX_INTRON" ]]
}

## NOTE ##
## Regarding the usage of the --long_reads and --long_reads_bam Trinity options: ##
##     --long_reads seems incompatible with --genome_guided_bam. ##
##     --long_reads_bam seems incompatible with --single, --left/right, and --samples. ##

## Trinity will not crash should incompatible short and long reads options be set in one command. However, ##
## extensive testing suggests that Trinity ignores long reads data when such incompatible options are set. ##
## Thus, it is probably best to enforce the mutual exclusivity of short/long option pairings to reduce any ##
## confusion regarding what is possible. The functions below will facilitate such enforcement. ##

# Function that evaluates to true if the assembly strategy involves the use of unmapped short reads data. #
unmapped_short_reads_strategy() {
  [[ ( "$STRATEGY" == "SINGLE" \
  || "$STRATEGY" == "PAIRED" \
  || "$STRATEGY" == "SAMPLES" ) \
  && "$STRATEGY" != "BAM" ]]
}

# Function that evaluates to true if the assembly strategy involves the use of mapped short reads data. #
mapped_short_reads_strategy() {
  [[ ( "$STRATEGY" != "SINGLE" \
  && "$STRATEGY" != "PAIRED" \
  && "$STRATEGY" != "SAMPLES" ) \
  && "$STRATEGY" == "BAM" ]]
}

# Function that evaluates to true if the assembly strategy incorporates no long reads data. #
short_reads_only_strategy() {
  [[ -z "$LONG_DATA_DIR" \
  && -z "$LONG_READS_SUFFIX" \
  && -z "$LONG_BAM_SUFFIX" ]]
}

# Function that evaluates to true if the assembly strategy incorporates unmapped long reads data. #
unmapped_long_reads_strategy() {
  [[ -d "$LONG_DATA_DIR" \
  && -n "$LONG_READS_SUFFIX" \
  && -z "$LONG_BAM_SUFFIX" ]]
}

# Function that evaluates to true if the assembly strategy incorporates mapped long reads data. #
mapped_long_reads_strategy() {
  [[ -d "$LONG_DATA_DIR" \
  && -z "$LONG_READS_SUFFIX" \
  && -n "$LONG_BAM_SUFFIX" ]]
}

# Function that standardizes path names by removing terminal forward slashes. #
standardize_pathnames() {
  local PATH_VARIABLE="$1"

  if [[ "$PATH_VARIABLE" =~ /$ ]]
  then
    echo "${PATH_VARIABLE%/}"
  else
    echo "$PATH_VARIABLE"
  fi
}

# Function that checks whether variables which should contain integer values do. #
check_int() {
  local VALUE_TO_CHECK="$1"

  if [[ "$VALUE_TO_CHECK" =~ ^[0-9]+$ ]]
  then
    # A no-op to skip the rest of this if block if the provided value is an integer. #
    :

  else
    printf "\n%s\n\n" "ERROR: Argument $VALUE_TO_CHECK is not an integer!"
    exit 1
  fi
}

# Function to check that Trinity commands begin with Trinity or singularity ... Trinity. #
check_exec() {
  local COMMAND_TO_VALIDATE="$1"

  if [[ "$COMMAND_TO_VALIDATE" =~ ^Trinity ]]
  then
    # A no-op to skip the rest of this if block if the command begins with Trinity. #
    :

  elif [[ "$COMMAND_TO_VALIDATE" =~ ^singularity.*Trinity ]]
  then
    # A no-op to skip the rest of this if block if the command begins with singularity ... Trinity. #
    :

  else
    printf "\n%s\n\n" "ERROR: Trinity command does not start with \"Trinity\" or \"singularity ... Trinity\"!"
    exit 1
  fi
}

# Export the exec_check function, as it is used in GNU parallel subshells. #
export -f check_exec

## NOTE ##
## Standard Trinity arguments and commands should probably never contain: ##
##     Command separators (e.g. semicolons) ##
##     Redirection operators (e.g. greater-than-signs) ##
##     Assignment operators (e.g. equals signs) ##
##     And several other metacharacters ##
##
## In certain contexts, such characters may cause unexpected and unsafe behaviors. The function ##
## below uses a whitelist to verify that arguments and commands do not contain such characters. ##
## Arguments and commands passing such basic safety checks are not guaranteed valid, however. ##

# Function to check provided arguments and Trinity commands for non-whitelisted characters. #
examine_strings() {
  local STRING_TO_VALIDATE="$1"
  local MESSAGE_TYPE="$2"

  # Ensure that provided arguments or Trinity commands contain no non-whitelisted characters. #
  if [[ "$STRING_TO_VALIDATE" == *[^$CHAR_WHITELIST]* && "$MESSAGE_TYPE" == "INITIAL_ARGS" ]]
  then

    printf "\n%s\n" "ERROR: Input may only contain alphanumerics, spaces, and the following: _ - / \\ \" ' : , ."
    printf "%s\n\n" " The use of \$ is allowed for variable specification only."
    exit 1

  elif [[ "$STRING_TO_VALIDATE" == *[^$CHAR_WHITELIST]* && "$MESSAGE_TYPE" == "FINAL_COMMAND" ]]
  then
    printf "\n%s\n" "ERROR: Commands may only contain alphanumerics, spaces, and the following: _ - / \\ \" ' : , ."
    printf "%s\n\n" " The use of \$ is allowed for variable specification only."
    exit 1

  elif [[ "$STRING_TO_VALIDATE" == *[^$CHAR_WHITELIST]* ]]
  then
    printf "\n%s\n" "ERROR: Input/commands may only contain alphanumerics, spaces, and the following: _ - / \\ \" ' : , ."
    printf "%s\n\n" " The use of \$ is allowed for variable specification only."
    exit 1
  fi

  # If no non-whitelisted characters are found in provided arguments or Trinity commands, proceed. #
  if [[ "$MESSAGE_TYPE" == "INITIAL_ARGS" ]]
  then
    # A no-op to prevent cluttering stdout with success messages if --help or --version are set. #
    :

  elif [[ "$MESSAGE_TYPE" == "FINAL_COMMAND" ]]
  then
    printf "%s\n" "Final Trinity command has passed basic safety checks."

  else
    printf "\n%s\n\n" "ERROR: Could not determine which string type is being examined for basic safety."
    exit 1
  fi
}

# Export the examine_strings function, as it is used in GNU parallel subshells. #
export -f examine_strings

#################################
### OPTION & ARGUMENT PARSING ###
#################################

# Before parsing opts and args, ensure we are using util-linux getopt and not the old Unix/BSD getopt. #
if command -v getopt > /dev/null 2>&1
then
  ## NOTE ##
  ## By design, util-linux getopt produces a rather specific exit status of 4 when ran with --test. ##
  ## The original BSD/Unix version of getopt produces an exit status of 0 when ran with --test. ##
  ## Therefore, we must disable set -e before testing and reset it after exit status storage. ##

  set +e
  getopt --test > /dev/null 2>&1
  GETOPT_EXIT_STATUS="$?"
  set -e

  if [[ "$GETOPT_EXIT_STATUS" -eq 4 ]]
  then
    # A no-op to prevent cluttering stdout with success messages if --help or --version are set. #
    :

  # The old Unix/BSD getopt is notoriously broken and will not parse our options and arguments properly. #
  elif [[ "$GETOPT_EXIT_STATUS" -eq 0 ]]
  then
    printf "\n%s\n" "ERROR: The version of getopt installed is likely not util-linux getopt."
    printf "%s\n\n" "Please install util-linux getopt (a.k.a. GNU getopt) before continuing."
    exit 1

  else
    printf "\n%s\n" "ERROR: The version of getopt installed could not be determined."
    printf "%s\n\n" "Please install util-linux getopt (a.k.a. GNU getopt) before continuing."
    exit 1
  fi

else
  printf "\n%s\n" "ERROR: Could not find getopt!"
  printf "%s\n\n" "Please install util-linux getopt (a.k.a. GNU getopt) before continuing."
  exit 1
fi

# Define the list of options our script can accept in long form. #
LONG_OPTS="input_dir:, long_data_dir:, output_dir:, single_suffix:, left_suffix:,
  right_suffix:, samples_suffix:, bam_suffix:, long_reads_suffix:, long_bam_suffix:,
  jobs:, extra_options:, singularity_image:, dry_run, help,
  version, seqType:, SS_lib_type:, min_contig_length:, genome_guided_max_intron:,
  jaccard_clip, trimmomatic, full_cleanup, run_as_paired, CPU:,
  max_memory:, quality_trimming_params:, bfly_opts:, grid_exec:, singularity_extra_params:"

# Remove the spaces and newlines we used when setting LONG_OPTS, included there for readability. #
LONG_OPTS=$(echo "$LONG_OPTS" | tr -d '[:space:]')

# Verify that all options and arguments seem safe before proceeding any further. #
examine_strings "$*" "INITIAL_ARGS"

# Ensure that parsing options and arguments with getopt is successful. #
if PARSED_ARGS=$(getopt --options '' --longoptions "$LONG_OPTS" -- "$@")
then
  # A no-op to prevent cluttering stdout with success messages if --help or --version are set. #
  :
else
  printf "\n%s\n" "ERROR: There was an issue parsing options and arguments."
  help_message
  exit 1
fi

# Ensure paratrin is not ran without any options or arguments supplied. #
if [[ -z "$*" ]]
then
  printf "\n%s\n" "ERROR: No options or arguments were provided."
  help_message
  exit 1
fi

# Verify that all parsed options and arguments seem safe before proceeding any further. #
examine_strings "$PARSED_ARGS" "INITIAL_ARGS"

# Assign positional information to each option and argument in PARSED_ARGS. #
eval set -- "$PARSED_ARGS"

# Assign values to variables based on the options and arguments set. #
while true
do
  case "$1" in

    # Wrapper parameters. #
    --input_dir)
      INPUT_DIR="$2"
      shift 2
      ;;
    --long_data_dir)
      LONG_DATA_DIR="$2"
      shift 2
      ;;
    --output_dir)
      OUTPUT_DIR="$2"
      shift 2
      ;;
    --single_suffix)
      SINGLE_SUFFIX="$2"
      shift 2
      ;;
    --left_suffix)
      LEFT_SUFFIX="$2"
      shift 2
      ;;
    --right_suffix)
      RIGHT_SUFFIX="$2"
      shift 2
      ;;
    --samples_suffix)
      SAMPLES_SUFFIX="$2"
      shift 2
      ;;
    --bam_suffix)
      BAM_SUFFIX="$2"
      shift 2
      ;;
    --long_reads_suffix)
      LONG_READS_SUFFIX="$2"
      shift 2
      ;;
    --long_bam_suffix)
      LONG_BAM_SUFFIX="$2"
      shift 2
      ;;
    --jobs)
      NUM_JOBS="$2"
      shift 2
      ;;
    --extra_options)
      EXTRA_OPTIONS="$2"
      shift 2
      ;;
    --singularity_image)
      SINGULARITY_IMAGE="$2"
      shift 2
      ;;
    --dry_run)
      DRY_RUN="ON"
      shift
      ;;
    --help)
      help_message
      exit 0
      ;;
    --version)
      version_message
      exit 0
      ;;

    # Standard Trinity parameters. #
    --seqType)
      SEQ_TYPE="$1 $2"
      shift 2
      ;;
    --SS_lib_type)
      SS_LIB_TYPE="$1 $2"
      shift 2
      ;;
    --min_contig_length)
      MIN_CONTIG_LENGTH="$1 $2"
      shift 2
      ;;
    --genome_guided_max_intron)
      GG_MAX_INTRON="$1 $2"
      shift 2
      ;;
    --jaccard_clip)
      JACCARD_CLIP="$1"
      shift
      ;;
    --trimmomatic)
      TRIMMOMATIC="$1"
      shift
      ;;
    --full_cleanup)
      FULL_CLEANUP="$1"
      shift
      ;;
    --run_as_paired)
      RUN_AS_PAIRED="$1"
      shift
      ;;
    --CPU)
      CPU="$1 $2"
      shift 2
      ;;
    --max_memory)
      MAX_MEMORY="$1 $2"
      shift 2
      ;;

    # Argument forwarding (special) Trinity parameters. #
    --quality_trimming_params)
      QT_PARAMETERS="$1 \"$2\""
      shift 2
      ;;
    --bfly_opts)
      BFLY_OPTS="$1 \"$2\""
      shift 2
      ;;
    --grid_exec)
      GRID_EXEC="$1 \"$2\""
      shift 2
      ;;
    --singularity_extra_params)
      SINGULARITY_PARAMETERS="$1 \"$2\""
      shift 2
      ;;

    # End of options and unknown parameters. #
    --)
      shift
      break
      ;;
    *)
      printf "\n%s\n\n" "ERROR: Unknown parameter $1"
      exit 1
      ;;
  esac
done

## NOTE ##
## From this point forward, we will be breaking up stdout into nicely organized sections. The reason we are not ##
## doing this earlier is because we do not want such messages popping up any time --help or --version are used. ##

#########################
### DEPENDENCY CHECKS ###
#########################

# If command line arguments are parsed successfully, print a message that dependency checks are beginning. #
printf "\n%s\n" "#########################"
printf "%s\n" "# CHECKING DEPENDENCIES #"
printf "%s\n\n" "#########################"

# Ensure that either Trinity or Singularity and the Trinity image are installed and seem operational. #
if [[ -z "$SINGULARITY_IMAGE" ]]
then
  if command -v Trinity > /dev/null 2>&1
  then
    # A no-op to skip the rest of this if block if Trinity is found. #
    :
  else
    printf "%s\n\n" "ERROR: Could not find Trinity!"
    exit 1
  fi

  ## NOTE ##
  ## One should not test Trinity with --version, as this requires performing a network check. ##
  ## Although it should work in most cases, --cite achieves the same goal without network checks. ##

  # This checks if Trinity responds as expected in a simple use case. #
  if Trinity --cite > /dev/null 2>&1
  then
    # A no-op to skip the rest of this if block if Trinity seems operational. #
    :

  else
    printf "%s\n\n" "ERROR: Trinity does not seem operational."
    exit 1
  fi

elif [[ -f "$SINGULARITY_IMAGE" ]]
then
  if command -v singularity > /dev/null 2>&1
  then
    # A no-op to skip the rest of this if block if Singularity is found. #
    :

  else
    printf "%s\n\n" "ERROR: Could not find Singularity!"
    exit 1
  fi

  # This checks if the Trinity Singularity Image responds as expected in a simple use case. #
  if singularity exec -e "$SINGULARITY_IMAGE" Trinity --cite > /dev/null 2>&1
  then
    # If Singularity and the Image seem operational, create a Singularity Trinity command. #
    TRINITY_EXEC="singularity exec -e $SINGULARITY_IMAGE Trinity"

  else
    printf "%s\n\n" "ERROR: The Trinity Singularity Image does not seem operational."
    exit 1
  fi
fi

# Export the Trinity command to be used (Trinity or Singularity Trinity). #
export TRINITY_EXEC

# Ensure that GNU Parallel is installed and seems operational. #
if command -v parallel > /dev/null 2>&1
then
  ## NOTE ##
  ## The use of --will-cite --version is to ensure the version of parallel installed is GNU Parallel. ##
  ## The GNU Parallel citation notice is left on in the main analysis block. Thus, neither the use of ##
  ## --will-cite nor the redirect of stdout to null is intended to circumvent said notice. ##

  # This checks if GNU Parallel responds as expected in a simple use case. #
  if parallel --will-cite --version > /dev/null 2>&1
  then
    # A no-op to skip the rest of this if block if GNU parallel is found and seems operational. #
    :

  else
    printf "%s\n\n" "ERROR: GNU Parallel does not seem operational."
    exit 1
  fi

else
  printf "%s\n\n" "ERROR: Could not find GNU Parallel!"
  exit 1
fi

# Print a success message if all dependencies are installed and seem operational. #
printf "%s\n\n" "All required software seems to be installed! Continuing..."

################################
### ASSEMBLY MODE ASSESSMENT ###
################################

# If all dependencies seem operational, print a message that assembly mode assessment is beginning. #
printf "%s\n" "###########################"
printf "%s\n" "# ASSESSING ASSEMBLY MODE #"
printf "%s\n\n" "###########################"

# Ensure core mandatory options have been set. #
if core_settings
then
  # A no-op to skip the rest of this if block if users have properly set all mandatory options. #
  :

# Handle missing directory errors explicitly to avoid confusion if said options are indeed set. #
elif [[ -n "$INPUT_DIR" && ! -d "$INPUT_DIR" ]]
then
  printf "%s\n\n" "ERROR: Could not find input directory \"${INPUT_DIR}\"!"
  exit 1

elif [[ -n "$OUTPUT_DIR" && ! -d "$OUTPUT_DIR" ]]
then
  printf "%s\n\n" "ERROR: Could not find output directory \"${OUTPUT_DIR}\"!"
  exit 1

else
  printf "%s\n\n" "ERROR: You must supply arguments for all required options."
  help_message
  exit 1
fi

# Ensure NUM_JOBS contains an integer and nothing which could alter the behavior of GNU Parallel. #
check_int "$NUM_JOBS"

# Remove trailing slashes from directory path names for consistent future handling. #
INPUT_DIR=$(standardize_pathnames "$INPUT_DIR")
OUTPUT_DIR=$(standardize_pathnames "$OUTPUT_DIR")

if [[ -d "$LONG_DATA_DIR" ]]
then
  LONG_DATA_DIR=$(standardize_pathnames "$LONG_DATA_DIR")

# Should users specify a non-existent long_data_dir, catch that issue early. #
elif [[ -n "$LONG_DATA_DIR" && ! -d "LONG_DATA_DIR" ]]
then
  printf "%s\n\n" "ERROR: Could not find long data directory \"${LONG_DATA_DIR}\"!"
  exit 1
fi

# Ensure we move into the output directory successfully. #
if cd "$OUTPUT_DIR"
then
  # Make a helpful output subdirectory for wrapper output files. #
  mkdir paratrin_output

else
  printf "%s\n\n" "ERROR: Output data directory could not be entered."
  exit 1
fi

# Export suffixes and assembly strategy if single-end analysis options have been set properly. #
if single_settings
then
  export DATA_FILE_SUFFIX="$SINGLE_SUFFIX"
  export STRATEGY="SINGLE"
  export SINGLE_SUFFIX

# Export suffixes and assembly strategy if paired-end analysis options have been set properly. #
elif paired_settings
then
  ## NOTE ##
  ## The left and right files should have identical basenames, differing only in their suffixes. ##
  ## Thus, it should not matter whether we assign LEFT_SUFFIX or RIGHT_SUFFIX to DATA_FILE_SUFFIX. ##

  export DATA_FILE_SUFFIX="$LEFT_SUFFIX"
  export STRATEGY="PAIRED"
  export LEFT_SUFFIX
  export RIGHT_SUFFIX

# Export suffixes and assembly strategy if samples file analysis options have been set properly. #
elif samples_settings
then
  export DATA_FILE_SUFFIX="$SAMPLES_SUFFIX"
  export STRATEGY="SAMPLES"
  export SAMPLES_SUFFIX

# Export suffixes and assembly strategy if genome-guided analysis options have been set properly. #
elif bam_settings
then
  export DATA_FILE_SUFFIX="$BAM_SUFFIX"
  export STRATEGY="BAM"
  export BAM_SUFFIX

# Print an error message and usage info if analysis mode options have been set improperly. #
else
  printf "%s\n\n" "ERROR: You must use one of the following option sets:"
  printf "%-25s%-40s\n" " Single-end usage: " "--single_suffix"
  printf "%-25s%-40s\n" " Paired-end usage: " "--left_suffix, --right_suffix"
  printf "%-25s%-40s\n" " Samples file usage: " "--samples_suffix"
  printf "%-25s%-40s\n" " Genome guided usage: " "--bam_suffix, --genome_guided_max_intron"
  printf "\n%s\n\n" "Note that options in each set are mutually exclusive with those of the other sets."
  help_message
  exit 1
fi

# If neither long reads nor long bam data are supplied, export the relevant variable. #
if short_reads_only_strategy
then
  export LONG_DATA_STRATEGY="NONE"

# If long reads data are supplied properly, export the relevant variables. #
elif unmapped_long_reads_strategy && unmapped_short_reads_strategy
then
  export LONG_DATA_STRATEGY="LONG_READS"
  export LONG_READS_SUFFIX

# If long bam data are supplied properly, export the relevant variables. #
elif mapped_long_reads_strategy && mapped_short_reads_strategy
then
  export LONG_DATA_STRATEGY="LONG_BAM"
  export LONG_BAM_SUFFIX

# If long reads or long bam data are supplied improperly, print an error message and usage info. #
else
  printf "%s\n\n" "ERROR: You use one of the following option sets if using long reads data:"
  printf "%-35s%-40s\n" " To incorporate long reads data:" "--long_dir, --long_reads_suffix"
  printf "%-35s%-40s\n" " To incorporate long bam data:" "--long_dir, --long_bam_suffix"
  printf "\n%s\n" "Also, please note that:"
  printf "%s\n" " --long_reads_suffix is incompatible with --bam_suffix."
  printf "%s\n" " --long_bam_suffix is incompatible with --single_suffix, --left_suffix/--right_suffix, and --samples_suffix."
  printf "%s\n" " --long_reads_suffix and --long_bam_suffix are mutually exclusive."
  help_message
  exit 1
fi

# Generate basenames for the relevant input files. #
if BASENAMES=$(find "$INPUT_DIR" -type f -name "*$DATA_FILE_SUFFIX" -print0 | xargs -0 -n 1 basename -s "$DATA_FILE_SUFFIX")
then
  # A no-op to skip the rest of this if block should the above pipeline populate BASENAMES. #
  :
else
  printf "%s\n\n" "ERROR: There was an issue parsing data file names!"
  exit 1
fi

# Create an array of wrapper variable names. #
WRAPPER_VARIABLES=("INPUT_DIR" "LONG_DATA_DIR" "OUTPUT_DIR" "DRY_RUN" "NUM_JOBS")

# Use the above array of variable names to export said variables via indirection if they contain data. #
for var in "${WRAPPER_VARIABLES[@]}"
do
  if [[ -n "${!var}" ]]
  then
    export "$var=${!var}"
  fi
done

# Create an array of all Trinity core variable names (plus EXTRA_PARAMETERS). #
ALL_TRINITY_VARIABLES=("SEQ_TYPE" "SS_LIB_TYPE" "MIN_CONTIG_LENGTH" "GG_MAX_INTRON" "JACCARD_CLIP"
      "TRIMMOMATIC" "QT_PARAMETERS" "BFLY_OPTS" "GRID_EXEC" "SINGULARITY_PARAMETERS"
      "FULL_CLEANUP" "RUN_AS_PAIRED" "EXTRA_OPTIONS" "CPU" "MAX_MEMORY")

SET_TRINITY_VARIABLES=""

# Use the above array to append said variables to SET_TRINITY_VARIABLES via indirection if they contain data. #
for var in "${ALL_TRINITY_VARIABLES[@]}"
do
  if [[ -n "${!var}" ]]
  then
    SET_TRINITY_VARIABLES+="${!var} "
  fi
done

# Export SET_TRINITY_VARIABLES after removing the trailing space.
export SET_TRINITY_VARIABLES="${SET_TRINITY_VARIABLES% }"

# Print a success message if assembly mode was determined and relevant variables were exported properly. #
printf "%s\n\n" "Assembly mode = $STRATEGY! Continuing..."

############################################
### COMMAND GENERATION & PARALLELIZATION ###
############################################

# Should all pre-analysis checks succeed, print a helpful message telling users that analyses are beginning. #
printf "%s\n" "#####################"
printf "%s\n" "# STARTING ANALYSES #"
printf "%s\n\n" "#####################"

# Pipe data file basenames into one or more GNU parallel subshells, one basename per subshell. #
echo "$BASENAMES" | parallel -j "$NUM_JOBS" '

  # Enable enhanced error handling independently within each GNU parallel subshell. #
  set -eou pipefail

  # Initializing variables specific to the GNU parallel subshells within each subshell may be safest. #
  SINGLE_FASTX=""
  LEFT_FASTX=""
  RIGHT_FASTX=""
  SAMPLES_FILE=""
  BAM_FILE=""
  LONG_FASTA=""
  LONG_BAM_FILE=""
  RESULTS_DIR=""

  SINGLE_TRINITY_COMMAND=""
  PAIRED_TRINITY_COMMAND=""
  SAMPLES_TRINITY_COMMAND=""
  BAM_TRINITY_COMMAND=""

  # Create short reads data filenames. #
  if [[ "$STRATEGY" == "SINGLE" ]]
  then
    SINGLE_FASTX="$INPUT_DIR"/{}"$SINGLE_SUFFIX"

  elif [[ "$STRATEGY" == "PAIRED" ]]
  then
    LEFT_FASTX="$INPUT_DIR"/{}"$LEFT_SUFFIX"
    RIGHT_FASTX="$INPUT_DIR"/{}"$RIGHT_SUFFIX"

  elif [[ "$STRATEGY" == "SAMPLES" ]]
  then
    SAMPLES_FILE="$INPUT_DIR"/{}"$SAMPLES_SUFFIX"

  elif [[ "$STRATEGY" == "BAM" ]]
  then
    BAM_FILE="$INPUT_DIR"/{}"$BAM_SUFFIX"

  else
    printf "%s\n\n" "ERROR: Assembly strategy could not be determined!"
    exit 1
  fi

  # Create long reads data filenames, if applicable. #
  if [[ "$LONG_DATA_STRATEGY" == "NONE" ]]
  then
    # A no-op to skip the rest of this if block if users have specified no long reads data. #
    :

  elif [[ "$LONG_DATA_STRATEGY" == "LONG_READS" ]]
  then
    LONG_FASTA="$LONG_DATA_DIR"/{}"$LONG_READS_SUFFIX"

  elif [[ "$LONG_DATA_STRATEGY" == "LONG_BAM" ]]
  then
    LONG_BAM_FILE="$LONG_DATA_DIR"/{}"$LONG_BAM_SUFFIX"

  else
    printf "%s\n\n" "ERROR: Strategy for incorporating long reads data could not be determined!"
    exit 1
  fi

  # Create paths to the results subdirectories. #
  RESULTS_DIR="$OUTPUT_DIR"/{}_trinity_assembly/

  if mkdir "$RESULTS_DIR"
  then
    # A no-op to skip the rest of this if block if we create each results directory successfully. #
    :

  else
    printf "%s\n\n" "ERROR: There was an issue creating a results directory for sample {}!"
    exit 1
  fi

  # Generate, write, validate, and run Trinity commands for single-end analyses. #
  if [[ -f "$SINGLE_FASTX" && -d "$RESULTS_DIR" ]]
  then
    # Generate commands using only short reads data. #
    if [[ "$LONG_DATA_STRATEGY" == "NONE" ]]
    then
      SINGLE_TRINITY_COMMAND=$(
      echo "$TRINITY_EXEC --single $SINGLE_FASTX --output $RESULTS_DIR $SET_TRINITY_VARIABLES"
      )

    # Generate commands incorporating long reads data. #
    elif [[ "$LONG_DATA_STRATEGY" == "LONG_READS" && -f "$LONG_FASTA" ]]
    then
      SINGLE_TRINITY_COMMAND=$(
      echo "$TRINITY_EXEC --single $SINGLE_FASTX --long_reads $LONG_FASTA --output $RESULTS_DIR $SET_TRINITY_VARIABLES"
      )

    # If long read data are specified but there is a short-long file mismatch, exit the subshell. #
    elif [[ "$LONG_DATA_STRATEGY" == "LONG_READS" && ! -f "$LONG_FASTA" ]]
    then
      printf "%s\n\n" "ERROR: $LONG_FASTA cannot be found! Trinity command for sample {} not generated."
      exit 1

    else
      printf "%s\n\n" "ERROR: There was an issue generating a Trinity command for sample {}!"
      exit 1
    fi

    # Append each command to a file for future reference. #
    echo "$SINGLE_TRINITY_COMMAND" >> "$OUTPUT_DIR"/paratrin_output/single_trinity_commands.txt

    # Ensure each command calls Trinity or Singularity and contains no non-whitelisted characters. #
    check_exec "$SINGLE_TRINITY_COMMAND"
    examine_strings "$SINGLE_TRINITY_COMMAND" "FINAL_COMMAND"

    # If commands pass validation, run them unless --dry_run has been turned on. #
    if [[ "$DRY_RUN" == "OFF" ]]
    then
      printf "%s\n\n" "Trinity command generated for sample {}. Running Trinity..."

      bash -c "$SINGLE_TRINITY_COMMAND"

    elif [[ "$DRY_RUN" == "ON" ]]
    then
      printf "%s\n\n" "Trinity command generated for sample {}."

    else
      printf "%s\n\n" "ERROR: There was an issue determining whether you want to do a real or dry run!"
      exit 1
    fi

  # Generate, write, validate, and run Trinity commands for paired-end analyses. #
  elif [[ -f "$LEFT_FASTX" && -f "$RIGHT_FASTX" && -d "$RESULTS_DIR" ]]
  then
    # Generate commands using only short reads data. #
    if [[ "$LONG_DATA_STRATEGY" == "NONE" ]]
    then
      PAIRED_TRINITY_COMMAND=$(
      echo "$TRINITY_EXEC --left $LEFT_FASTX --right $RIGHT_FASTX --output $RESULTS_DIR $SET_TRINITY_VARIABLES"
      )

    # Generate commands incorporating long reads data. #
    elif [[ "$LONG_DATA_STRATEGY" == "LONG_READS" && -f "$LONG_FASTA" ]]
    then
      PAIRED_TRINITY_COMMAND=$(
      echo "$TRINITY_EXEC --left $LEFT_FASTX --right $RIGHT_FASTX --long_reads $LONG_FASTA --output $RESULTS_DIR $SET_TRINITY_VARIABLES"
      )

    # If long read data are specified but there is a short-long file mismatch, exit the subshell. #
    elif [[ "$LONG_DATA_STRATEGY" == "LONG_READS" && ! -f "$LONG_FASTA" ]]
    then
      printf "%s\n\n" "ERROR: $LONG_FASTA cannot be found! Trinity command for sample {} not generated."
      exit 1

    else
      printf "%s\n\n" "ERROR: There was an issue generating a Trinity command for sample {}!"
      exit 1
    fi

    # Append each command to a file for future reference. #
    echo "$PAIRED_TRINITY_COMMAND" >> "$OUTPUT_DIR"/paratrin_output/paired_trinity_commands.txt

    # Ensure each command calls Trinity or Singularity and contains no non-whitelisted characters. #
    check_exec "$PAIRED_TRINITY_COMMAND"
    examine_strings "$PAIRED_TRINITY_COMMAND" "FINAL_COMMAND"

    # If commands pass validation, run them unless --dry_run has been turned on. #
    if [[ "$DRY_RUN" == "OFF" ]]
    then
      printf "%s\n\n" "Trinity command generated for sample {}. Running Trinity..."

      bash -c "$PAIRED_TRINITY_COMMAND"

    elif [[ "$DRY_RUN" == "ON" ]]
    then
      printf "%s\n\n" "Trinity command generated for sample {}."

    else
      printf "%s\n\n" "ERROR: There was an issue determining whether you want to do a real or dry run!"
      exit 1
    fi

  # Generate, write, validate, and run Trinity commands for samples file analyses. #
  elif [[ -f "$SAMPLES_FILE" && -d "$RESULTS_DIR" ]]
  then
    # Generate commands using only short reads data. #
    if [[ "$LONG_DATA_STRATEGY" == "NONE" ]]
    then
      SAMPLES_TRINITY_COMMAND=$(
      echo "$TRINITY_EXEC --samples_file $SAMPLES_FILE --output $RESULTS_DIR $SET_TRINITY_VARIABLES"
      )

    # Generate commands incorporating long reads data. #
    elif [[ "$LONG_DATA_STRATEGY" == "LONG_READS" && -f "$LONG_FASTA" ]]
    then
      SAMPLES_TRINITY_COMMAND=$(
      echo "$TRINITY_EXEC --samples_file $SAMPLES_FILE --long_reads $LONG_FASTA --output $RESULTS_DIR $SET_TRINITY_VARIABLES"
      )

    # If long read data are specified but there is a short-long file mismatch, exit the subshell. #
    elif [[ "$LONG_DATA_STRATEGY" == "LONG_READS" && ! -f "$LONG_FASTA" ]]
    then
      printf "%s\n\n" "ERROR: $LONG_FASTA cannot be found! Trinity command for sample {} not generated."
      exit 1

    else
      printf "%s\n\n" "ERROR: There was an issue generating a Trinity command for sample {}!"
      exit 1
    fi

    # Append each command to a file for future reference. #
    echo "$SAMPLES_TRINITY_COMMAND" >> "$OUTPUT_DIR"/paratrin_output/samples_trinity_commands.txt

    # Ensure each command calls Trinity or Singularity and contains no non-whitelisted characters. #
    check_exec "$SAMPLES_TRINITY_COMMAND"
    examine_strings "$SAMPLES_TRINITY_COMMAND" "FINAL_COMMAND"

    # If commands pass validation, run them unless --dry_run has been turned on. #
    if [[ "$DRY_RUN" == "OFF" ]]
    then
      printf "%s\n\n" "Trinity command generated for sample {}. Running Trinity..."

      bash -c "$SAMPLES_TRINITY_COMMAND"

    elif [[ "$DRY_RUN" == "ON" ]]
    then
      printf "%s\n\n" "Trinity command generated for sample {}."

    else
      printf "%s\n\n" "ERROR: There was an issue determining whether you want to do a real or dry run!"
      exit 1
    fi

  # Generate, write, validate, and run Trinity commands for genome-guided analyses. #
  elif [[ -f "$BAM_FILE" && -d "$RESULTS_DIR" ]]
  then
    # Generate commands using only short reads data. #
    if [[ "$LONG_DATA_STRATEGY" == "NONE" ]]
    then
      BAM_TRINITY_COMMAND=$(
      echo "$TRINITY_EXEC --genome_guided_bam $BAM_FILE --output $RESULTS_DIR $SET_TRINITY_VARIABLES"
      )

    # Generate commands incorporating long reads data. #
    elif [[ "$LONG_DATA_STRATEGY" == "LONG_BAM" && -f "$LONG_BAM_FILE" ]]
    then
      BAM_TRINITY_COMMAND=$(
      echo "$TRINITY_EXEC --genome_guided_bam $BAM_FILE --long_reads_bam $LONG_BAM_FILE --output $RESULTS_DIR $SET_TRINITY_VARIABLES"
      )

    # If long read data are specified but there is a short-long file mismatch, exit the subshell. #
    elif [[ "$LONG_DATA_STRATEGY" == "LONG_BAM" && ! -f "$LONG_BAM_FILE" ]]
    then
      printf "%s\n\n" "ERROR: $LONG_BAM_FILE cannot be found! Trinity command for sample {} not generated."
      exit 1

    else
      printf "%s\n\n" "ERROR: There was an issue generating a Trinity command for sample {}!"
      exit 1
    fi

    # Append each command to a file for future reference. #
    echo "$BAM_TRINITY_COMMAND" >> "$OUTPUT_DIR"/paratrin_output/bam_trinity_commands.txt

    # Ensure each command calls Trinity or Singularity and contains no non-whitelisted characters. #
    check_exec "$BAM_TRINITY_COMMAND"
    examine_strings "$BAM_TRINITY_COMMAND" "FINAL_COMMAND"

    # If commands pass validation, run them unless --dry_run has been turned on. #
    if [[ "$DRY_RUN" == "OFF" ]]
    then
      printf "%s\n\n" "Trinity command generated for sample {}. Running Trinity..."

      bash -c "$BAM_TRINITY_COMMAND"

    elif [[ "$DRY_RUN" == "ON" ]]
    then
      printf "%s\n\n" "Trinity command generated for sample {}."

    else
      printf "%s\n\n" "ERROR: There was an issue determining whether you want to do a real or dry run!"
      exit 1
    fi

  else
    printf "\n%s\n\n" "ERROR: Data file or results directory not found."
    exit 1
  fi
'

# After all analyses finish, print a helpful message telling users where they can find their results. #
printf "%s\n" "#####################"
printf "%s\n" "# ANALYSES COMPLETE #"
printf "%s\n" "#####################"
printf "\n%s\n" "You may find your results at $OUTPUT_DIR/"
printf "%s\n\n" "You may find your trinity_commands.txt file within the paratrin_output/ subdirectory."


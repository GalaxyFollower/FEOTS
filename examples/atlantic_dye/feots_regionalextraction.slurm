#!/bin/bash
#
#SBATCH --nodes=1 --nodefile=feotsnodes 
#SBATCH --job-name=feots_extraction
#SBATCH -joe
#SBATCH --time=24:00:00
#

module purge
module load gcc

cd /home/jiaxu/FEOTS/examples/atlantic_dye/
date
./RegionalExtraction
date

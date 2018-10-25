###This script takes a txt file with file paths, a config_R.ini and project_config.R in katmai
#!/bin/bash
#install parallel
#conda install -c bioconda parallel
#install copyCat R packages in conda environment

###Generate input files for copyCat to run, including bam-windows and vcf from mpileups.

mkdir -p 0.bam.window.outputs
mkdir -p 1.mpileup.outputs
mkdir -p 2.CNV.outputs
echo -n '' > CPTAC3.b1.CCRCC.WGS.copyCat.commands.txt  #clear the file automatically if the code is rerun
echo -n '' > case_list.txt
awk '{print $1,$6}' /diskmnt/Projects/Users/lyao/CPTAC/CPTAC_CCRCC/copyCat/CPTAC3.b1.BamMap.dat.CCRCC.WGS.FIRST6 | while read case file
do
        #sample_name=$(basename "$file" .WholeGenome.RP-1303.bam )
        sample_name=$case
        command="bam-window -i $file -o ./0.bam.window.outputs/${sample_name}.bam.window -l -r>&./0.bam.window.outputs/${sample_name}.bam.window.log &"
        echo ${command} >> CPTAC3.b1.CCRCC.WGS.copyCat.commands.txt
        #generate bcf and vcf filesi
        command="nohup sh -c \"samtools mpileup -g -f /diskmnt/Projects/CPTAC3CNV/genomestrip/inputs/Homo_sapiens_assembly19/Homo_sapiens_assembly19.fasta $file | bcftools call --threads 5 -c | awk '{if((\$0 ~ /^#/) || (NR%10==0)) print}' > ./1.mpileup.outputs/${sample_name}.mpileup.vcf\" > ./1.mpileup.outputs/${sample_name}.mpileup.vcf.log &"
        echo ${command} >> CPTAC3.b1.CCRCC.WGS.copyCat.commands.txt
        case_ID=$(echo "${case}" | cut -d "." -f1)
        echo ${case_ID}
        echo ${case_ID} >> case_list.txt
        #exit
done

###After the preprocessing steps, run copycat R codes.

cat case_list.txt | sort -u -o case_list.txt
source activate copycat

cat case_list.txt | while read case
do
        mkdir -p ./2.CNV.outputs/${case}
        #copy from example files
        cp /diskmnt/Projects/Users/lyao/CPTAC/copycat_pipeline/config_R.ini ./2.CNV.outputs/${case}/${case}.params.ini
        cp /diskmnt/Projects/Users/lyao/CPTAC/copycat_pipeline/project_config.R ./2.CNV.outputs/${case}/${case}_run.R
        #modify params file
        output_folder_path=./2.CNV.outputs/${case}/${case}.copycat
        N_bam_window_path=./0.bam.window.outputs/${case}.WGS.N.bam.window
        T_bam_window_path=./0.bam.window.outputs/${case}.WGS.T.bam.window
        N_vcf_path=./1.mpileup.outputs/${case}.WGS.N.mpileup.vcf
        T_vcf_path=./1.mpileup.outputs/${case}.WGS.T.mpileup.vcf
        params_path=./2.CNV.outputs/${case}/${case}.params.ini
        R_path=./2.CNV.outputs/${case}/${case}_run.R
        #replace parameters accordingly
        sed -i "s#/diskmnt/Projects/Users/lyao/CPTAC/copycat_pipeline/test_run/3.C3L-00006.WGS.N.T#${output_folder_path}#g" ${params_path}
        sed -i "s#/diskmnt/Projects/Users/lyao/CPTAC/CPTAC_UCEC/WGS_CNV/copyCat/0.N.CPT0000120163.WholeGenome.RP-1303.bam.window#${N_bam_window_path}#g" ${params_path}
        sed -i "s#/diskmnt/Projects/Users/lyao/CPTAC/CPTAC_UCEC/WGS_CNV/copyCat/0.T.CPT0001460007.WholeGenome.RP-1303.bam.window#${T_bam_window_path}#g" ${params_path}
        sed -i "s#/diskmnt/Projects/Users/lyao/CPTAC/CPTAC_UCEC/WGS_CNV/copyCat/2.N.CPT0000120163.WholeGenome.RP-1303.subset.vcf#${N_vcf_path}#g" ${params_path}
        sed -i "s#/diskmnt/Projects/Users/lyao/CPTAC/CPTAC_UCEC/WGS_CNV/copyCat/2.T.CPT0001460007.WholeGenome.RP-1303.subset.vcf#${T_vcf_path}#g" ${params_path}
        sed -i "s#/diskmnt/Projects/Users/lyao/CPTAC/copycat_pipeline/config_R.ini#${params_path}#g" ${R_path}
        command="nohup Rscript ${R_path} > ./2.CNV.outputs/${case}/copycat.log &"
        echo ${command} >> CPTAC3.b1.CCRCC.WGS.copyCat.commands.txt
done

cat CPTAC3.b1.CCRCC.WGS.copyCat.commands.txt | parallel -j 6 {} 
#The last step need to be modified so that the second-part commands will not start to run unless the preprocessing steps are done.
#for parallel, refer to this script `/diskmnt/Projects/CPTAC3CNV/gatk4wxscnv/gatk4wxscnv.b2/collecthsmetrics.sh`, basically remove the & in the commands.txt and add a & at the end of parallel command

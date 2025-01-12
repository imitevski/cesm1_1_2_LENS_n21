# cesm1_1_2_LENS_n21
CESM1.1.2-LENS model code ([Kay et al., 2015](https://doi.org/10.1175/BAMS-D-13-00255.1 "Kay et al., 2015")). 

This code has been ported on Derecho but not tested. Let me know if you find any problems with the porting.



To run on Derecho:
* CASENAME='test'
* CASEDIR="/glade/work/${USER}/runs/${CASENAME}"
* RUNDIR="/glade/derecho/scratch/${USER}/${CASENAME}/run/"
* cd cesm1_1_2_LENS_n21/scripts
* ./create_newcase -case "$CASEDIR" -mach derecho -compset B1850LENS -res f09_g16
* cd "$CASEDIR"
* ./cesm_setup
* in env_mach_pes.xml change all NTHRDS_* values to 1
* ./xmlchange RUN_TYPE=hybrid,RUN_REFCASE=b.e11.B1850C5CN.f09_g16.005,RUN_REFDATE=0402-01-01,GET_REFCASE=FALSE
* ./${CASENAME}.build
* cp -r /glade/work/im2527/0402-01-01-00000/* /YOUR_RUN_DIRECTORY/
* ./${CASENAME}.submit

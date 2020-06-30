*Model do file

*Import dataset into STATA
import delimited `c(pwd)'/output/input.csv, clear

cd  `c(pwd)'/analysis /*sets working directory to analysis folder*/
set more off 

***********************HOUSE-KEEPING*******************************************
* Create directories required 
capture mkdir output
capture mkdir log
capture mkdir tempdata

* Set globals that will print in programs and direct output
global pri_outcome 	  "tpp_infec"
global sec_outcome 	  "comb_death_ITU"

global outdir  	  "output" 
global logdir     "log"
global tempdir    "tempdata"
global varlist 		i.obese4cat						///
					i.smoke_nomiss					///
					i.imd 							///
					i.asthma						///
					i.chronic_respiratory_disease 	///
					i.chronic_cardiac_disease		///
					i.diabetes 						///
					i.chronic_liver_disease  		///
					i.other_neuro 			///
					i.ra_sle_psoriasis				///
					i.other_immuno 				///
					i.asplenia 						///
					i.organ_trans					///
					i.stroke_dementia				///
					i.cancer_heam_cat 					///
					i.cancer_exhaem_cat 				///
					i.reduced_kidney_function							///
					i.hypertension			 	
					
					
					
global table_pri_outcome "COVID-19 infection"
global table_sec_outcome "COVID-19 Death or ITU admission"

global ymax 0.005

********************************************************************************

/*  Pre-analysis data manipulation  */
do "01_cr_analysis_dataset.do"

/*  Checks  */
do "02_an_data_checks.do"


*********************************************************************
*IF PARALLEL WORKING - FOLLOWING CAN BE RUN IN ANY ORDER/IN PARALLEL*
*       PROVIDING THE ABOVE CR_ FILE HAS BEEN RUN FIRST				*
*********************************************************************
do "03_an_descriptive_tables.do"

foreach outcome of any covid_death_itu covid_tpp_prob_or_susp {
	do "04_an_descriptive_table_1.do" `outcome'
	}
	
*do "an_descriptive_plots.do"

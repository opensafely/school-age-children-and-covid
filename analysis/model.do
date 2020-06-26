*Model do file

*Import dataset into STATA
cd  `c(pwd)'/analysis /*sets working directory to analysis folder*/
import delimited input.csv, clear
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
global varlist 		i.obese4cat					///
					i.smoke_nomiss				///
					i.imd 						///
					i.ckd	 					///
					i.hypertension			 	///
					i.heart_failure				///
					i.other_heart_disease		///
					i.diabcat 					///
					i.cancer_ever 				///
					i.statin 					///
					i.flu_vaccine 				///
					i.pneumococcal_vaccine		///
					i.exacerbations 			///
					i.asthma_ever				///
					i.immunodef_any
					
global table_pri_outcome "COVID-19 infection"
global table_sec_outcome "COVID-19 Death or ITU admission"

global ymax 0.005

********************************************************************************

/*  Pre-analysis data manipulation  */
do "01_cr_analysis_dataset.do"

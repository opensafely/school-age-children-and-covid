*************************************************************************

*Exposure children and COVID risk
  
*DO file name:  14_multiple_imputation_analysis

*Purpose: Using dataset with imputed ethnicity

*Requires: final analysis dataset (analysis_dataset.dta)

*Coding: HFORBES, based on Krishnan Bhaskaran

*Date drafted: 20th August 2020

*************************************************************************
* Set globals that will print in programs and direct output
global outdir  	  "output" 
global logdir     "log"
global tempdir    "tempdata"
global demogadjlist  age1 age2 age3 i.male	`bmi' `smoking'	`ethnicity'	i.imd i.tot_adults_hh
global comordidadjlist  i.htdiag_or_highbp				///
			i.chronic_respiratory_disease 	///
			i.asthma						///
			i.chronic_cardiac_disease 		///
			i.diabcat						///
			i.cancer_exhaem_cat	 			///
			i.cancer_haem_cat  				///
			i.chronic_liver_disease 		///
			i.stroke_dementia		 		///
			i.other_neuro					///
			i.reduced_kidney_function_cat	///
			i.esrd							///
			i.other_transplant 				///
			i.asplenia 						///
			i.ra_sle_psoriasis  			///
			i.other_immuno		

local outcome `1' 

* Open a log file
capture log close
log using "$logdir/14_multiple_imputation_analysis_`outcome'", text replace



forvalues x=0/1 {
use "$tempdir/cr_imputed_analysis_dataset_STSET_`outcome'_ageband_`x'.dta", clear

/*
*Age and sex adjusted
mi estimate, hr: stcox i.kids_cat3 age1 age2 age3 i.male, strata(stp) vce(cluster household_id) 
estimates

estimates save ./output/an_univariable_cox_models_`outcome'_AGESEX_multiple_imputation_ageband_`x', replace						

*Minimally adjusted
mi estimate, hr:  stcox 	i.kids_cat3 	///
			age1 age2 age3		///
			i.male 							///
			i.obese4cat 					///
			i.smoke_nomiss					///
			i.imd 						///
			, strata(stp) vce(cluster household_id)  
estimates
estimates save ./output/an_multivariate_cox_models_`outcome'_kids_cat3_DEMOGADJ_multiple_imputation_ageband_`x', replace
*/

*Fully adjusted
mi estimate, hr:  stcox 	i.kids_cat3 	 ///
			age1 age2 age3		///
			i.male 							///
			i.obese4cat 					///
			i.smoke_nomiss					///
			i.imd 						///
			i.ethnicity					///
			$comordidadjlist				///	
			, strata(stp) vce(cluster household_id)  
estimates
estimates save ./output/an_sense_`outcome'_multiple_imputation_ageband_`x', replace
}

log close


exit, clear STATA

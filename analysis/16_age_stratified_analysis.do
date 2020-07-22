********************************************************************************
*
*	Do-file:		16_age_stratified_analysis.do
*
*	Project:		Exposure children and COVID risk
*
*	Programmed by:	Hforbes, based on files from Fizz & Krishnan
*
*	Data used:		analysis_dataset.dta
*
*	Data created:	None
*
*	Other output:	Log file:  an_multivariable_cox_models.log
*
********************************************************************************
*
*	Purpose:		This do-file performs multivariable (partially adjusted) 
*					Cox models for different age strata 
*  
********************************************************************************
*	
*	Stata routines needed:	stbrier	  
*
********************************************************************************

* Set globals that will print in programs and direct output
global outdir  	  "output" 
global logdir     "log"
global tempdir    "tempdata"


local outcome `1' 


* Open a log file
capture log close
log using "$logdir\an_multivariableFULL_cox_models_`outcome'_age_strata", text replace
use "$tempdir\cr_create_analysis_dataset_STSET_`outcome'.dta", clear


*Run main MV model for different age bands
forvalues x=1/2 { 
 stcox 	kids_cat3 age1 age2 age3 		///
			i.male 							///
			i.obese4cat 					///
			i.smoke_nomiss 					///
			i.imd 							///
			i.htdiag_or_highbp				///
			i.chronic_respiratory_disease 	///
			i.asthma						///
			i.chronic_cardiac_disease 		///
			i.diabetes						///
			i.cancer_exhaem_cat	 			///
			i.cancer_haem_cat  				///
			i.chronic_liver_disease 		///
			i.stroke_dementia		 		///
			i.other_neuro					///
			i.reduced_kidney_function_cat	///
			i.organ_trans 					///
			i.tot_people_hh					///
			i.asplenia 						///
			i.ra_sle_psoriasis  			///
			i.other_immuno					///
			 if age66==`x', strata(stp) vce(cluster household_size) 
			}
estat phtest, d			


log close 


			
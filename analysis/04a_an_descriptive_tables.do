

********************************************************************************
*
*	Do-file:		04a_an_descriptive_tables.do
*
*	Project:		Exposure children and COVID risk
*
*	Programmed by:	HFORBES based on Elizabeth Williamson
*
*	Data used:		analysis_dataset.dta
*
*	Data created:	None
*
*	Other output:	Log file: 03_an_descriptive_tables.log
*
********************************************************************************
*
*	Purpose:		This do-file runs some basic safetabulations on the analysis
*					dataset.
*  
********************************************************************************


* Set globals that will print in programs and direct output
global outdir  	  "output" 
global logdir     "log"
global tempdir    "tempdata"

* Open a log file
capture log close
log using "$logdir/04a_an_descriptive_tables", replace t

forvalues x=0/1 {

use $tempdir/analysis_dataset_ageband_`x', clear

**********************************
*  Distribution in whole cohort  *
**********************************


* Demographics
summ age
safetab agegroup
safetab age66
safetab male
safetab bmicat
safetab bmicat, m
safetab obese4cat
safetab smoke
safetab smoke, m
safetab bpcat
safetab bpcat, m
safetab htdiag_or_highbp
ta shield

* Comorbidities
foreach var in chronic_respiratory_disease ///
						asthma  ///
						chronic_cardiac_disease  ///
						diabcat  ///
						cancer_exhaem_cat 						///
						cancer_haem_cat 						///
						other_immuno 	///
						other_transplant 			/// 
						asplenia 			/// 
						chronic_liver_disease  ///
						other_neuro  ///
						stroke_dementia				///
						egfr_cat  ///
						reduced_kidney_function ///
						esrd 		///
						hypertension  ///
						ra_sle_psoriasis  ///
						{
						
safetab `var'
}

safetab imd 
safetab imd, m
safetab ethnicity
safetab ethnicity, m
safetab stp


* Outcomes
safetab non_covid_death
safetab covid_death
safetab covid_tpp_prob
safetab covid_death_icu
safetab covid_icu




**********************************
*  Number (%) with each outcome  *
**********************************

foreach outvar of varlist covid_tpp_prob covid_death_icu non_covid_death {

*** Repeat for each outcome

	* Demographics
	safetab agegroup 							`outvar', col
	safetab male 								`outvar', col
	safetab bmicat 								`outvar', col m 
	safetab smoke 								`outvar', col m
	safetab obese4cat							`outvar', col m 
	safetab shield   							`outvar', col m 

	* Comorbidities
	foreach var in chronic_respiratory_disease ///
						asthma  ///
						chronic_cardiac_disease  ///
						diabcat  ///
						cancer_exhaem_cat 						///
						cancer_haem_cat 						///
						other_immuno 	///
						other_transplant 			/// 
						asplenia 			/// 
						chronic_liver_disease  ///
						other_neuro  ///
						stroke_dementia				///
						egfr_cat  ///
						esrd ///
						reduced_kidney_function ///
						hypertension  ///
						ra_sle_psoriasis  ///
						{
	safetab `var' 		`outvar', col
}
	
	safetab imd  								`outvar', col m
	safetab ethnicity 							`outvar', col m
	*safetab urban 								`outvar', col
	safetab stp 								`outvar', col
}


********************************************
*  Cumulative incidence of ONS NON COVID DEATH*
********************************************

use "$tempdir/cr_create_analysis_dataset_STSET_non_covid_death_ageband_`x'.dta", clear

sts list , at(0 80) by(agegroup male) fail

***************************************
*  Cumulative incidence of TPP COVID PROBABLE CASES *
***************************************

use "$tempdir/cr_create_analysis_dataset_STSET_covid_tpp_prob_ageband_`x'.dta", clear

sts list , at(0 80) by(agegroup male) fail

}

* Close the log file
log close


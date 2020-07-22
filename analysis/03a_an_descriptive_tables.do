

********************************************************************************
*
*	Do-file:		03a_an_descriptive_tables.do
*
*	Project:		Exposure children and COVID risk
*
*	Programmed by:	HFORBES based on Elizabeth Williamson
*
*	Data used:		analysis_dataset.dta
*
*	Data created:	None
*
*	Other output:	Log file: output/04a_an_descriptive_tables.log
*
********************************************************************************
*
*	Purpose:		This do-file runs some basic safetabulations on the analysis
*					dataset.
*  
********************************************************************************



* Open a log file
capture log close
log using "$logdir\03a_an_descriptive_tables", replace t

use $tempdir\analysis_dataset, clear


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
						diabetes  ///
						cancer_exhaem_cat 						///
						cancer_haem_cat 						///
						other_immuno 	///
						organ_trans 			/// 
						asplenia 			/// 
						chronic_liver_disease  ///
						other_neuro  ///
						stroke_dementia				///
						egfr_cat  ///
						reduced_kidney_function ///
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
foreach var in covid_death non_covid_death  ///
covid_tpp_prob_or_susp covid_tpp_prob {
safetab `var'
safetab `var' kids_cat3, col row
}




**********************************
*  Number (%) with each exposure  *
**********************************

*** Repeat for each outcome

	* Demographics
	safetab agegroup 							kids_cat3, col
	safetab male 								kids_cat3, col
	safetab bmicat 								kids_cat3, col m 
	safetab smoke 								kids_cat3, col m
	safetab obese4cat							kids_cat3, col m 
	safetab shield   							kids_cat3, col m 

	* Comorbidities
	foreach var in chronic_respiratory_disease ///
						asthma  ///
						chronic_cardiac_disease  ///
						diabetes  ///
						cancer_exhaem_cat 						///
						cancer_haem_cat 						///
						other_immuno 	///
						organ_trans 			/// 
						asplenia 			/// 
						chronic_liver_disease  ///
						other_neuro  ///
						stroke_dementia				///
						egfr_cat  ///
						reduced_kidney_function ///
						hypertension  ///
						ra_sle_psoriasis  ///
						{
	safetab `var' 		kids_cat3, col
}
	
	safetab imd  								kids_cat3, col m
	safetab ethnicity 							kids_cat3, col m
	*safetab urban 								kids_cat3, col
	safetab stp 								kids_cat3, col

* Close the log file
log close

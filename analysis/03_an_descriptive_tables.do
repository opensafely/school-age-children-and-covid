

********************************************************************************
*
*	Do-file:		03_an_descriptive_tables.do
*
*	Project:		Exposure children and COVID risk
*
*	Programmed by:	HFORBES based on Elizabeth Williamson
*
*	Data used:		analysis_dataset.dta
*
*	Data created:	None
*
*	Other output:	Log file: output/03_an_descriptive_tables.log
*
********************************************************************************
*
*	Purpose:		This do-file runs some basic tabulations on the analysis
*					dataset.
*  
********************************************************************************



* Open a log file
capture log close
log using "output/03_an_descriptive_tables", text replace

use $tempdir\analysis_dataset, clear


**********************************
*  Distribution in whole cohort  *
**********************************


* Demographics
summ age
tab agegroup
tab age66
tab male
tab bmicat
tab bmicat, m
tab obese4cat
tab smoke
tab smoke, m
tab bpcat
tab bpcat, m
tab htdiag_or_highbp


* Comorbidities
foreach var in chronic_respiratory_disease ///
						asthma  ///
						chronic_cardiac_disease  ///
						diabetes  ///
						cancer_exhaem_cat 						///
						cancer_heam_cat 						///
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
						
tab `var'
}

tab imd 
tab imd, m
tab ethnicity
tab ethnicity, m
tab stp


* Outcomes
tab covid_death_itu
tab covid_tpp_prob_or_susp






**********************************
*  Number (%) with each outcome  *
**********************************

foreach outvar of varlist covid_death_itu covid_tpp_prob_or_susp {

*** Repeat for each outcome

	* Demographics
	tab agegroup 							`outvar', col
	tab male 								`outvar', col
	tab bmicat 								`outvar', col m 
	tab smoke 								`outvar', col m
	tab obese4cat							`outvar', col m 

	* Comorbidities
	foreach var in chronic_respiratory_disease ///
						asthma  ///
						chronic_cardiac_disease  ///
						diabetes  ///
						cancer_exhaem_cat 						///
						cancer_heam_cat 						///
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
	tab `var' 		`outvar', col
}
	
	tab imd  								`outvar', col m
	tab ethnicity 							`outvar', col m
	*tab urban 								`outvar', col
	tab stp 								`outvar', col
}


********************************************
*  Cumulative incidence of ONS COVID DEATH /ICNARC ITU ADM.*
********************************************

use "$tempdir\cr_create_analysis_dataset_STSET_covid_death_itu.dta", clear

sts list , at(0 80) by(agegroup male) fail

***************************************
*  Cumulative incidence of TPP COVID CASES *
***************************************

use "$tempdir\cr_create_analysis_dataset_STSET_covid_tpp_prob_or_susp.dta", clear

sts list , at(0 80) by(agegroup male) fail



* Close the log file
log close

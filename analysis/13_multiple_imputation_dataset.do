*************************************************************************

*Exposure children and COVID risk
  
*DO file name:  13_multiple_imputation_dataset

*Purpose: Impute ethnicity
*
*Requires: final analysis dataset (analysis_dataset.dta)
*
*Coding: HFORBES, based on Krishnan Bhaskaran
*
*Date drafted: 18th August 2020
*************************************************************************


* Set globals that will print in programs and direct output
global outdir  	  "output" 
global logdir     "log"
global tempdir    "tempdata"


local outcome `1' 

* Open a log file
capture log close
log using "$logdir\13_multiple_imputation_dataset_`outcome'", text replace


*******************************************************************************
forvalues x=0/1 {

use $tempdir\analysis_dataset_ageband_`x', clear
replace ethnicity=. if ethnicity==.u 
count
* Save a version set on NON ONS covid death outcome
stset stime_non_covid_death, fail(non_covid_death) 				///
	id(patient_id) enter(enter_date) origin(enter_date)
	
drop if _st==0	
mi set wide
mi register imputed ethnicity

*Gen NA Cum Haz
sts generate cumh = na
egen cumhgp = cut(cumh), group(5)
replace cumhgp = cumhgp + 1

*HIV code: mi impute mlogit ethnicity i.hiv i.stp $adjustmentlist i.cumhgp _d, add(10) rseed(3040985)

*What's the cumulative hazard for?
*Do we need to include household id in some way?
recode diabcat .=0
mi impute mlogit ethnicity ///
			i.kids_cat3 age1 age2 age3		///
			i.male 							///
			i.obese4cat 					///
			i.smoke_nomiss					///
			i.imd 							///
			i.htdiag_or_highbp				///
			i.chronic_respiratory_disease 	///
			i.asthma						///
			i.chronic_cardiac_disease 		///
			i.diabcat						///
			i.cancer_exhaem_cat	 			///
			i.chronic_liver_disease 		///
			i.stroke_dementia		 		///
			i.other_transplant 					///
			i.asplenia 						///
			i.stp 							///
			i.cumhgp						///
			i.cancer_haem_cat  				///
			i.other_neuro					///
			i.reduced_kidney_function_cat	///
			i.esrd							///
			i.tot_adults_hh					///
			i.ra_sle_psoriasis  			///
			i.other_immuno					///
			, add(10) rseed(894726318) augment


save "$tempdir\cr_imputed_analysis_dataset_STSET_non_covid_death_ageband_`x'.dta", replace
	
	
	
	
	
	
use $tempdir\analysis_dataset_ageband_`x', clear
replace ethnicity=. if ethnicity==.u 

* Save a version set on covid death/icu  outcome
stset stime_covid_death_icu, fail(covid_death_icu) 				///
	id(patient_id) enter(enter_date) origin(enter_date)

drop if _st==0	
mi set wide
mi register imputed ethnicity
recode diabcat .=0

*Gen NA Cum Haz
sts generate cumh = na
egen cumhgp = cut(cumh), group(5)
replace cumhgp = cumhgp + 1

*HIV code: mi impute mlogit ethnicity i.hiv i.stp $adjustmentlist i.cumhgp _d, add(10) rseed(3040985)

*What's the cumulative hazard for?
*Do we need to include household id in some way?

mi impute mlogit ethnicity ///
			i.kids_cat3 age1 age2 age3		///
			i.male 							///
			i.obese4cat 					///
			i.smoke_nomiss					///
			i.imd 							///
			i.htdiag_or_highbp				///
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
			i.other_transplant 					///
			i.tot_adults_hh					///
			i.asplenia 						///
			i.ra_sle_psoriasis  			///
			i.other_immuno					///
			i.stp 							///
			i.cumhgp						///
			, add(10) rseed(894726318) augment
	
save "$tempdir\cr_imputed_analysis_dataset_STSET_covid_death_icu_ageband_`x'.dta", replace

}


log close



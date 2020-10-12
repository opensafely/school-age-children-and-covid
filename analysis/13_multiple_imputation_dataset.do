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
log using "$logdir/13_multiple_imputation_dataset_`outcome'", text replace


use  $tempdir/analysis_dataset_with_missing_ethnicity, clear
keep if age<=65
* Create restricted cubic splines for age
mkspline age = age, cubic nknots(4)
save $tempdir/analysis_dataset_with_missing_ethnicity_ageband_0, replace


use  $tempdir/analysis_dataset_with_missing_ethnicity, clear
keep if age>65
* Create restricted cubic splines for age
mkspline age = age, cubic nknots(4)
save $tempdir/analysis_dataset_with_missing_ethnicity_ageband_1, replace

*******************************************************************************
forvalues x=0/1 {

use $tempdir/analysis_dataset_with_missing_ethnicity_ageband_`x', clear
replace ethnicity=. if ethnicity==.u 
count
* Save a version set on NON ONS covid death outcome
stset stime_`outcome', fail(`outcome') 				///
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


save "$tempdir/cr_imputed_analysis_dataset_STSET_`outcome'_ageband_`x'.dta", replace
	
}	


log close



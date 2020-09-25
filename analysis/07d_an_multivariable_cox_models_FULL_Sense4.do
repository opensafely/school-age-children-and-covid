********************************************************************************
*
*	Do-file:		07d_an_multivariable_cox_models_Sense4.do
*
*	Project:		Exposure children and COVID risk
*
*	Programmed by:	Hforbes, based on files from Fizz & Krishnan
*
*	Data used:		analysis_dataset.dta
*
*	Data created:	None
*
*	Other output:	Log file:  07b_an_multivariable_cox_models_`outcome'.log
*
********************************************************************************
*
*	Purpose:		This do-file performs multivariable (fully adjusted) 
*					Cox models, with age as the underlying timescale
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
global demogadjlist  age1 age2 age3 i.male i.obese4cat i.smoke_nomiss i.imd i.tot_adults_hh i.ethnicity
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


************************************************************************************
*First clean up all old saved estimates for this outcome
*This is to guard against accidentally displaying left-behind results from old runs
************************************************************************************

* Open a log file
capture log close
log using "$logdir\07d_an_multivariable_cox_models_`outcome'_Sense4_agetimescale", text replace


*************************************************************************************
*PROG TO DEFINE THE BASIC COX MODEL WITH OPTIONS FOR HANDLING OF AGE, BMI, ETHNICITY:
cap prog drop basecoxmodel
prog define basecoxmodel
	syntax , exposure(string) age(string)
timer clear
timer on 1
	capture stcox 	`exposure'			///
			$demogadjlist 				///
			$comordidadjlist 		///
			, strata(stp) vce(cluster household_id)
timer off 1
timer list
end
*************************************************************************************


* Open dataset and fit specified model(s)
forvalues x=0/1 {

use "$tempdir\cr_create_analysis_dataset_STSET_`outcome'_ageband_`x'.dta", clear

*reset underlying timescale to age
stset
gen dob=d(01feb2020)-(age*365.25)
format dob %td
*list age dob in 1/20
streset, origin(dob) scale(365.25) 

******************************
*  Multivariable Cox models  *
******************************



foreach exposure_type in kids_cat3  {

*Age spline model (not adj ethnicity)
basecoxmodel, exposure("i.`exposure_type'") age("age1 age2 age3")
if _rc==0{
estimates
estimates save ./output/an_sense_`outcome'_age_underlying_timescale_ageband_`x', replace
*estat concordance /*c-statistic*/
	/*  Proportional Hazards test  
	* Based on Schoenfeld residuals
	timer clear 
	timer on 1
	if e(N_fail)>0 estat phtest, d
	timer off 1
	timer list*/
}
else di "WARNING AGE SPLINE MODEL DID NOT FIT (OUTCOME `outcome')"

}
}

log close



exit, clear STATA


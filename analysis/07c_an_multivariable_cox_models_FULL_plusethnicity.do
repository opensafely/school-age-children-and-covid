********************************************************************************
*
*	Do-file:		07c_an_multivariable_cox_models_FULL_plusethnicity.do
*
*	Project:		Exposure children and COVID risk
*
*	Programmed by:	Hforbes, based on files from Fizz & Krishnan
*
*	Data used:		analysis_dataset.dta
*
*	Data created:	None
*
*	Other output:	Log file:  07b_an_multivariable_cox_models_FULL_plusethnicity.log
*
********************************************************************************
*
*	Purpose:		This do-file performs multivariable (fully adjusted) 
*					Cox models. 
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
global demogadjlist  age1 age2 age3 i.male	`bmi' `smoking'	i.ethnicity	i.imd i.tot_adults_hh
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
cap erase ./output/an_multivariate_cox_models_`outcome'_MAINFULLYADJMODEL_agespline_bmicat_noeth.ster
cap erase ./output/an_multivariate_cox_models_`outcome'_MAINFULLYADJMODEL_agegroup_bmicat_noeth.ster
cap erase ./output/an_multivariate_cox_models_`outcome'_MAINFULLYADJMODEL_agespline_bmicat_CCeth.ster
cap erase ./output/an_multivariate_cox_models_`outcome'_MAINFULLYADJMODEL_agespline_bmicat_CCnoeth.ster


* Open a log file
capture log close
log using "$logdir\07c_an_multivariable_cox_models_plus_ethnicity_`outcome'", text replace


*************************************************************************************
*PROG TO DEFINE THE BASIC COX MODEL WITH OPTIONS FOR HANDLING OF AGE, BMI, ETHNICITY:
cap prog drop basecoxmodel
prog define basecoxmodel
	syntax , exposure(string) age(string) bmi(string) smoking(string)
timer clear
timer on 1
	capture stcox 	`exposure' 				///
			$demogadjlist	 			  	///
			$comordidadjlist				///
			`if'							///
			, strata(stp) vce(cluster household_id)
timer off 1
timer list
end
*************************************************************************************


* Open dataset and fit specified model(s)
forvalues x=0/1 {

use "$tempdir\cr_create_analysis_dataset_STSET_`outcome'_ageband_`x'.dta", clear

******************************
*  Multivariable Cox models  *
******************************



foreach exposure_type in 	kids_cat3  {

*Age spline model (not adj ethnicity)
basecoxmodel, exposure("i.`exposure_type'") age("age1 age2 age3")  bmi(i.obese4cat) smoking(i.smoke_nomiss)
if _rc==0{
estimates
estimates save "./output/an_multivariate_cox_models_`outcome'_`exposure_type'_MAINFULLYADJMODEL_plus_eth_ageband_`x'", replace
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

*SENSITIVITY ANALYSIS: 12 months FUP
keep if has_12_m_follow_up == 1
foreach exposure_type in kids_cat3   {

*Age spline model (not adj ethnicity)
basecoxmodel, exposure("i.`exposure_type'") age("age1 age2 age3")  bmi(i.obese4cat) smoking(i.smoke_nomiss)
if _rc==0{
estimates
estimates save ./output/an_sense_`outcome'_plus_eth_12mo_ageband_`x', replace
*estat concordance /*c-statistic*/
}
else di "WARNING 12 MO FUP MODEL W/ AGE SPLINE  DID NOT FIT (OUTCOME `outcome')"


}	

 
 
 foreach exposure_type in	gp_number_kids {
*Age spline model (not adj ethnicity)
basecoxmodel, exposure("i.`exposure_type'") age("age1 age2 age3")  bmi(i.obese4cat) smoking(i.smoke_nomiss)
if _rc==0{
estimates
estimates save ./output/an_multivariate_cox_models_`outcome'_`exposure_type'_MAINFULLYADJMODEL_plus_eth_ageband_`x', replace
}
else di "WARNING AGE SPLINE MODEL DID NOT FIT (OUTCOME `outcome')"
}

}

log close


exit, clear STATA

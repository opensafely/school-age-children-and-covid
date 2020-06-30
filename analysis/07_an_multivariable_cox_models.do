********************************************************************************
*
*	Do-file:		07_an_multivariable_cox_models.do
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
*	Purpose:		This do-file performs multivariable (fully adjusted) 
*					Cox models. 
*  
********************************************************************************
*	
*	Stata routines needed:	stbrier	  
*
********************************************************************************

local outcome `1' 


************************************************************************************
*First clean up all old saved estimates for this outcome
*This is to guard against accidentally displaying left-behind results from old runs
************************************************************************************
cap erase ./output/models/an_multivariate_cox_models_`outcome'_MAINFULLYADJMODEL_agespline_bmicat_noeth.ster
cap erase ./output/models/an_multivariate_cox_models_`outcome'_MAINFULLYADJMODEL_agegroup_bmicat_noeth.ster
cap erase ./output/models/an_multivariate_cox_models_`outcome'_MAINFULLYADJMODEL_agespline_bmicat_CCeth.ster
cap erase ./output/models/an_multivariate_cox_models_`outcome'_MAINFULLYADJMODEL_agespline_bmicat_CCnoeth.ster


* Open a log file
capture log close
log using "./output/an_multivariable_cox_models_`outcome'", text replace

use "$tempdir\cr_create_analysis_dataset_STSET_`outcome'.dta", clear


******************************
*  Multivariable Cox models  *
******************************

*************************************************************************************
*PROG TO DEFINE THE BASIC COX MODEL WITH OPTIONS FOR HANDLING OF AGE, BMI, ETHNICITY:
cap prog drop basecoxmodel
prog define basecoxmodel
	syntax , exposure(string) age(string) bp(string) [ethnicity(real 0) if(string)] 

	if `ethnicity'==1 local ethnicity "i.ethnicity"
	else local ethnicity
timer clear
timer on 1
	capture stcox 	`exposure' `age' 					///
			i.male 							///
			i.obese4cat						///
			i.smoke_nomiss					///
			`ethnicity'						///
			i.imd 							///
			`bp'							///
			i.chronic_respiratory_disease 	///
			i.asthma					///
			i.chronic_cardiac_disease 		///
			i.diabetes						///
			i.cancer_exhaem_cat	 			///
			i.cancer_haem_cat  				///
			i.chronic_liver_disease 		///
			i.stroke_dementia		 		///
			i.other_neuro					///
			i.reduced_kidney_function_cat	///
			i.organ_trans 				///
			i.asplenia 						///
			i.ra_sle_psoriasis  			///
			i.other_immuno			///
			`if'							///
			, strata(stp) vce(cluster household_size)
timer off 1
timer list
end
*************************************************************************************

foreach exposure_type in 	kids_cat3  ///
		kids_cat2_0_18yrs  ///
		kids_cat2_1_12yrs  ///
		gp_number_kids {

*Age spline model (not adj ethnicity)
basecoxmodel, exposure("`exposure_type'") age("age1 age2 age3")  bp("i.htdiag_or_highbp") ethnicity(0)
if _rc==0{
estimates
estimates save ./output/models/an_multivariate_cox_models_`outcome'_`exposure_type'_MAINFULLYADJMODEL_agespline_bmicat_noeth, replace
*estat concordance /*c-statistic*/
}
else di "WARNING AGE SPLINE MODEL DID NOT FIT (OUTCOME `outcome')"
 
*Age group model (not adj ethnicity)
basecoxmodel, exposure("`exposure_type'") age("ib3.agegroup") bp("i.htdiag_or_highbp") ethnicity(0)
if _rc==0{
estimates
estimates save ./output/models/an_multivariate_cox_models_`outcome'_`exposure_type'_MAINFULLYADJMODEL_agegroup_bmicat_noeth, replace
*estat concordance /*c-statistic*/
}
else di "WARNING GROUP MODEL DID NOT FIT (OUTCOME `outcome')"

*Complete case ethnicity model
basecoxmodel, exposure("`exposure_type'") age("age1 age2 age3") bp("i.htdiag_or_highbp") ethnicity(1)
if _rc==0{
estimates
estimates save ./output/models/an_multivariate_cox_models_`outcome'_`exposure_type'_MAINFULLYADJMODEL_agespline_bmicat_CCeth, replace
*estat concordance /*c-statistic*/
 }
 else di "WARNING CC ETHNICITY MODEL WITH AGESPLINE DID NOT FIT (OUTCOME `outcome')"
 
}

log close

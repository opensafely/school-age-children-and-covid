********************************************************************************
*
*	Do-file:		07d_an_multivariable_cox_models_FULL_Sense3.do
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
*					Cox models for a sense analysis on those with complete data on 
*					bmi and smoking
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
global demogadjlist  age1 age2 age3 i.male i.bmicat i.smoke	i.imd i.tot_adults_hh 
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
log using "$logdir\07d_an_multivariable_cox_models_FULL_Sense3_`outcome'", text replace

* Open dataset and fit specified model(s)
forvalues x=0/1 {

use "$tempdir\cr_create_analysis_dataset_STSET_`outcome'_ageband_`x'.dta", clear

******************************
*  Multivariable Cox models  *
******************************


foreach exposure_type in 	kids_cat3   {
 
*Complete case ethnicity model
stcox 	i.`exposure_type'			///
			$demogadjlist 				///
			$comordidadjlist 			///
			, strata(stp) vce(cluster household_id)
if _rc==0{
estimates
estimates save ./output/an_sense_`outcome'_CCnoeth_bmi_smok_ageband_`x', replace
*estat concordance /*c-statistic*/
 }
 else di "WARNING CC BMI SMOK MODEL WITH AGESPLINE DID NOT FIT (OUTCOME `outcome')" 
 }

}




log close




exit, clear STATA


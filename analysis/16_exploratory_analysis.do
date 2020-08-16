********************************************************************************
*
*	Do-file:		16_exploratory_analysis.do
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
*	Purpose:		This do-file performs exploratory analyis inc:
*					- MVCox models for different age strata 
*  					- MVCox models for hh size
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
log using "$logdir\16_exploratory_analysis_`outcome'", text replace

* Open dataset and fit specified model(s)
forvalues x=0/1 {

use "$tempdir\cr_create_analysis_dataset_STSET_`outcome'_ageband_`x'.dta", clear

*Run main MV model for different hh sizes
forvalues x=1/5 { 
stcox 	i.kids_cat3 age1 age2 age3 		///
			i.male 							///
			i.obese4cat 					///
			i.smoke_nomiss 					///
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
			 if household_size==`x', ///
			 strata(stp) vce(cluster household_id) 
}
			

********************************************************************************
********************************************************************************
********************************************************************************




*Run models for hh with 2 adults
*Age and sex adj
stcox 	i.kids_cat3 age1 age2 age3 		///
			i.male 						///
			 if tot_adults_hh==2, strata(stp) vce(cluster household_id) 
			 
			 
*Demog adj
stcox 	i.kids_cat3 age1 age2 age3 			///
			i.male 							///
			i.obese4cat 					///
			i.smoke_nomiss 					///
			i.imd 							///
			 if tot_adults_hh==2, strata(stp) vce(cluster household_id) 


*FULL
 stcox 	i.kids_cat3 age1 age2 age3 		///
			i.male 							///
			i.obese4cat 					///
			i.smoke_nomiss 					///
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
			 if tot_adults_hh==2, strata(stp) vce(cluster household_id) 


			 
********************************************************************************
********************************************************************************
********************************************************************************



*Investigate non-PH


*Full MV model without clustering (to see if the clustering by hh id is affecting PH test)
 stcox 	i.kids_cat3 age1 age2 age3 		///
			i.male 							///
			i.obese4cat 					///
			i.smoke_nomiss 					///
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
			 if tot_adults_hh==2, strata(stp) 


*Plot hazards
*Age and sex adj
stcox 	i.kids_cat3 age1 age2 age3 		///
			i.male 	, strata(stp) vce(cluster household_id) 
estat phtest, d		
			 
			 
*Demog adj
stcox 	i.kids_cat3 age1 age2 age3 		///
			i.male 							///
			i.obese4cat 					///
			i.smoke_nomiss 					///
			i.imd 		, strata(stp) vce(cluster household_id) 
estat phtest, d		


*FULL
 stcox 	i.kids_cat3 age1 age2 age3 		///
			i.male 							///
			i.obese4cat 					///
			i.smoke_nomiss 					///
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
			i.other_immuno, strata(stp) vce(cluster household_id) 

estat phtest, d		

*Fit time interactions

stsplit timeperiod, at(60 90)

*make vars binary
gen anyreduced_kidney_function = reduced_kidney_function_cat>=2
gen anyobesity = obese4cat>=2
gen highimd = imd>=3
gen anydiab= diabcat>=2

stcox 	i.kids_cat3 age1 age2 age3 		///
			i.male 							///
			i.obese4cat 					///
			i.smoke_nomiss 					///
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
		60.timeperiod#1.anyobesity							///
			90.timeperiod#1.anyobesity						///
		60.timeperiod#3.smoke_nomiss						///
			90.timeperiod#3.smoke_nomiss					///
		60.timeperiod#1.highimd								///
			90.timeperiod#1.highimd							///
		60.timeperiod#1.diabetes							///
			90.timeperiod#1.diabetes						///		
		60.timeperiod#1.chronic_liver_disease				///
			90.timeperiod#1.chronic_liver_disease			///
		60.timeperiod#1.cancer_exhaem_cat					///
			90.timeperiod#1.cancer_exhaem_cat				///
			90.timeperiod#1.asplenia						///
		60.timeperiod#1.other_immuno						///
			90.timeperiod#1.other_immuno					///
, strata(stp) vce(cluster household_id) 

estat phtest, d


}
log close


			
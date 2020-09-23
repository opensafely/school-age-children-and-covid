********************************************************************************
*
*	Do-file:		10_an_interaction_cox_models_weeks.do
*
*	Project:		Exposure children and COVID risk
*
*	Programmed by:	Hforbes, based on files from Fizz & Krishnan
*
*	Data used:		analysis_dataset.dta
*
*	Data created:	None
*
*	Other output:	Log file:  10_an_interaction_cox_models.log
*
********************************************************************************
*
*	Purpose:		This do-file performs multivariable (fully adjusted) 
*					Cox models, with an interaction by week of pandemic.
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
global demogadjlist  age1 age2 age3 i.male	i.obese4cat i.smoke_nomiss i.imd i.tot_adults_hh
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
foreach week in 0 1 2 3 4 5 6 7 {
cap erase ./output/an_interaction_cox_models_`outcome'_week`week'_ageband_0
cap erase ./output/an_interaction_cox_models_`outcome'_week`week'_ageband_1
}

cap log close
log using "$logdir/10a_an_interaction_cox_models_weeks_covidad", text replace

*PROG TO DEFINE THE BASIC COX MODEL WITH OPTIONS FOR HANDLING OF AGE, BMI, ETHNICITY:
cap prog drop basemodel
prog define basemodel
	syntax , exposure(string)  age(string) [ethnicity(real 0) interaction(string)] 
	if `ethnicity'==1 local ethnicity "i.ethnicity"
	else local ethnicity
timer clear
timer on 1
stcox 	`exposure'  								///
			$demogadjlist							///
			$comordidadjlist						///
			`interaction'							///
			, strata(stp) vce(cluster household_id)
	timer off 1
timer list
end
*************************************************************************************

* Open dataset and fit specified model(s)
forvalues x=0/1 {

use "$tempdir/cr_create_analysis_dataset_STSET_`outcome'_ageband_`x'.dta", clear

*SPLITTING TAKES TOO MUCH MEMORY - STRATIFY INSTEAD
/*Split data by week following start of pandemic: weeks 1 to 6 and remaining time
stsplit weeks, at(0 63 (7) 105 200)
tab weeks
recode weeks 63=1 70=2 77=3 84=4 91=5 98=6 105=7
recode covidadmission .=0 
tab weeks
tab weeks covidadmission*/

use "$tempdir/cr_create_analysis_dataset_STSET_`outcome'_ageband_`x'.dta", clear

gen new_exit=d(03april2020)
format new_exit %td
sum new_exit, format
drop stime*
gen stime_`outcome'	= min(date_`outcome', died_date_ons, dereg_date, new_exit)
* If outcome was after censoring occurred, set to zero
gen `outcome'_0 = `outcome'
replace `outcome'_0 = 0 if (date_`outcome' > stime_`outcome')
stset stime_`outcome', fail(`outcome'_0) 				///
	id(patient_id) enter(enter_date) origin(enter_date)

*Age spline model (not adj ethnicity, interaction)
basemodel, exposure("i.kids_cat3") age("age1 age2 age3")
if _rc==0 {
estimates save ./output/an_interaction_cox_models_`outcome'_week0_ageband_`x', replace
}
else di "WARNING GROUP MODEL DID NOT FIT (OUTCOME `outcome')"




foreach week in 1 2 3 4 {
cap drop new_enter 
gen new_enter=new_exit
cap drop new_exit
gen new_exit=(new_enter)+7
format new_enter new_exit %td
sum new_enter new_exit, format

drop stime*
gen stime_`outcome'	= min(covid_admissioncensor, date_covidadmission, died_date_ons, dereg_date, new_exit)
gen `outcome'_`week' = `outcome'
replace `outcome'_`week' = 0 if (date_`outcome' > stime_`outcome')
stset stime_`outcome', fail(`outcome'_`week') 				///
	id(patient_id) enter(new_enter) origin(new_enter)

*Age spline model (not adj ethnicity, interaction)
basemodel, exposure("i.kids_cat3") age("age1 age2 age3")
if _rc==0 {

estimates save ./output/an_interaction_cox_models_`outcome'_week`week'_ageband_`x', replace
}
else di "WARNING GROUP MODEL DID NOT FIT (OUTCOME `outcome')"
}
}
log close





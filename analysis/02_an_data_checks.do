/*==============================================================================
DO FILE NAME:			02_an_data_checks
PROJECT:				Exposure children and COVID risk
AUTHOR:					HFORBES Adapted from A Wong, A Schultze, C Rentsch
						 K Baskharan, E Williamson
DATE: 					30th June 2020 
DESCRIPTION OF FILE:	Run sanity checks on all variables
							- Check variables take expected ranges 
							- Cross-check logical relationships 
							- Explore expected relationships 
							- Check stsettings 
DATASETS USED:			$tempdir\`analysis_dataset'.dta
DATASETS CREATED: 		None
OTHER OUTPUT: 			Log file: $logdir\02_an_data_checks
							
==============================================================================*/

* Open a log file

capture log close
log using $logdir\02_an_data_checks, replace t

* Open Stata dataset
use $tempdir\analysis_dataset, clear

*run ssc install if not on local machine - server needs datacheck.ado file
*ssc install datacheck 

*Duplicate patient check
datacheck _n==1, by(patient_id) nol


/* CHECK INCLUSION AND EXCLUSION CRITERIA=====================================*/ 

* DATA STRUCTURE: Confirm one row per patient 
duplicates tag patient_id, generate(dup_check)
assert dup_check == 0 
drop dup_check

* INCLUSION 1: >=18 and <=110 at 1 March 2020 
assert age < .
assert age >= 18 
assert age <= 110
 
* INCLUSION 2: M or F gender at 1 March 2020 
assert inlist(sex, "M", "F")

* EXCLUDE 1:  MISSING IMD
assert inlist(imd, 1, 2, 3, 4, 5)

* EXCLUDE 2:  HH with more than 10 people
datacheck inlist(household_size, 1, 2, 3, 4, 5,6, 7, 8, 9, 10), nol

/* EXPECTED VALUES============================================================*/ 

*HH
datacheck kids_cat3<., nol
datacheck inlist(kids_cat3, 0,1, 2), nol

datacheck number_kids<., nol
datacheck inlist(number_kids, 0,1,2,3,4,5,6,7,8,9), nol

* Age
datacheck age<., nol
datacheck inlist(agegroup, 1, 2, 3, 4, 5, 6,7), nol
datacheck inlist(age66, 0, 1), nol

* Sex
datacheck inlist(male, 0, 1), nol

* BMI 
datacheck inlist(obese4cat, 1, 2, 3, 4), nol
datacheck inlist(bmicat, 1, 2, 3, 4, 5, 6, .u), nol

* IMD
datacheck inlist(imd, 1, 2, 3, 4, 5), nol

* Ethnicity
datacheck inlist(ethnicity, 1, 2, 3, 4, 5, .u), nol

* Smoking
datacheck inlist(smoke, 1, 2, 3, .u), nol
datacheck inlist(smoke_nomiss, 1, 2, 3), nol 


* Check date ranges for all comorbidities 

foreach var of varlist  chronic_respiratory_disease 	///
					chronic_cardiac_disease		///
					chronic_liver_disease  		///
					other_neuro 			///
					stroke_dementia ///
					ra_sle_psoriasis				///
					perm_immunodef  ///
					temp_immunodef  ///
					other_transplant 			/// 
					asplenia 			/// 
					hypertension			 	///
					{
						
	summ `var'_date, format

}

foreach comorb in $varlist { 

	local comorb: subinstr local comorb "i." ""
	safetab `comorb', m
	
}

* Outcome dates
foreach outcome in covid_icu_death_date died_date_onsnoncovid date_covid_tpp_prob  {
summ  `outcome', format d
hist `outcome', saving(`outcome', replace)
}
* Combine histograms
grc1leg covid_icu_death_date.gph died_date_onsnoncovid.gph date_covid_tpp_prob.gph
graph export "output/histogram_outcomes.svg", as(svg) replace

* Delete unneeded graphs
erase covid_icu_death_date.gph
erase died_date_onsnoncovid.gph
erase  date_covid_tpp_prob.gph
*censor dates
summ dereg_date, format
summ has_12_m

/* LOGICAL RELATIONSHIPS======================================================*/ 

*HH variables
safetab kids_cat3 tot_adults_hh
safetab number_kids tot_adults_hh
safetab household_size tot_adults_hh

* BMI
bysort bmicat: summ bmi
safetab bmicat obese4cat, m

* Age
bysort agegroup: summ age
safetab agegroup age66, m

* Smoking
safetab smoke smoke_nomiss, m

* Diabetes
*safetab diabcat diabetes, m

* CKD
safetab reduced egfr_cat, m
* CKD
safetab reduced esrd, m

/* EXPECTED RELATIONSHIPS=====================================================*/ 

/*  Relationships between demographic/lifestyle variables  */
safetab agegroup bmicat, 	row 
safetab agegroup smoke, 	row  
safetab agegroup ethnicity, row 
safetab agegroup imd, 		row 
safetab agegroup shield,    row 

safetab bmicat smoke, 		 row   
safetab bmicat ethnicity, 	 row 
safetab bmicat imd, 	 	 row 
safetab bmicat hypertension, row 
safetab bmicat shield,    row 

                            
safetab smoke ethnicity, 	row 
safetab smoke imd, 			row 
safetab smoke hypertension, row 
safetab smoke shield,    row 
                      
safetab ethnicity imd, 		row 
safetab shield imd, 		row 

safetab shield ethnicity, 		row 



* Relationships with age
foreach var of varlist  asthma						///
					chronic_respiratory_disease 	///
					chronic_cardiac_disease		///
					diabcat 						///
					chronic_liver_disease  		///
					other_neuro 			///
					stroke_dementia ///
					ra_sle_psoriasis				///
					other_immuno 				///
					other_transplant 			/// 
					asplenia 			/// 
					cancer_exhaem_cat 						///
					cancer_haem_cat 						///
					reduced_kidney_function_cat ///
					esrd 					///
					hypertension		///	 	
										{

		
 	safetab agegroup `var', row 
 }


 * Relationships with sex
foreach var of varlist asthma						///
					chronic_respiratory_disease 	///
					chronic_cardiac_disease		///
					diabcat						///
					chronic_liver_disease  		///
					other_neuro 			///
					stroke_dementia ///
					ra_sle_psoriasis				///
					other_immuno 				///
					other_transplant 			/// 
					asplenia 			/// 
					cancer_exhaem_cat 						///
					cancer_haem_cat 						///
					reduced_kidney_function_cat ///
					esrd 					///
					hypertension			 ///	
										{
						
 	safetab male `var', row 
}

 * Relationships with smoking
foreach var of varlist  asthma						///
					chronic_respiratory_disease 	///
					chronic_cardiac_disease		///
					diabcat						///
					chronic_liver_disease  		///
					other_neuro 			///
					stroke_dementia ///
					ra_sle_psoriasis				///
					other_immuno 				///
					other_transplant 			/// 
					asplenia 			/// 
					cancer_exhaem_cat 						///
					cancer_haem_cat 						///
					reduced_kidney_function_cat ///
					esrd					///
					hypertension			 	///
					{
	
 	safetab smoke `var', row 
}


/* SENSE CHECK OUTCOMES=======================================================*/

safetab covid_death_icu covid_tpp_prob  , row col
safetab non_covid_death covid_death_icu  , row col
safetab covid_death covid_icu  , row col

safecount if covid_icu==1 & covid_death==1

* Close log file 
log close



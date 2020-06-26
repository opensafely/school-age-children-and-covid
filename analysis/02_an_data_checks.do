/*==============================================================================
DO FILE NAME:			03_an_checks
PROJECT:				ICS in COVID-19 
AUTHOR:					A Wong, A Schultze, C Rentsch
						Adapted from K Baskharan, E Williamson
DATE: 					10th of May 2020 
DESCRIPTION OF FILE:	Run sanity checks on all variables
							- Check variables take expected ranges 
							- Cross-check logical relationships 
							- Explore expected relationships 
							- Check stsettings 
DATASETS USED:			$tempdir\analysis_dataset.dta
DATASETS CREATED: 		None
OTHER OUTPUT: 			Log file: $logdir\03_an_checks
							
==============================================================================*/

* Open a log file

capture log close
log using $logdir\02_an_checks, replace t

* Open Stata dataset
use $tempdir\analysis_dataset, clear

*run ssc install if not already installed on your computer
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
assert inlist(household_size, 1, 2, 3, 4, 5,6, 7, 8, 9, 10)

/* EXPECTED VALUES============================================================*/ 

*HH
datacheck kids_cat3<., nol
datacheck inlist(kids_cat3, 0,1, 2), nol

datacheck kids_cat2_0_18yrs<., nol
datacheck inlist(kids_cat2_0_18yrs, 0,1), nol

datacheck kids_cat2_1_11yrs<., nol
datacheck inlist(kids_cat2_0_18yrs, 0,1), nol

datacheck number_kids<., nol
datacheck inlist(number_kids, 0,1,2,3,4,5,6,7,8,9), nol

* Age
datacheck age<., nol
datacheck inlist(agegroup, 1, 2, 3, 4, 5, 6), nol
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

foreach var of varlist  		asthma						///
					chronic_respiratory_disease 	///
					chronic_cardiac_disease		///
					diabetes 						///
					chronic_liver_disease  		///
					neurological_disease 			///
					ra_sle_psoriasis				///
					perm_immunodef  ///
					temp_immunodef  ///				
					cancer 						///
					ckd							///
					hypertension			 	///
					{
						
	summ `var'_date, format

}

foreach comorb in $varlist { 

	local comorb: subinstr local comorb "i." ""
	tab `comorb', m
	
}

* Outcome dates
summ  stime_cpnsdeath stime_onscoviddeath,   format
summ  died_date_onsnoncovid died_date_cpns died_date_onscovid, format

/* LOGICAL RELATIONSHIPS======================================================*/ 

*HH variables
tab kids_cat3 kids_cat2_0_18yrs
tab kids_cat3 kids_cat2_1_11yrs
tab kids_cat2_0_18yrs kids_cat2_1_11yrs
tab number_kids

* BMI
bysort bmicat: summ bmi
tab bmicat obese4cat, m

* Age
bysort agegroup: summ age
tab agegroup age66, m

* Smoking
tab smoke smoke_nomiss, m

* Diabetes
*tab diabcat diabetes, m

* CKD
tab ckd egfr_cat, m


/* EXPECTED RELATIONSHIPS=====================================================*/ 

/*  Relationships between demographic/lifestyle variables  */
tab agegroup bmicat, 	row 
tab agegroup smoke, 	row  
tab agegroup ethnicity, row 
tab agegroup imd, 		row 

tab bmicat smoke, 		 row   
tab bmicat ethnicity, 	 row 
tab bmicat imd, 	 	 row 
tab bmicat hypertension, row 
                            
tab smoke ethnicity, 	row 
tab smoke imd, 			row 
tab smoke hypertension, row 
                            
tab ethnicity imd, 		row 

* Relationships with age
foreach var of varlist  asthma						///
					chronic_respiratory_disease 	///
					chronic_cardiac_disease		///
					diabetes 						///
					chronic_liver_disease  		///
					neurological_disease 			///
					ra_sle_psoriasis				///
					immunodef_any 				///
					cancer 						///
					ckd							///
					hypertension		///	 	
										{

		
 	tab agegroup `var', row 
 }


 * Relationships with sex
foreach var of varlist asthma						///
					chronic_respiratory_disease 	///
					chronic_cardiac_disease		///
					diabetes 						///
					chronic_liver_disease  		///
					neurological_disease 			///
					ra_sle_psoriasis				///
					immunodef_any 				///
					cancer 						///
					ckd							///
					hypertension			 ///	
										{
						
 	tab male `var', row 
}

 * Relationships with smoking
foreach var of varlist  asthma						///
					chronic_respiratory_disease 	///
					chronic_cardiac_disease		///
					diabetes 						///
					chronic_liver_disease  		///
					neurological_disease 			///
					ra_sle_psoriasis				///
					immunodef_any 				///
					cancer 						///
					ckd							///
					hypertension			 	///
					{
	
 	tab smoke `var', row 
}


/* SENSE CHECK OUTCOMES=======================================================*/

tab onscoviddeath cpnsdeath, row col


* Close log file 
log close

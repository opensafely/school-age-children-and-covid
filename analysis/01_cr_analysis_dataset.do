/*==============================================================================
DO FILE NAME:			01_cr_analysis_dataset
PROJECT:				Exposure children and COVID risk
DATE: 					25th June 2020 
AUTHOR:					Harriet Forbes adapted from A Wong, A Schultze, C Rentsch,
						 K Baskharan, E Williamson 										
DESCRIPTION OF FILE:	program 01, data management for project  
						reformat variables 
						categorise variables
						label variables 
						apply exclusion criteria
DATASETS USED:			data in memory (from analysis/input.csv)
DATASETS CREATED: 		none
OTHER OUTPUT: 			logfiles, printed to folder analysis/$logdir
							
==============================================================================*/

* Open a log file
cap log close
log using $logdir\01_cr_analysis_dataset, replace t


/* CONVERT STRINGS TO DATE====================================================*/
/* Comorb dates and TPP case outcome dates are given with month only, so adding day 
15 to enable  them to be processed as dates 											  */

*cr date for diabetes based on adjudicated type
gen diabetes=type1_diabetes if diabetes_type=="T1DM"
replace diabetes=type2_diabetes if diabetes_type=="T2DM"
replace diabetes=unknown_diabetes if diabetes_type=="UNKNOWN_DM"

drop type1_diabetes type2_diabetes unknown_diabetes

foreach var of varlist 	chronic_respiratory_disease ///
						chronic_cardiac_disease  ///
						diabetes ///
						cancer_haem  ///
						cancer_nonhaem  ///
						permanent_immunodeficiency  ///
						temporary_immunodeficiency  ///
						dialysis					///
						kidney_transplant			///
						other_transplant 			/// 
						asplenia 			/// 
						chronic_liver_disease  ///
						other_neuro  ///
						stroke_dementia				///
						esrf  ///
						hypertension  ///
						ra_sle_psoriasis  ///
						bmi_date_measured   ///
						bp_sys_date_measured   ///
						bp_dias_date_measured   ///
						creatinine_date  ///
						smoking_status_date ///
						dereg_date ///
						covid_tpp_probable ///
						{
							
		capture confirm string variable `var'
		if _rc!=0 {
			assert `var'==.
			rename `var' `var'_date
		}
	
		else {
				replace `var' = `var' + "-15"
				rename `var' `var'_dstr
				replace `var'_dstr = " " if `var'_dstr == "-15"
				gen `var'_date = date(`var'_dstr, "YMD") 
				order `var'_date, after(`var'_dstr)
				drop `var'_dstr
		}
	
	format `var'_date %td
}

* Recode to dates from the strings 
foreach var of varlist covid_icu_date	died_date_ons 	{
						
	confirm string variable `var'
	rename `var' `var'_dstr
	gen `var' = date(`var'_dstr, "YMD")
	drop `var'_dstr
	format `var' %td 
	
}

/*Tab all variables in initial extract*/
sum, d f


/* CREATE VARIABLES===========================================================*/

/* DEMOGRAPHICS */ 

* Sex
gen male = 1 if sex == "M"
replace male = 0 if sex == "F"

* Ethnicity 
replace ethnicity = .u if ethnicity == .

label define ethnicity 	1 "White"  					///
						2 "Mixed" 					///
						3 "Asian or Asian British"	///
						4 "Black"  					///
						5 "Other"					///
						.u "Unknown"

label values ethnicity ethnicity

* STP 
rename stp stp_old
bysort stp_old: gen stp = 1 if _n==1
replace stp = sum(stp)
drop stp_old

/*  IMD  */
* Group into 5 groups
rename imd imd_o
egen imd = cut(imd_o), group(5) icodes

* add one to create groups 1 - 5 
replace imd = imd + 1

* - 1 is missing, should be excluded from population 
replace imd = .u if imd_o == -1
drop imd_o

* Reverse the order (so high is more deprived)
recode imd 5 = 1 4 = 2 3 = 3 2 = 4 1 = 5 .u = .u

label define imd 1 "1 least deprived" 2 "2" 3 "3" 4 "4" 5 "5 most deprived" .u "Unknown"
label values imd imd 

/*  Age variables  */ 

* Create categorised age 
recode age 18/29.9999 = 1 /// 
		   30/39.9999 = 2 /// 
           40/49.9999 = 3 ///
		   50/59.9999 = 4 ///
	       60/69.9999 = 5 ///
		   70/79.9999 = 6 ///
		   80/max = 7, gen(agegroup) 

label define agegroup 	1 "18-<30" ///
						2 "30-<40" ///
						3 "40-<50" ///
						4 "50-<60" ///
						5 "60-<70" ///
						6 "70-<80" ///
						7 "80+"
						
label values agegroup agegroup

* Create binary age (for age stratification)
recode age min/65.999999999 = 0 ///
           66/max = 1, gen(age66)

* Check there are no missing ages
assert age < .
assert agegroup < .
assert age66 < .


/* APPLY HH level INCLUSION/EXCLUIONS==================================================*/ 

noi di "DROP if HH ID==0"
count if household_id==0
drop if household_id==0
count

drop if care_home_type!="U"
count

noi di "DROP HH>=10 persons:"
sum household_size, d
drop if household_size>=10
count

noi di "DROP MISSING GENDER:"
recode male .=9
recode male .u=9
bysort household_id: egen male_drop=max(male)
drop if male_drop==9
count


noi di "DROP AGE MISSING:"
recode age .=9
recode age .u=9
bysort household_id: egen age_drop=max(age)
drop if age_drop==9
count

noi di "DROP IMD MISSING"
recode imd .=9
recode imd .u=9
bysort household_id: egen imd_drop=max(imd)
drop if imd_drop==9
count
**************************** HOUSEHOLD VARS*******************************************

*No kids/kids under 12/up to 18
*Identify kids under 12, or kids under 18
gen nokids=1 if age<12
recode nokids .=2 if age<18 
bysort household_id: egen min_kids=min(nokids) 
gen kids_cat3=min_kids
recode kids_cat3 .=0 
lab define kids_cat3  0 "No kids" 1 "Kids under 12" 2 "Kids under 18"
lab val kids_cat3 kids_cat3
drop min_kids

*Dose-response exposure
recode nokids 2=.
bysort household_id: egen number_kids=count(nokids)
gen gp_number_kids=number_kids
recode gp_number_kids 3/max=3
recode gp_number_kids 1=2 2=3 3=4
replace gp_number_kids=0 if kids_cat3==0 
replace gp_number_kids=1 if kids_cat3==2 

lab var gp_number_kids "Number kids under 12 years in hh"
drop nokids
lab define   gp_number_kids 0 none  1 "only >12 years" ///
2 "1 child <12" ///
3 "2 children <12" ///
4 "3+ children <12"
lab val gp_number_kids gp_number_kids

tab kids_cat3 gp_number_kids, miss
 

/* DROP ALL KIDS, AS HH COMPOSITION VARS ARE NOW MADE */
drop if age<18

*Total number adults in household (to check hh size)
bysort household_id: gen tot_adults_hh=_N
recode tot_adults_hh 3/max=3


/* SET FU DATES===============================================================*/ 
* Censoring dates for each outcome (largely, last date outcome data available)
*****NEEDS UPDATING WHEN INFO AVAILABLE*******************
global onscoviddeathcensor   	= "03/08/2020"

*Start dates
global indexdate 			    = "01/02/2020"







* Note - outcome dates are handled separtely below 

* Some names too long for loops below, shorten
rename permanent_immunodeficiency_date 	perm_immunodef_date
rename temporary_immunodeficiency_date 	temp_immunodef_date
rename bmi_date_measured_date  			bmi_measured_date
rename dereg_date_date 						dereg_date

/* CREATE BINARY VARIABLES====================================================*/
*  Make indicator variables for all conditions where relevant 

foreach var of varlist 	chronic_respiratory_disease ///
						chronic_cardiac_disease  ///
						diabetes_date  ///
						cancer_haem  ///
						cancer_nonhaem  ///
						perm_immunodef  ///
						temp_immunodef  ///
						dialysis					///
						kidney_transplant			///
						other_transplant 			/// 
						asplenia 			/// 
						chronic_liver_disease  ///
						other_neuro  ///
						stroke_dementia				///
						esrf  ///
						hypertension  ///
						ra_sle_psoriasis  ///
						bmi_measured_date   ///
						bp_sys_date_measured   ///
						bp_dias_date_measured   ///
						creatinine_date  ///
						smoking_status_date ///
						{
						
	/* date ranges are applied in python, so presence of date indicates presence of 
	  disease in the correct time frame */ 
	local newvar =  substr("`var'", 1, length("`var'") - 5)
	gen `newvar' = (`var'!=. )
	order `newvar', after(`var')
	
}




/*  Body Mass Index  */
* NB: watch for missingness

* Recode strange values 
replace bmi = . if bmi == 0 
replace bmi = . if !inrange(bmi, 15, 50)

* Restrict to within 10 years of index and aged > 16 
gen bmi_time = (date("$indexdate", "DMY") - bmi_measured_date)/365.25
gen bmi_age = age - bmi_time

replace bmi = . if bmi_age < 16 
replace bmi = . if bmi_time > 10 & bmi_time != . 

* Set to missing if no date, and vice versa 
replace bmi = . if bmi_measured_date == . 
replace bmi_measured_date = . if bmi == . 
replace bmi_measured = . if bmi == . 

gen 	bmicat = .
recode  bmicat . = 1 if bmi < 18.5
recode  bmicat . = 2 if bmi < 25
recode  bmicat . = 3 if bmi < 30
recode  bmicat . = 4 if bmi < 35
recode  bmicat . = 5 if bmi < 40
recode  bmicat . = 6 if bmi < .
replace bmicat = .u if bmi >= .

label define bmicat 1 "Underweight (<18.5)" 	///
					2 "Normal (18.5-24.9)"		///
					3 "Overweight (25-29.9)"	///
					4 "Obese I (30-34.9)"		///
					5 "Obese II (35-39.9)"		///
					6 "Obese III (40+)"			///
					.u "Unknown (.u)"
					
label values bmicat bmicat

* Create less  granular categorisation
recode bmicat 1/3 .u = 1 4 = 2 5 = 3 6 = 4, gen(obese4cat)

label define obese4cat 	1 "No record of obesity" 	///
						2 "Obese I (30-34.9)"		///
						3 "Obese II (35-39.9)"		///
						4 "Obese III (40+)"		

label values obese4cat obese4cat
order obese4cat, after(bmicat)


/*  Smoking  */

* Smoking 
label define smoke 1 "Never" 2 "Former" 3 "Current" .u "Unknown (.u)"

gen     smoke = 1  if smoking_status == "N"
replace smoke = 2  if smoking_status == "E"
replace smoke = 3  if smoking_status == "S"
replace smoke = .u if smoking_status == "M"
replace smoke = .u if smoking_status == "" 

label values smoke smoke
drop smoking_status

* Create non-missing 3-category variable for current smoking
* Assumes missing smoking is never smoking 
recode smoke .u = 1, gen(smoke_nomiss)
order smoke_nomiss, after(smoke)
label values smoke_nomiss smoke

/* CLINICAL COMORBIDITIES */ 

/*  Cancer */
label define cancer 1 "Never" 2 "Last year" 3 "2-5 years ago" 4 "5+ years"

* Haematological malignancies
gen     cancer_haem_cat = 4 if inrange(cancer_haem_date, d(1/1/1900), d(1/2/2015))
replace cancer_haem_cat = 3 if inrange(cancer_haem_date, d(1/2/2015), d(1/2/2019))
replace cancer_haem_cat = 2 if inrange(cancer_haem_date, d(1/2/2019), d(1/2/2020))
recode  cancer_haem_cat . = 1
label values cancer_haem_cat cancer


* All other cancers
gen     cancer_exhaem_cat = 4 if inrange(cancer_nonhaem_date,  d(1/1/1900), d(1/2/2015)) 
replace cancer_exhaem_cat = 3 if inrange(cancer_nonhaem_date,  d(1/2/2015), d(1/2/2019))
replace cancer_exhaem_cat = 2 if inrange(cancer_nonhaem_date,  d(1/2/2019), d(1/2/2020)) 
recode  cancer_exhaem_cat . = 1
label values cancer_exhaem_cat cancer


/*  Immunosuppression  */

* Immunosuppressed:
* Permanent immunodeficiency ever, OR 
* Temporary immunodeficiency  last year
gen temp1  = 1 if perm_immunodef_date!=.
gen temp2  = inrange(temp_immunodef_date, (date("$indexdate", "DMY") - 365), date("$indexdate", "DMY"))

egen other_immuno = rowmax(temp1 temp2)
drop temp1 temp2 
order other_immuno, after(temp_immunodef)

/*  Blood pressure   */

* Categorise
gen     bpcat = 1 if bp_sys < 120 &  bp_dias < 80
replace bpcat = 2 if inrange(bp_sys, 120, 130) & bp_dias<80
replace bpcat = 3 if inrange(bp_sys, 130, 140) | inrange(bp_dias, 80, 90)
replace bpcat = 4 if (bp_sys>=140 & bp_sys<.) | (bp_dias>=90 & bp_dias<.) 
replace bpcat = .u if bp_sys>=. | bp_dias>=. | bp_sys==0 | bp_dias==0

label define bpcat 1 "Normal" 2 "Elevated" 3 "High, stage I"	///
					4 "High, stage II" .u "Unknown"
label values bpcat bpcat

recode bpcat .u=1, gen(bpcat_nomiss)
label values bpcat_nomiss bpcat

* Create non-missing indicator of known high blood pressure
gen bphigh = (bpcat==4)

/*  Hypertension  */

gen htdiag_or_highbp = bphigh
recode htdiag_or_highbp 0 = 1 if hypertension==1 


************
*   eGFR   *
************

* Set implausible creatinine values to missing (Note: zero changed to missing)
replace creatinine = . if !inrange(creatinine, 20, 3000) 
	
* Divide by 88.4 (to convert umol/l to mg/dl)
gen SCr_adj = creatinine/88.4

gen min=.
replace min = SCr_adj/0.7 if male==0
replace min = SCr_adj/0.9 if male==1
replace min = min^-0.329  if male==0
replace min = min^-0.411  if male==1
replace min = 1 if min<1

gen max=.
replace max=SCr_adj/0.7 if male==0
replace max=SCr_adj/0.9 if male==1
replace max=max^-1.209
replace max=1 if max>1

gen egfr=min*max*141
replace egfr=egfr*(0.993^age)
replace egfr=egfr*1.018 if male==0
label var egfr "egfr calculated using CKD-EPI formula with no eth"

* Categorise into ckd stages
egen egfr_cat = cut(egfr), at(0, 15, 30, 45, 60, 5000)
recode egfr_cat 0=5 15=4 30=3 45=2 60=0, generate(ckd)
* 0 = "No CKD" 	2 "stage 3a" 3 "stage 3b" 4 "stage 4" 5 "stage 5"
label define ckd 0 "No CKD" 1 "CKD"
label values ckd ckd
*label var ckd "CKD stage calc without eth"

* Convert into CKD group
*recode ckd 2/5=1, gen(chronic_kidney_disease)
*replace chronic_kidney_disease = 0 if creatinine==. 
	
recode ckd 0=1 2/3=2 4/5=3, gen(reduced_kidney_function_cat)
replace reduced_kidney_function_cat = 1 if creatinine==. 
label define reduced_kidney_function_catlab ///
	1 "None" 2 "Stage 3a/3b egfr 30-60	" 3 "Stage 4/5 egfr<30"
label values reduced_kidney_function_cat reduced_kidney_function_catlab 
lab var  reduced "Reduced kidney function"


/*ESDR: dialysis or kidney transplant*/
gen esrd=1 if dialysis==1 | kidney_transplant==1
recode esrd .=0



***************************
/* DM / Hb1AC */
***************************


/*  Diabetes severity  */

* Set zero or negative to missing
replace hba1c_percentage   = . if hba1c_percentage <= 0
replace hba1c_mmol_per_mol = . if hba1c_mmol_per_mol <= 0

/* Express  HbA1c as percentage  */ 

* Express all values as perecentage 
noi summ hba1c_percentage hba1c_mmol_per_mol 
gen 	hba1c_pct = hba1c_percentage 
replace hba1c_pct = (hba1c_mmol_per_mol/10.929)+2.15 if hba1c_mmol_per_mol<. 

* Valid % range between 0-20  /195 mmol/mol
replace hba1c_pct = . if !inrange(hba1c_pct, 0, 20) 
replace hba1c_pct = round(hba1c_pct, 0.1)


/* Categorise hba1c and diabetes  */
/* Diabetes type */
gen dm_type=1 if diabetes_type=="T1DM"
replace dm_type=2 if diabetes_type=="T2DM"
replace dm_type=3 if diabetes_type=="UNKNOWN_DM"
replace dm_type=0 if diabetes_type=="NO_DM"

safetab dm_type diabetes_type
label define dm_type 0"No DM" 1"T1DM" 2"T2DM" 3"UNKNOWN_DM"
label values dm_type dm_type

*Open safely diabetes codes with exeter algorithm
gen dm_type_exeter_os=1 if diabetes_exeter_os=="T1DM_EX_OS"
replace dm_type_exeter_os=2 if diabetes_exeter_os=="T2DM_EX_OS"
replace dm_type_exeter_os=0 if diabetes_exeter_os=="NO_DM"
label values  dm_type_exeter_os dm_type

* Group hba1c
gen 	hba1ccat = 0 if hba1c_pct <  6.5
replace hba1ccat = 1 if hba1c_pct >= 6.5  & hba1c_pct < 7.5
replace hba1ccat = 2 if hba1c_pct >= 7.5  & hba1c_pct < 8
replace hba1ccat = 3 if hba1c_pct >= 8    & hba1c_pct < 9
replace hba1ccat = 4 if hba1c_pct >= 9    & hba1c_pct !=.
label define hba1ccat 0 "<6.5%" 1">=6.5-7.4" 2">=7.5-7.9" 3">=8-8.9" 4">=9"
label values hba1ccat hba1ccat
safetab hba1ccat

gen hba1c75=0 if hba1c_pct<7.5
replace hba1c75=1 if hba1c_pct>=7.5 & hba1c_pct!=.
label define hba1c75 0"<7.5" 1">=7.5"
safetab hba1c75, m

* Create diabetes, split by control/not
gen     diabcat = 1 if dm_type==0
replace diabcat = 2 if dm_type==1 & inlist(hba1ccat, 0, 1)
replace diabcat = 3 if dm_type==1 & inlist(hba1ccat, 2, 3, 4)
replace diabcat = 4 if dm_type==2 & inlist(hba1ccat, 0, 1)
replace diabcat = 5 if dm_type==2 & inlist(hba1ccat, 2, 3, 4)
replace diabcat = 6 if dm_type==1 & hba1c_pct==. | dm_type==2 & hba1c_pct==.


label define diabcat 	1 "No diabetes" 			///
						2 "T1DM, controlled"		///
						3 "T1DM, uncontrolled" 		///
						4 "T2DM, controlled"		///
						5 "T2DM, uncontrolled"		///
						6 "Diabetes, no HbA1c"
label values diabcat diabcat
safetab diabcat, m




/*  Asthma  */


* Asthma  (coded: 0 No, 1 Yes no OCS, 2 Yes with OCS)
rename asthma asthmacat
recode asthmacat 0=1 1=2 2=3
label define asthmacat 1 "No" 2 "Yes, no OCS" 3 "Yes with OCS"
label values asthmacat asthmacat

gen asthma = (asthmacat==2|asthmacat==3)

/*  Probable shielding  */
gen shield=1 if esrd==1 | other_transplant==1 | asthmacat==2 | asthmacat==3 | ///
chronic_respiratory_disease==1 | cancer_haem==1 | cancer_nonhaem==1 | ///
asplenia==1 | other_immuno==1
recode shield .=0

recode positive_covid_test_ever .=0

/* OUTCOME AND SURVIVAL TIME==================================================*/

/*  Cohort entry and censor dates  */
* Date of cohort entry, 1 Mar 2020
gen enter_date = date("$indexdate", "DMY")

* Date of study end (typically: last date of outcome data available)
**** NOTE!! NEEDS UPDATING!!!!
gen onscoviddeathcensor_date 	    = date("$onscoviddeathcensor", 	"DMY")
gen tpp_infec_censor_date    	    = date("$tpp_infec_censor", 	"DMY")
 	
* Format the dates
format 	enter_date					///
		onscoviddeathcensor_date   %td
		 	
		
			/****   Outcome definitions   ****/

* Date of Covid death in ONS
gen died_date_onscovid = died_date_ons if died_ons_covid_flag_any == 1

* Date of non-COVID death in ONS 
* If missing date of death resulting died_date will also be missing
gen died_date_onsnoncovid = died_date_ons if died_ons_covid_flag_any != 1 
gen covid_icu_death_date=min(covid_icu_date, died_date_onscovid)

*Date probable covid in TPP
rename covid_tpp_probable date_covid_tpp_prob

format died_date_ons %td
format died_date_onscovid %td 
format died_date_onsnoncovid %td
format covid_icu_death_date %td 

* Binary indicators for outcomes
gen covid_tpp_prob = (date_covid_tpp_prob < .)
gen non_covid_death = (died_date_onsnoncovid < .)
gen covid_death = (died_date_onscovid < .)
gen covid_icu = (covid_icu_date < .)
gen covid_death_icu = (covid_icu_death_date < .)



					/**** Create survival times  ****/
* For looping later, name must be stime_binary_outcome_name

* Survival time = last followup date (first: end study, death, or that outcome)
*gen stime_onscoviddeath = min(onscoviddeathcensor_date, 				died_date_ons)
gen stime_covid_tpp_prob = min(onscoviddeathcensor_date, 	died_date_ons, date_covid_tpp_prob, dereg_date)
gen stime_non_covid_death = min(onscoviddeathcensor_date, 	died_date_ons, died_date_onsnoncovid)
gen stime_covid_death_icu = min(onscoviddeathcensor_date, died_date_ons, died_date_onscovid, covid_icu_date)


* If outcome was after censoring occurred, set to zero
replace covid_tpp_prob = 0 if (date_covid_tpp_prob > onscoviddeathcensor_date)
replace non_covid_death = 0 if (died_date_onsnoncovid > onscoviddeathcensor_date)
replace covid_death_icu = 0 if (covid_icu_death_date > onscoviddeathcensor_date)


* Format date variables
format  stime* %td 


/* LABEL VARIABLES============================================================*/
*  Label variables you are intending to keep, drop the rest 

*HH variable
label var kids_cat3 "Presence of children or young people in the household"
label var  number_kids "Number of children aged 1-<12 years in household"
label var  household_size "Number people in household"
label var  household_id "Household ID"


* Demographics
label var patient_id				"Patient ID"
label var age 						"Age (years)"
label var agegroup					"Grouped age"
label var age66 					"66 years and older"
label var sex 						"Sex"
label var male 						"Male"
label var bmi 						"Body Mass Index (BMI, kg/m2)"
label var bmicat 					"Grouped BMI"
label var bmi_measured_date  		"Body Mass Index (BMI, kg/m2), date measured"
label var obese4cat					"Evidence of obesity (4 categories)"
label var smoke		 				"Smoking status"
label var smoke_nomiss	 			"Smoking status (missing set to non)"
label var imd 						"Index of Multiple Deprivation (IMD)"
label var ethnicity					"Ethnicity"
label var stp 						"Sustainability and Transformation Partnership"
lab var care_home_type				"Care home type"
lab var tot_adults_hh 				"Total number adults in hh"
lab var positive_covid_test_ever	"Ever having had positive covid test"

* Comorbidities of interest 
label var asthma						"Asthma category"
label var egfr_cat						"Calculated eGFR"
label var hypertension				    "Diagnosed hypertension"
label var chronic_respiratory_disease 	"Chronic Respiratory Diseases"
label var chronic_cardiac_disease 		"Chronic Cardiac Diseases"
label var diabcat						"Diabetes"
label var cancer_haem_cat						"Haematological cancer"
label var cancer_exhaem_cat						"Non-haematological cancer"
label var kidney_transplant						"Kidney transplant"	
label var other_transplant 	 					"Other solid organ transplant"
label var asplenia 						"Asplenia"
label var other_immuno					"Immunosuppressed (combination algorithm)"
label var chronic_liver_disease 		"Chronic liver disease"
label var other_neuro 			"Neurological disease"			
label var stroke_dementia 			    "Stroke or dementia"							
label var ra_sle_psoriasis				"Autoimmune disease"
lab var egfr							eGFR
lab var perm_immunodef  				"Permanent immunosuppression"
lab var temp_immunodef  				"Temporary immunosuppression"
lab var esrd 							"End-stage renal disease"


label var hypertension_date			   		"Diagnosed hypertension Date"
label var chronic_respiratory_disease_date 	"Other Respiratory Diseases Date"
label var chronic_cardiac_disease_date		"Other Heart Diseases Date"
label var diabetes_date						"Diabetes Date"
label var cancer_haem_date 					"Haem cancer Date"
label var cancer_nonhaem_date 				"Non-haem cancer Date"
label var chronic_liver_disease_date  		"Chronic liver disease Date"
label var other_neuro_date 		"Neurological disease  Date"
label var stroke_dementia_date			    "Stroke or dementia date"							
label var ra_sle_psoriasis_date 			"Autoimmune disease  Date"
lab var perm_immunodef_date  				"Permanent immunosuppression date"
lab var temp_immunodef_date   				"Temporary immunosuppression date"
label var kidney_transplant_date						"Kidney transplant"	
label var other_transplant_date 					"Other solid organ transplant"
label var asplenia_date  						"Asplenia date"
lab var  bphigh "non-missing indicator of known high blood pressure"
lab var bpcat "Blood pressure four levels, non-missing"
lab var htdiag_or_highbp "High blood pressure or hypertension diagnosis"
lab var shield "Probable shielding"

* Outcomes and follow-up
label var enter_date					"Date of study entry"
label var onscoviddeathcensor_date 		"Date of admin censoring for ONS deaths"
label var tpp_infec_censor_date 		"Date of admin censoring for covid TPP cases"
label var covid_icu_death_date			"Date of admin censoring for covid death or ICU"

label var  covid_tpp_prob				"Failure/censoring indicator for outcome: covid prob case"
label var  non_covid_death				"Failure/censoring indicator for outcome: non-covid death"
label var  covid_death				    "Failure/censoring indicator for outcome: covid death"
label var  covid_icu				    "Failure/censoring indicator for outcome: covid icu"
label var  covid_death_icu			 "Failure/censoring indicator for outcome: covid icu/death"

label var date_covid_tpp_prob			"Date of covid TPP case (probable)"
label var died_date_onsnoncovid	 		"Date of ONS non-COVID Death"
label var  died_date_onscovid			"Date of ONS COVID Death"
lab var covid_icu_date					"Date admission to ICU for COVID" 

* Survival times
label var  stime_covid_tpp_prob					"Survival tme (date); outcome "
label var  stime_non_covid_death				"Survival tme (date); outcome non_covid_death	"
label var  stime_covid_death_icu				"Survival time (date); outcome covid death"

*Key DATES
label var   died_date_ons				"Date death ONS"
label var  has_12_m_follow_up			"Has 12 months follow-up"
lab var  dereg_date						"Date deregistration from practice"




/* TIDY DATA==================================================================*/
*  Drop variables that are not needed (those not labelled)
ds, not(varlabel)
drop `r(varlist)'
	

	

/* APPLY INCLUSION/EXCLUIONS==================================================*/ 

*************TEMP DROP TO INVESTIGATE ASSOCIATIONS MORE EASILY******************
noi di "DROP AGE >110:"
drop if age > 110 & age != .
count

noi di "DROP IF DIED BEFORE INDEX"
drop if died_date_ons <= date("$indexdate", "DMY")
count

noi di "DROP IF COVID IN TPP BEFORE INDEX"
drop if date_covid_tpp_prob <= date("$indexdate", "DMY")
count
	
	
***************
*  Save data  *
***************
sort patient_id
save $tempdir\analysis_dataset, replace



use  $tempdir\analysis_dataset, clear
keep if age<=65
* Create restricted cubic splines for age
mkspline age = age, cubic nknots(4)
save $tempdir\analysis_dataset_ageband_0, replace


use  $tempdir\analysis_dataset, clear
keep if age>65
* Create restricted cubic splines for age
mkspline age = age, cubic nknots(4)
save $tempdir\analysis_dataset_ageband_1, replace



forvalues x=0/1 {

use $tempdir\analysis_dataset_ageband_`x', clear
* Save a version set on NON ONS covid death outcome
stset stime_non_covid_death, fail(non_covid_death) 				///
	id(patient_id) enter(enter_date) origin(enter_date)
*WEIGHTING - TO REDUCE TIME 
set seed 30459820
keep if _d==1|uniform()<.03
gen pw = 1
replace pw = (1/0.03) if _d==0
stset stime_non_covid_death [pweight = pw],  fail(non_covid_death) 				///
	id(patient_id) enter(enter_date) origin(enter_date)
save "$tempdir\cr_create_analysis_dataset_STSET_non_covid_death_ageband_`x'.dta", replace
	

use $tempdir\analysis_dataset_ageband_`x', clear
* Save a version set on covid death/icu  outcome
stset stime_covid_death_icu, fail(covid_death_icu) 				///
	id(patient_id) enter(enter_date) origin(enter_date)
*WEIGHTING - TO REDUCE TIME 
set seed 30459820
keep if _d==1|uniform()<.03
gen pw = 1
replace pw = (1/0.03) if _d==0
stset stime_covid_death_icu [pweight = pw],  fail(covid_death_icu) 				///
	id(patient_id) enter(enter_date) origin(enter_date)
save "$tempdir\cr_create_analysis_dataset_STSET_covid_death_icu_ageband_`x'.dta", replace


use $tempdir\analysis_dataset_ageband_`x', clear
* Save a version set on probable covid
stset stime_covid_tpp_prob, fail(covid_tpp_prob) 				///
	id(patient_id) enter(enter_date) origin(enter_date)
*WEIGHTING - TO REDUCE TIME 
set seed 30459820
keep if _d==1|uniform()<.03
gen pw = 1
replace pw = (1/0.03) if _d==0
stset stime_covid_tpp_prob [pweight = pw],  fail(covid_tpp_prob) 				///
	id(patient_id) enter(enter_date) origin(enter_date)
save "$tempdir\cr_create_analysis_dataset_STSET_covid_tpp_prob_ageband_`x'.dta", replace	
}

* Close log file 
log close


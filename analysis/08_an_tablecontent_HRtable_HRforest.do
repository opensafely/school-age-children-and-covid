*************************************************************************
*Purpose: Create content that is ready to paste into a pre-formatted Word 
* shell table containing minimally and fully-adjusted HRs for risk factors
* of interest, across 2 outcomes 
*
*Requires: final analysis dataset (analysis_dataset.dta)
*
*Coding: HFORBES, based on file from Krishnan Bhaskaran
*
*Date drafted: 30th June 2020
*************************************************************************

local outcome `1' 


***********************************************************************************************************************
*Generic code to ouput the HRs across outcomes for all levels of a particular variables, in the right shape for table
cap prog drop outputHRsforvar
prog define outputHRsforvar
syntax, variable(string) min(real) max(real) outcome(string)
forvalues i=`min'/`max'{
local endwith "_tab"

	*put the varname and condition to left so that alignment can be checked vs shell
	file write tablecontents ("`variable'") _tab ("`i'") _tab
	
	foreach modeltype of any minadj fulladj {
	
		local noestimatesflag 0 /*reset*/

*CHANGE THE OUTCOME BELOW TO LAST IF BRINGING IN MORE COLS
		if "`modeltype'"=="fulladj" local endwith "_n"

		***********************
		*1) GET THE RIGHT ESTIMATES INTO MEMORY
		
		if "`modeltype'"=="minadj" & "`variable'"!="agegroup" & "`variable'"!="male" {
			cap estimates use ./output/an_univariable_cox_models_`outcome'_AGESEX_`variable'
			if _rc!=0 local noestimatesflag 1
			}

		*FOR AGEGROUP - need to use the separate univariate/multivariate model fitted with age group rather than spline
		*FOR ETHNICITY - use the separate complete case multivariate model
		*FOR REST - use the "main" multivariate model
		if "`variable'"=="agegroup" {
			if "`modeltype'"=="minadj" {
				cap estimates use ./output/an_univariable_cox_models_`outcome'_AGESEX_agegroupsex
				if _rc!=0 local noestimatesflag 1
				}
			if "`modeltype'"=="fulladj" {
				cap estimates use ./output/an_multivariate_cox_models_`outcome'_`exposure_type'_MAINFULLYADJMODEL_agegroup_bmicat_noeth
				if _rc!=0 local noestimatesflag 1
				}
			}
		else if "`variable'"=="male" {
			if "`modeltype'"=="minadj" {
				cap estimates use ./output/an_univariable_cox_models_`outcome'_AGESEX_agesplsex
				if _rc!=0 local noestimatesflag 1			
				}
			if "`modeltype'"=="fulladj" {
				cap estimates use ./output/an_multivariate_cox_models_`outcome'_`exposure_type'_MAINFULLYADJMODEL_agespline_bmicat_noeth  
				if _rc!=0 local noestimatesflag 1
				}
			}
		else if "`variable'"=="ethnicity" {
			if "`modeltype'"=="fulladj" {
				cap estimates use ./output/an_multivariate_cox_models_`outcome'_`exposure_type'_MAINFULLYADJMODEL_agespline_bmicat_CCeth  
				if _rc!=0 local noestimatesflag 1
				}
			}			
		else {
			if "`modeltype'"=="fulladj" {
				cap estimates use ./output/an_multivariate_cox_models_`outcome'_`exposure_type'_MAINFULLYADJMODEL_agespline_bmicat_noeth  
				if _rc!=0 local noestimatesflag 1
				}
		}
		
		***********************
		*2) WRITE THE HRs TO THE OUTPUT FILE
		
		if `noestimatesflag'==0{
			cap lincom `i'.`variable', eform
			if _rc==0 file write tablecontents %4.2f (r(estimate)) (" (") %4.2f (r(lb)) ("-") %4.2f (r(ub)) (")") `endwith'
				else file write tablecontents %4.2f ("ERR IN MODEL") `endwith'
			}
			else file write tablecontents %4.2f ("DID NOT FIT") `endwith' 
			
		*3) Save the estimates for plotting
		if `noestimatesflag'==0{
			if "`modeltype'"=="fulladj" {
				local hr = r(estimate)
				local lb = r(lb)
				local ub = r(ub)
				cap gen `variable'=.
				testparm i.`variable'
				post HRestimates ("`outcome'") ("`variable'") (`i') (`hr') (`lb') (`ub') (r(p))
				drop `variable'
				}
		}	
		} /*min adj, full adj*/
		
} /*variable levels*/

end
***********************************************************************************************************************
*Generic code to write a full row of "ref category" to the output file
cap prog drop refline
prog define refline
file write tablecontents _tab _tab ("1.00 (ref)") _tab ("1.00 (ref)")  _n
*post HRestimates ("`outcome'") ("`variable'") (`refcat') (1) (1) (1) (.)
end
***********************************************************************************************************************

*MAIN CODE TO PRODUCE TABLE CONTENTS

cap file close tablecontents
file open tablecontents using ./output/an_tablecontents_HRtable_`outcome'.txt, t w replace 

tempfile HRestimates
cap postutil clear
postfile HRestimates str10 outcome str27 variable level hr lci uci pval using `HRestimates'


*Primary exposure
refline
outputHRsforvar, variable("kids_cat3") min(1) max(2) outcome(`outcome')
file write tablecontents _n

*Kids under 18
refline
outputHRsforvar, variable("kids_cat2_0_18yrs") min(1) max(1) outcome(`outcome')
file write tablecontents _n

*kids 1-11 years
refline
outputHRsforvar, variable("kids_cat2_1_12yrs") min(1) max(1) outcome(`outcome')
file write tablecontents _n

*Number kids
refline
outputHRsforvar, variable("gp_number_kids") min(1) max(4) outcome(`outcome')
file write tablecontents _n 


file close tablecontents

postclose HRestimates

use `HRestimates', clear

gen varorder = 1 
local i=2
foreach var of any male obese4cat smoke_nomiss ethnicity imd  diabetes ///
	cancer_exhaem_cat cancer_haem_cat reduced_kidney_function_cat asthma chronic_respiratory_disease ///
	chronic_cardiac_disease htdiag_or_highbp chronic_liver_disease ///
	stroke_dementia other_neuro organ_trans ///
	spleen ra_sle_psoriasis other_immuno {
replace varorder = `i' if variable=="`var'"
local i=`i'+1
}
sort varorder level
drop varorder

gen obsorder=_n
expand 2 if variable!=variable[_n-1], gen(expanded)
for var hr lci uci: replace X = 1 if expanded==1

sort obsorder
drop obsorder
replace level = 0 if expanded == 1
replace level = 1 if expanded == 1 & (variable=="obese4cat"|variable=="smoke_nomiss"|variable=="ethnicity"|variable=="imd"|variable=="asthma"|variable=="diabetes"|substr(variable,1,6)=="cancer"|variable=="reduced_kidney_function_cat")
replace level = 3 if expanded == 1 & variable=="agegroup"

gen varorder = 1 if variable!=variable[_n-1]
replace varorder = sum(varorder)
sort varorder level


drop expanded
expand 2 if variable!=variable[_n-1], gen(expanded)
replace level = -1 if expanded==1
drop expanded
*expand 3 if variable=="htdiag_or_highbp" & level==-1, gen(expanded)
*replace level = -99 if variable=="htdiag_or_highbp" & expanded==1
expand 2 if level == -1, gen(expanded)
replace level = -99 if expanded==1

for var hr lci uci pval : replace X=. if level<0
sort varorder level

gen varx = 0.07
gen levelx = 0.071
gen lowerlimit = 0.15

*Names
gen Name = variable if (level==-1&!(level[_n+1]==0&variable!="male"))|(level==1&level[_n-1]==0&variable!="male")
replace Name = subinstr(Name, "_", " ", 10)
replace Name = upper(substr(Name,1,1)) + substr(Name,2,.)
replace Name = "Age group" if Name=="Agegroup"
replace Name = "Sex" if Name=="Male"
replace Name = "Obesity" if Name=="Obese4cat"
replace Name = "Smoking status" if Name=="Smoke nomiss"
replace Name = "Deprivation (IMD) quintile" if Name=="Imd"
replace Name = "Hypertension/high bp" if Name=="Htdiag or highbp"
replace Name = "Asthma" if Name=="asthma"
replace Name = "Diabetes" if Name=="diabetes"
replace Name = "Cancer (non-haematological)" if Name=="Cancer exhaem cat"
replace Name = "Haematological malignancy" if Name=="Cancer haem cat"
replace Name = "Stroke or dementia" if Name=="Stroke dementia"
replace Name = "Other neurological" if Name=="Other neuro"
replace Name = "Rheumatoid arthritis/Lupus/Psoriasis" if Name=="Ra sle psoriasis"
replace Name = "Reduced kidney function" if Name=="Reduced kidney function cat"
replace Name = "Asplenia" if Name=="Spleen"

*Levels
gen leveldesc = ""
replace leveldesc = "18-39" if variable=="agegroup" & level==1
replace leveldesc = "40-49" if variable=="agegroup" & level==2
replace leveldesc = "50-59 (ref)" if variable=="agegroup" & level==3
replace leveldesc = "60-69" if variable=="agegroup" & level==4
replace leveldesc = "70-79" if variable=="agegroup" & level==5
replace leveldesc = "80+" if variable=="agegroup" & level==6

replace leveldesc = "Female (ref)" if variable=="male" & level==0
replace leveldesc = "Male" if variable=="male" & level==1

replace leveldesc = "Not obese (ref)" if variable=="obese4cat" & level==1
replace leveldesc = "Obese class I" if variable=="obese4cat" & level==2
replace leveldesc = "Obese class II" if variable=="obese4cat" & level==3
replace leveldesc = "Obese class III" if variable=="obese4cat" & level==4

replace leveldesc = "Never (ref)" if variable=="smoke_nomiss" & level==1
replace leveldesc = "Ex-smoker" if variable=="smoke_nomiss" & level==2
replace leveldesc = "Current" if variable=="smoke_nomiss" & level==3

replace leveldesc = "White (ref)" if variable=="ethnicity" & level==1
replace leveldesc = "Mixed" if variable=="ethnicity" & level==2
replace leveldesc = "Asian/Asian British" if variable=="ethnicity" & level==3
replace leveldesc = "Black" if variable=="ethnicity" & level==4
replace leveldesc = "Other" if variable=="ethnicity" & level==5

replace leveldesc = "1 (least deprived, ref)" if variable=="imd" & level==1
replace leveldesc = "2" if variable=="imd" & level==2
replace leveldesc = "3" if variable=="imd" & level==3
replace leveldesc = "4" if variable=="imd" & level==4
replace leveldesc = "5 (most deprived)" if variable=="imd" & level==5

replace leveldesc = "No diabetes (ref)" if variable=="diabetes" & level==1
replace leveldesc = "Controlled (HbA1c <58mmol/mol)" if variable=="diabetes" & level==2
replace leveldesc = "Uncontrolled (HbA1c >=58mmol/mol) " if variable=="diabetes" & level==3
replace leveldesc = "Unknown HbA1c" if variable=="diabetes" & level==4

replace leveldesc = "No asthma (ref)" if variable=="asthma" & level==1
replace leveldesc = "With no recent OCS use" if variable=="asthma" & level==2
replace leveldesc = "With recent OCS use" if variable=="asthma" & level==3

replace leveldesc = "Never (ref)" if substr(variable,1,6)=="cancer" & level==1
replace leveldesc = "<1 year ago" if substr(variable,1,6)=="cancer" & level==2
replace leveldesc = "1-4.9 years ago" if substr(variable,1,6)=="cancer" & level==3
replace leveldesc = "5+ years ago" if substr(variable,1,6)=="cancer" & level==4

replace leveldesc = "None (ref)" if variable=="reduced_kidney_function_cat" & level==1
replace leveldesc = "eGFR 30-60 ml/min/1.73m2" if variable=="reduced_kidney_function_cat" & level==2
replace leveldesc = "eGFR <30 ml/min/1.73m2" if variable=="reduced_kidney_function_cat" & level==3


*replace leveldesc = "Absent" if level==0
*replace leveldesc = "Present" if level==1 & leveldesc==""
drop if level==0 & variable!="male"


gen obsorder=_n
gsort -obsorder
gen graphorder = _n
sort obsorder

*merge 1:1 variable level using c:\statatemp\tptemp, update replace

gen displayhrci = "<<< HR = " + string(hr, "%3.2f") + " (" + string(lci, "%3.2f") + "-" + string(uci, "%3.2f") + ")" if lci<0.15

scatter graphorder hr if lci>=.15, mcol(black)	msize(small)		///										///
	|| rcap lci uci graphorder if lci>=.15, hor mcol(black)	lcol(black)			///
	|| scatter graphorder lowerlimit, m(i) mlab(displayhrci) mlabcol(black) mlabsize(tiny) ///
	|| scatter graphorder varx , m(i) mlab(Name) mlabsize(tiny) mlabcol(black) 	///
	|| scatter graphorder levelx, m(i) mlab(leveldesc) mlabsize(tiny) mlabcol(gs8) 	///
		xline(1,lp(dash)) 															///
		xscale(log) xlab(0.25 0.5 1 2 5 10) xtitle("Hazard Ratio & 95% CI") ylab(none) ytitle("")						/// 
		legend(off)  ysize(8) 

graph export ./output/an_tablecontent_HRtable_HRforest_`outcome'.svg, as(svg) replace

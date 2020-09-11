*************************************************************************
*Purpose: Create content that is ready to paste into a pre-formatted Word 
* shell table containing sensitivity analysis (complete case for BMI and smoking, 
*and ethnicity) 
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
forvalues x=0/1 {
file write tablecontents_sense ("age") ("`x'") _n
foreach sense in CCeth_bmi_smok CCeth CCnoeth_bmi_smok noeth_12mo age_underlying_timescale time_int {
file write tablecontents_sense _n ("sense=") ("`sense'") _n
forvalues i=1/2 {
local endwith "_tab"

	*put the varname and condition to left so that alignment can be checked vs shell
	file write tablecontents_sense ("`variable'") _tab ("`i'") _tab
	
	foreach modeltype of any fulladj {
	
		local noestimatesflag 0 /*reset*/

*CHANGE THE OUTCOME BELOW TO LAST IF BRINGING IN MORE COLS
		if "`modeltype'"=="fulladj" local endwith "_n"

		***********************
		*1) GET THE RIGHT ESTIMATES INTO MEMORY
		
		/*if "`modeltype'"=="minadj" & "`variable'"!="agegroup" & "`variable'"!="male" {
			cap estimates use ./output/an_univariable_cox_models_`outcome'_AGESEX_`variable'_ageband_`x'
			if _rc!=0 local noestimatesflag 1
			}
		if "`modeltype'"=="demogadj" {
			cap estimates use ./output/an_multivariate_cox_models_`outcome'_`variable'_DEMOGADJ_`sense'_ageband_`x'
			if _rc!=0 local noestimatesflag 1
			}*/
		if "`modeltype'"=="fulladj" {
	    cap estimates use  ./output/an_sense_`outcome'_`sense'_ageband_`x'
				if _rc!=0 local noestimatesflag 1
				}
		
		***********************
		*2) WRITE THE HRs TO THE OUTPUT FILE
		
		if `noestimatesflag'==0 & "`modeltype'"=="fulladj" & "`sense'"!="multiple_imputation" {
			cap lincom `i'.`variable', eform
			if _rc==0 file write tablecontents_sense %4.2f (r(estimate)) (" (") %4.2f (r(lb)) ("-") %4.2f (r(ub)) (")") (e(N))  `endwith'
				else file write tablecontents_sense %4.2f ("ERR IN MODEL") `endwith'
			}
			
		*3) Save the estimates for plotting
		if `noestimatesflag'==0{
			if "`modeltype'"=="fulladj" & "`sense'"!="multiple_imputation"  {
				local hr = r(estimate)
				local lb = r(lb)
				local ub = r(ub)
				local N=e(N)
				post HRestimates_sense ("`x'") ("`outcome'") ("`variable'") ("`sense'") (`i') (`hr') (`lb') (`ub') (`N') 
				}
		}	
		} /*min adj, full adj*/
		
} /*variable levels*/

/*forvalues i=2/3 {
local endwith "_tab"

	*put the varname and condition to left so that alignment can be checked vs shell
	file write tablecontents_sense ("`variable'") _tab ("`i'") _tab
	
	foreach modeltype of any fulladj {
	
		local noestimatesflag 0 /*reset*/

*CHANGE THE OUTCOME BELOW TO LAST IF BRINGING IN MORE COLS
		if "`modeltype'"=="fulladj" local endwith "_n"

		***********************
		*1) GET THE RIGHT ESTIMATES INTO MEMORY
		
		/*if "`modeltype'"=="minadj" & "`variable'"!="agegroup" & "`variable'"!="male" {
			cap estimates use ./output/an_univariable_cox_models_`outcome'_AGESEX_`variable'_ageband_`x'
			if _rc!=0 local noestimatesflag 1
			}
		if "`modeltype'"=="demogadj" {
			cap estimates use ./output/an_multivariate_cox_models_`outcome'_`variable'_DEMOGADJ_`sense'_ageband_`x'
			if _rc!=0 local noestimatesflag 1
			}*/
		if "`modeltype'"=="fulladj" {
		cap estimates use  ./output/an_sense_`outcome'_`sense'_ageband_`x'
				if _rc!=0 local noestimatesflag 1
				}
		
		***********************
		*2) WRITE THE HRs TO THE OUTPUT FILE
		
		
		if `noestimatesflag'==0 & "`modeltype'"=="fulladj" & "`sense'"=="multiple_imputation" {
			local hr = exp( el(e(b_mi),1,`i') )
			di `hr'
			local lb = exp( el(e(b_mi),1,`i')  - 1.96*  sqrt(el(e(V_mi),2,`i'))  )
			di `lb'
			local ub = exp( el(e(b_mi),1,`i')  + 1.96*  sqrt(el(e(V_mi),2,`i'))  )
			if _rc==0 file write tablecontents_sense %4.2f (`hr') (" (") %4.2f (`lb') ("-") %4.2f (`ub') (")") `endwith'
				else file write tablecontents_sense %4.2f ("ERR IN MODEL") `endwith'
			}
				
		*3) Save the estimates for plotting
			if "`modeltype'"=="fulladj" & "`sense'"=="multiple_imputation"  {
				local hr = exp( el(e(b_mi),1,`i') )
				local lb = exp( el(e(b_mi),1,`i')  - 1.96*  sqrt(el(e(V_mi),2,`i'))  )
				local ub = exp( el(e(b_mi),1,`i')  + 1.96*  sqrt(el(e(V_mi),2,`i'))  )
				local N=e(N)
				post HRestimates_sense ("`x'") ("`outcome'") ("`variable'") ("`sense'") (`i') (`hr') (`lb') (`ub') (`N') 
				}

		} /*min adj, full adj*/
		
} /*variable levels*/
*/
} /*age levels*/
} /*sense levels*/

end

*MAIN CODE TO PRODUCE TABLE CONTENTS


cap file close tablecontents_sense
file open tablecontents_sense using ./output/12_an_sense_HRtable_`outcome'_SENSE_ANALYSES.txt, t w replace 

tempfile HRestimates_sense
cap postutil clear
postfile HRestimates_sense str10 x str10 outcome str27 variable str27 sense i hr lci uci N using `HRestimates_sense'


*Primary exposure
outputHRsforvar, variable("kids_cat3") min(1) max(2) outcome(`outcome')
file write tablecontents_sense _n

file close tablecontents_sense

postclose HRestimates_sense

*use `HRestimates_sense', clear
*save HRestimates_sense, replace
*stop


forvalues x=0/1 {

use `HRestimates_sense', clear
keep if x=="`x'"
drop outcome variable
gen varorder = 1 


recode i 2=1 if sense=="multiple_imputation" 
recode i 3=2 if sense=="multiple_imputation" 


sort varorder sense i
drop varorder

gen obsorder=_n
expand 2 if sense!=sense[_n-1], gen(expanded)
gsort obsorder -expanded 

for var hr lci uci: replace X = 1 if expanded==1

drop obsorder
gen obsorder=_n


expand 2 if expanded==1, gen(expanded2)
drop obsorder
gsort sense i -expanded -expanded2
gen obsorder=_n

for var hr lci uci : replace X=. if expanded==1 & expanded2==1

gen varx = 0.03
gen levelx = 0.033
gen intx=0.08
gen lowerlimit = 0.15
gen disx=2.5

*Levels
gen leveldesc = ""
replace leveldesc = "Children under 12 years" if i==1 & hr!=1 & hr!=.
replace leveldesc = "Children/young people aged 11-<18 years" if i==2

gen Name = sense if hr==1

foreach type in CCeth_bmi_smok CCeth CCnoeth_bmi_smok noeth_12mo age_underlying_timescale multiple_imputation time_int {
sum N if sense=="`type'"
local number_`type'=r(mean)
di `number_`type''
}


replace Name = "Additionally adjusting for ethnicity (N=`number_CCeth')" if Name=="CCeth"
replace Name = "Additionally adjusting for ethnicity, BMI and smoking, where data is complete  (N=`number_CCeth_bmi_smok')" if Name=="CCeth_bmi_smok"
replace Name = "Restricted to participants with complete data on BMI and smoking  (N=`number_CCnoeth_bmi_smok')" if Name=="CCnoeth_bmi_smok"
replace Name = "Age used as the underlying timescale in the cox model  (N=`number_age_underlying_timescale')" if Name=="age_underlying_timescale"
replace Name = "Participants with at least 12 months registration at GP  (N=`number_noeth_12mo')" if Name=="noeth_12mo"
replace Name = "Non-PH fitted (N=`number_time_int')" if Name=="time_int"
replace Name = "Using multiple imputation to handle missing ethnicity data  (N=`number_multiple_imputation')" if Name=="multiple_imputation"


for var hr lci uci: replace X = . if X==1


gen displayhrci = string(hr, "%3.2f") + " (" + string(lci, "%3.2f") + "-" + string(uci, "%3.2f") + ")"
replace displayhrci="" if hr==.
list display 

drop obsorder
gen obsorder=_n
gsort -obsorder
gen graphorder = _n
sort graphorder
list graphorder Name leveldesc hr  lci uci 

gen hrtitle="Hazard Ratio (95% CI)" if graphorder == 28

gen bf_hrtitle = "{bf:" + hrtitle + "}" 
gen bf_Name = "{bf:" + Name + "}" 

scatter graphorder hr, mcol(black)	msize(small)		///										///
	|| rcap lci uci graphorder, hor mcol(black)	lcol(black)			///
	|| scatter graphorder varx , m(i) mlab(bf_Name) mlabsize(vsmall) mlabcol(black) 	///
	|| scatter graphorder levelx, m(i) mlab(leveldesc) mlabsize(vsmall) mlabcol(black) 	///
	|| scatter graphorder disx, m(i) mlab(displayhrci) mlabsize(vsmall) mlabcol(black) ///
	|| scatter graphorder disx, m(i) mlab(bf_hrtitle) mlabsize(vsmall) mlabcol(black) ///
		xline(1,lp(dash)) 															///
		xscale(log range(0.1 6)) xlab(0.5 1 2, labsize(vsmall)) xtitle("")  ///
		ylab(none) ytitle("")		yscale( lcolor(white))					/// 
		graphregion(color(white))  legend(off)  ysize(4) ///
		text(-2 0.2 "Lower risk in those living with children", place(e) size(vsmall)) ///
		text(-2 1.5 "Higher risk in those living with children", place(e) size(vsmall))

graph export ./output/12_an_HRforest_SENSE_`outcome'_ageband_`x'.svg, as(svg) replace
}

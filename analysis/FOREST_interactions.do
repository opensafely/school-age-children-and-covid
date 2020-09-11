
*******************************************************************************
*>> HOUSEKEEPING
*******************************************************************************/
/*clear

version 15
clear all
capture log close

* create a filename global that can be used throughout the file
global filename "forest_plot"

global globalpath "C:\Users\ENCDHFOR\Dropbox\EHR-Working\Harriet\Covid19\Schools_study\graphs/"

ssc install metan
*ssc install admetan

/*
/*******************************************************************************
#1. graph for each outcome, and age group
*******************************************************************************/
*cat_time shield
foreach outcome of any non_covid_death covid_tpp_prob covidadmission covid_icu covid_death {
foreach age in 0 1  {

import delimited ./output/11_an_int_tab_contents_HRtable_`outcome'.txt, clear
keep if age==`age'

list

gen log_est = log(hr)
gen log_lci = log(lci)
gen log_uci = log(uci)
lab define  age 0 "Age <=65 years" 1 "Age>65 years"
lab values age age

lab define exposurelevel 1 "Children under 12 years" 2 "Children/young people aged 11-<18 years" 
lab val exposurelevel exposurelevel

replace int_type= "Time period" if int_type=="cat_time"
replace int_type= "Sex" if int_type=="male"
replace int_type= "Shielding" if int_type=="shield"

gen int_level_new="Female" if int_type=="Sex" & int_level==0
replace int_level_new="Male" if int_type=="Sex" & int_level==1
replace int_level_new="Time before 3rd April 2020" if int_type=="Time period" & int_level==0
replace int_level_new="Time after 3rd April 2020" if int_type=="Time period" & int_level==1
replace int_level_new="Not shielding" if int_type=="Shielding" & int_level==0
replace int_level_new="Probable shielding" if int_type=="Shielding" & int_level==1

lab var int_level_new "Level"
lab var int_type "Interaction"

if "`outcome'"=="non_covid_death" {
local title="Non-covid-19 death" 
}
if "`outcome'"=="covid_tpp_prob" {
local title="COVID-19 probable clinical infection"
}
if "`outcome'"=="covid_icu" {
local title="COVID-19 ICU admission" 
}
if "`outcome'"=="covid_death" {
local title="COVID-19 death" 
}
if "`outcome'"=="covidadmission" {
local title="COVID-19 hospital admission" 
}
   
if "`age'"=="1" {
local agetitle="Age>65 years" 
}
if "`age'"=="0" {
local agetitle="Age <=65 years"
}
**********************************************************************
***Pool the odds ratios for the studies
**********************************************************************
metan log_est log_lci log_uci, eform random ///
	lcols(int_type int_level_new ) olineopt(lpattern(dash) lwidth(vthin)) ///
	diamopt(lcolor(blue)) ///
	nowarning nobox effect(Hazard Ratio) xlab (.8,1,1.25,1.5)  ///
	graphregion(color(white)) nooverall nowt nohet texts(100) astext(55) ///
	nosubgroup by(exposurelevel) title("`title': `agetitle'", size(small))
	graph export "\`outcome'_`age'.png", as(png) replace 

	} /*ages*/
	
} /*outcomes*/	

* Combine histograms

	
*graph export "H:\Work\aceiarb_infection/$filename.png", as(png) replace
*********************************************************************/
/*
admetan log_est log_lci log_uci, by(country) effect(Hazard Ratio) ///
	random nohet nosubgroup nooverall nowt nokeepvars ///
	forestplot(favours(Favours continuing # Favours stopping) ///
	lcols(country outcome) leftjustify astext(55))
*/
*/
/*******************************************************************************
#1. graph for interaction type
*******************************************************************************/
*cat_time shield
foreach outcome of any non_covid_death covid_tpp_prob covidadmission covid_icu covid_death {
import delimited ./output/11_an_int_tab_contents_HRtable_`outcome'.txt, clear
save $globalpath/`outcome', replace
}

use $globalpath/non_covid_death, clear
foreach outcome of any covid_tpp_prob covidadmission covid_icu covid_death {
append using $globalpath/`outcome'
}
save $globalpath/interactions_all, replace
*/


use $globalpath/interactions_all, clear
foreach int_type in male {

use $globalpath/interactions_all, clear
keep if int_type=="`int_type'"

list

gen log_est = log(hr)
gen log_lci = log(lci)
gen log_uci = log(uci)
lab define  age 0 "Age <=65 years" 1 "Age>65 years"
lab values age age

lab define exposurelevel 1 "Children under 12 years" 2 "Children/young people aged 11-<18 years" 
lab val exposurelevel exposurelevel

replace int_type= "Time period" if int_type=="cat_time"
replace int_type= "Sex" if int_type=="male"
replace int_type= "Shielding" if int_type=="shield"

gen int_level_new="Female" if int_type=="Sex" & int_level==0
replace int_level_new="Male" if int_type=="Sex" & int_level==1
replace int_level_new="Time before 3rd April 2020" if int_type=="Time period" & int_level==0
replace int_level_new="Time after 3rd April 2020" if int_type=="Time period" & int_level==1
replace int_level_new="Not shielding" if int_type=="Shielding" & int_level==0
replace int_level_new="Probable shielding" if int_type=="Shielding" & int_level==1

lab var int_level_new "Level"
lab var int_type "Interaction"

replace outcome="Non-covid-19 death" if outcome=="non_covid_death"
replace outcome="COVID-19 probable clinical infection" if outcome=="covid_tpp_prob"
replace outcome="COVID-19 ICU admission"  if outcome=="covid_icu"
replace outcome="COVID-19 death"  if outcome=="covid_death"
replace outcome="COVID-19 hospital admission"  if outcome=="covidadmission"

if "`age'"=="1" {
local agetitle="Age>65 years" 
}
if "`age'"=="0" {
local agetitle="Age <=65 years"
}
sort outcome int_level_new exposurelevel
**********************************************************************
***Pool the odds ratios for the studies
**********************************************************************
metan log_est log_lci log_uci, eform random ///
	lcols(outcome exposurelevel int_level_new ) olineopt(lpattern(dash) lwidth(vthin)) ///
	diamopt(lcolor(blue)) ///
	nowarning nobox effect(Hazard Ratio) xlab (.8,1,1.25,1.5)  ///
	graphregion(color(white)) nooverall nowt nohet texts(100) astext(55) ///
	nosubgroup by(age) title("`title': `agetitle'", size(small))
	graph export $globalpath/interactions_`int_type'.png", as(png) replace 

	} /*ages*/
	
} /*outcomes*/	

* Combine histograms

	
*graph export "H:\Work\aceiarb_infection/$filename.png", as(png) replace
*********************************************************************/
/*
admetan log_est log_lci log_uci, by(country) effect(Hazard Ratio) ///
	random nohet nosubgroup nooverall nowt nokeepvars ///
	forestplot(favours(Favours continuing # Favours stopping) ///
	lcols(country outcome) leftjustify astext(55))
*/


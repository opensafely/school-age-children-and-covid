
  
********************************************************************************
*
*	Do-file:		WORMS_05_an_descriptive_plots.do
*
*	Project:		Exposure children and COVID risk
*
*	Programmed by:	hforbes, based on file from Elizabeth Williamson
*
*	Data used:		analysis_dataset.dta
*
*	Data created:	None
*
*	Other output:	Kaplan-Meier plots (intended for publication)
*							output/km_age_sex_covid_death_itu.svg 	
*							output/km_age_sex_covid_tpp_prob_or_susp
*
********************************************************************************
*
*	Purpose:		This do-file creates Kaplan-Meier plots by age and sex. 
*  
********************************************************************************
*	
*	Stata routines needed:	grc1leg	
*
********************************************************************************
forvalues x=0/1 {

use "$tempdir\cr_create_analysis_dataset_STSET_worms_ageband_`x'.dta", clear

****************************
*  KM plot by age and sex  *
****************************

*** Intended for publication


* KM plot for females by age		
sts graph if male==0, title("Female") 				///
	failure by(agegroup) 							///
	xtitle(" ")					///
	yscale(range(0, 0.008)) 						///
	ylabel(0 (0.002) 0.008, angle(0) format(%4.3f))	///
	xscale(range(30, 100)) 							///
	xlabel(0 "1 Feb 20" 29 "1 Mar 20" 				///
		60 "1 Apr 20" 91 "1 May 20")	 			///
	legend(order(1 2 3 4 5 6)						///
	subtitle("Age group", size(small)) 				///
	label(1 "18-<40") label(2 "40-<50") 			///
	label(3 "50-<60") label(4 "60-<70")				///
	label(5 "70-<80") label(6 "80+")				///
	col(3) colfirst size(small))	noorigin		///
	plot1opts(lcolor(gs11) lpattern(dot))			///
	plot2opts(lcolor(gs11) 	lpattern(shortdash))	///
	plot3opts(lcolor(gs9) lpattern(shortdash_dot)) 	///
	plot4opts(lcolor(gs6)  lpattern(longdash)) 		///
	plot5opts(lcolor(gs3)   lpattern(longdash_dot)) ///
	plot6opts(lcolor(gs0) lpattern(solid))  		///
	saving(female, replace)
* KM plot for males by age		
sts graph if male==1, title("Male") 				///
failure by(agegroup) 								///
	xtitle(" ")										///
	yscale(range(0, 0.008)) 						///
	ylabel(0 (0.002) 0.008, angle(0) format(%4.3f))	///
	xscale(range(30, 100)) 							///
	xlabel(0 "1 Feb 20" 29 "1 Mar 20" 				///
		60 "1 Apr 20" 91 "1 May 20")	 			///
	legend(order(1 2 3 4 5 6)						///
	subtitle("Age group", size(small)) 				///
	label(1 "18-<40") label(2 "40-<50") 			///
	label(3 "50-<60") label(4 "60-<70")				///
	label(5 "70-<80") label(6 "80+")				///
	col(3) colfirst size(small))	noorigin		///
	plot1opts(lcolor(gs11) lpattern(dot))			///
	plot2opts(lcolor(gs11) 	lpattern(shortdash))	///
	plot3opts(lcolor(gs9) lpattern(shortdash_dot)) 	///
	plot4opts(lcolor(gs6)  lpattern(longdash)) 		///
	plot5opts(lcolor(gs3)   lpattern(longdash_dot)) ///
	plot6opts(lcolor(gs0) lpattern(solid))  		///
	saving(male, replace)	
* KM plot for males and females 
grc1leg female.gph male.gph, 						///
	t1(" ") l1title("Cumulative probability" "of worms", size(medsmall))
graph export "output/km_age_sex_worms_ageband_`x'.svg", as(svg) replace

* Delete unneeded graphs
erase female.gph
erase male.gph


*********************

}

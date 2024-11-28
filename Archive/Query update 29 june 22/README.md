# Pfizer SHTG sql
 sql code for Pfizer sHTG project
 
 Instructions for query execution for Pfizer sHTG/ASCVD project:

This set of queries has 2 sections, Query 1 and Query 2, that are  two separate but related groups of patients. A lot of the tables generated will be the same for Query 1 and Query 2. 

Note: The scope calls these two sections “queries” so that’s what I’ll call them too, but each section is actually made up of many different sql queries. 

There are also two sets of folders - one for Oracle, and one for sql server. 

For each “query”, I’ll first define the cohorts, and then use those cohorts to generate tables with demographics, lab distributions etc. Each step will write some tables to disk, and the last query will pull all of the written queries and should be saved in csv files. Saving all as sheets in one excel file is also fine. 

Queries should be run in  the following order:


Q1:

Define Q1 cohorts: 
		
		Pfizer_shtg_Q1_cohort_definition.sql (run time ~25 mins, save Q1_T0 to csv file)
 

Run this next: 

		Q1_labs_part 1.sql (run time ~40 mins)

Then the rest of the tables can be run in any order:

		Q1_T1_shtg.sql	
			(run time ~2 mins; save Q1_T1 to csv file)
		Q1_T2_comorbidities.sql 
			(run time ~3 mins; save Q1_T2 to csv file)
		Q1_T3 _labs.sql 
			(run time ~8 mins x2, save Q1_T3a and Q1_T3b to csv files)
		Q1_T4-T6.sql 
 			(run time ~1 minute;save Q1_T4, Q1_T5 and Q1_t6 to csv files )
		Q1_T7_T8_meds.sql 
 			(run time ~ 4 mins save Q1_T7, Q1_T8  to csv files)
		Q1_table9.sql   
 			(run time ~3 mins; save Q1_T9 to csv file)


Q2:

		Define Q2 cohorts:
				Q2_cohort_definition_part1.sql 
					(run time ~35 mins)
				Q2_cohort_definition_part2_labs.sql 
					(run time ~35 mins)
				Q2_cohort_definition_part3_cohort_groups.sql 
					(run time ~10 mins)

After that the queries can be run in any order. Q2 doesn’t have T9, but has a T10 that Q1 doesn’t have. 
Run times as for Q1. 









# Pfizer SHTG sql
 sql code for Pfizer sHTG project
 
 Instructions for query execution for Pfizer sHTG/ASCVD project:

This set of queries has 2 sections, Query 1 and Query 2, that are  two separate but related groups of patients. A lot of the tables generated will be the same for Query 1 and Query 2. 

Note: The scope calls these two sections “queries” so that’s what I’ll call them too, but each section is actually made up of many different sql queries. 

There are also two sets of folders - one for Oracle, and one for sql server. 

For each “query”, I’ll first define the cohorts, and then use those cohorts to generate tables with demographics, lab distributions etc. Each step will write some tables to disk, and the last query will pull all of the written queries and should be saved in csv files. 

Queries should be run in  the following order:


Q1:

Define Q1 cohorts: 
Pfizer_shtg_Q1_cohort_definition.sql

Run this next: Q1_labs_part 1.sql

Then the rest of the tables can be run in any order:
Q1_T1_shtg.sql
Q1_T2_comorbidities.sql
Q1_T3 _labs.sql
Q1_T4-T6.sql
Q1_T7_T8_meds.sql
Q1_table9.sql


Q2:

Define Q2 cohorts:
Q2_cohort_definition_part1.sql
Q2_cohort_definition_part2_labs.sql
Q2_cohort_definition_part3_cohort_groups.sql

After that the queries can be run in any order. Q2 doesn’t have T9, but has a T10 that Q1 doesn’t have. 










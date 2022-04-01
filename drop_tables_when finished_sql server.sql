--This code will drop all of the tables written to disk once all of the queries are totally finished.
-- syntax is for sql server
-- I would leave them for now, if you don't need the space, since we may need to edit to fix bugs etc.

--Q1:
IF OBJECT_ID(foo.dbo.SHTG_COHORT_DEFINITION) IS NOT NULL
    DROP TABLE foo.dbo.SHTG_COHORT_DEFINITION;
IF OBJECT_ID(foo.dbo.shtg_q1_total_counts) IS NOT NULL
    DROP TABLE foo.dbo.shtg_q1_total_counts;
IF OBJECT_ID(foo.dbo.SHTG_Q1_COHORTS_WITH_EXCLUSIONS) IS NOT NULL
    DROP TABLE foo.dbo.SHTG_Q1_COHORTS_WITH_EXCLUSIONS;
IF OBJECT_ID(foo.dbo.SHTG_Q1_COHORTS_WITH_EX) IS NOT NULL
    DROP TABLE foo.dbo.SHTG_Q1_COHORTS_WITH_EX;
IF OBJECT_ID(foo.dbo.Q1_Labs_all) IS NOT NULL
    DROP TABLE foo.dbo.Q1_Labs_all;


Q2:


IF OBJECT_ID(foo.dbo.SHTG_Q2_Step1_D5) IS NOT NULL
    DROP TABLE foo.dbo.SHTG_Q2_Step1_D5;
IF OBJECT_ID(foo.dbo.SHTG_Q2_STEP3_D5) IS NOT NULL
    DROP TABLE foo.dbo.SHTG_Q2_STEP3_D5;
IF OBJECT_ID(foo.dbo.Q2_Labs_all) IS NOT NULL
    DROP TABLE foo.dbo.Q2_Labs_all;
IF OBJECT_ID(foo.dbo.SHTG_MEDS_Q2) IS NOT NULL
    DROP TABLE foo.dbo.SHTG_MEDS_Q2;
IF OBJECT_ID(foo.dbo.SHTG_Q2_Step1) IS NOT NULL
    DROP TABLE foo.dbo.SHTG_Q2_Step1;

IF OBJECT_ID(SHTG_Q2_STEP3) IS NOT NULL
    DROP TABLE SHTG_Q2_STEP3;

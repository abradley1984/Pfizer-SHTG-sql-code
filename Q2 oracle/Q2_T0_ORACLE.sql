select count(patid), cohort from shtg_Q1_cohorts_with_ex group by cohort;

(
select count(distinct patid) as N ,'Have lab data' as label1 ,2 as order1 from SHTG_Q2_STEP1_d5
    union
select count(distinct patid) ,'Have lab data and over 18',3 from SHTG_Q2_STEP1_d5
where age>=18
union
select count(distinct patid) ,'Have lab data, over 18 and at least 180 days since first encounter',4 from SHTG_Q2_STEP1_d5
where age>=18 and pre_index_days>=180);

select count(patid) , cohort from SHTG_Q2_STEP3_d5

group by cohort
union
select count(patid), 'total all cohorts' from SHTG_Q2_STEP3_d5
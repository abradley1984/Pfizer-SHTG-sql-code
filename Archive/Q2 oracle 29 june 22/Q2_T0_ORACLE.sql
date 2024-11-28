-- This counts total population numbers with the required lab data.
/*
--Q1_T0 - save as csv or excel file
select * from (select * from shtg_Q1_total_counts
    union

select count(patid), cohort, 10 from shtg_Q1_cohorts_with_ex group by cohort)
order by order1, label1;*/

--Q2_T0 - save as csv or excel file
select * from (
select count(distinct patid) as N ,'Have lab data' as label1 ,2 as order1 from SHTG_Q2_STEP1_d5_pre_exc
    union
select count(distinct patid) ,'Have lab data and over 18',3 from SHTG_Q2_STEP1_d5_pre_exc
where age>=18
union
select count(distinct patid) ,'Have lab data, over 18 and at least 180 days since first encounter',4 from SHTG_Q2_STEP1_d5_pre_exc
where age>=18 and pre_index_days>=180
union

select count(patid) as N , cohort ,10 as order1 from SHTG_Q2_STEP3_d5

group by cohort
union
select count(patid), 'total all cohorts', 11 from SHTG_Q2_STEP3_d5)
order by order1, label1;
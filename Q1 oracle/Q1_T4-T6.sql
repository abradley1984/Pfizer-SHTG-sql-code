--Run time: <1 minute
--3 tables are output and should be saved to csv


 /*Q1_T4.csv*/ with pat_list as (select * from shtg_Q1_cohorts_with_ex)
select count(distinct patid) as N, TG_category, LDL_category2 from pat_list
group by TG_category, LDL_category2
union select count(distinct patid) as N, 'TG_total', LDL_category2 from pat_list
group by  LDL_category2
union select count(distinct patid) as N, 'LDL_total', TG_category from pat_list
group by  TG_category ;
--Q1_T5.csv
with pat_list as (select * from shtg_Q1_cohorts_with_ex)
select count(distinct patid) as N, TG_category, NHDL_category2 from pat_list
group by TG_category, NHDL_category2
union select count(distinct patid) as N, 'TG_total',  NHDL_category2 from pat_list
group by  NHDL_category2
union select count(distinct patid) as N, 'NHDL_total', TG_category from pat_list
group by  TG_category ;
--Q1_T6.csv
with pat_list as (select * from shtg_Q1_cohorts_with_ex)
select count(distinct patid) as N,  LDL_category2, NHDL_category2 from pat_list
group by  LDL_category2, NHDL_category2
union select count(distinct patid) as N, 'LDL_total',  NHDL_category2 from pat_list
group by  NHDL_category2
union select count(distinct patid) as N, 'NHDL_total', LDL_category2 from pat_list
group by  LDL_category2;
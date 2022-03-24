

 --Q1_T4.csv
with pat_list as (select * from shtg_Q1_cohorts_with_exclusions)
select count(distinct patid) as N, TG_category, LDL_category2 from pat_list
group by TG_category, LDL_category2
union select count(distinct patid) as N, 'LDL_total', LDL_category2 from pat_list
group by  LDL_category2
union select count(distinct patid) as N, 'Tg_total', TG_category from pat_list
group by  TG_category ;
--Q1_T5.csv
with pat_list as (select * from shtg_Q1_cohorts_with_exclusions)
select count(distinct patid) as N, TG_category, NHDL_category2 from pat_list
group by TG_category, NHDL_category2
union select count(distinct patid) as N, 'NHDL_total',  NHDL_category2 from pat_list
group by  NHDL_category2
union select count(distinct patid) as N, 'Tg_total', TG_category from pat_list
group by  TG_category ;
--Q1_T6.csv
with pat_list as (select * from shtg_Q1_cohorts_with_exclusions)
select count(distinct patid) as N,  LDL_category2, NHDL_category2 from pat_list
group by  LDL_category2, NHDL_category2
union select count(distinct patid) as N, 'NHDL_total',  NHDL_category2 from pat_list
group by  NHDL_category2
union select count(distinct patid) as N, 'LDL_total', LDL_category2 from pat_list
group by  LDL_category2;
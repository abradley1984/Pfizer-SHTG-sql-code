/* This outputs 3 tables, T4, T5 and T6
   Run time ~1 minute
 */

 --Q1_T4.csv
with pat_list as (select * from foo.dbo.shtg_Q1_cohort_with_exclusions)
select count(distinct patid) as N, TG_category, LDL_category2 from pat_list
group by TG_category, LDL_category2
union select count(distinct patid) as N, 'LDL_total', LDL_category2 from pat_list
group by  LDL_category2
union select count(distinct patid) as N, 'Tg_total', TG_category from pat_list
group by  TG_category ;
--Q1_T5.csv
with pat_list as (select * from foo.dbo.shtg_Q1_cohort_with_exclusions)
select count(distinct patid) as N, TG_category, NHDL_category2 from pat_list
group by TG_category, NHDL_category2
union select count(distinct patid) as N, 'NHDL_total',  NHDL_category2 from pat_list
group by  NHDL_category2
union select count(distinct patid) as N, 'Tg_total', TG_category from pat_list
group by  TG_category ;
--Q1_T6.csv
with pat_list as (select * from foo.dbo.shtg_Q1_cohort_with_exclusions)
select count(distinct patid) as N,  LDL_category2, NHDL_category2 from pat_list
group by  LDL_category2, NHDL_category2
union select count(distinct patid) as N, 'NHDL_total',  NHDL_category2 from pat_list
group by  NHDL_category2
union select count(distinct patid) as N, 'LDL_total', LDL_category2 from pat_list
group by  LDL_category2;
--Q2_T4.csv
with joined1 as (select *
                 from SHTG_Q2_STEP1_d5
                          join SHTG_Q2_STEP3_d1 using (patid)
                 where cohort is not null),
     pat_list as
         (
             select distinct *

             from joined1
         )
        
     select count(distinct patid) as N, TG_category, LDL_category2 from pat_list
group by TG_category, LDL_category2;
--Q2_T5.csv
with joined1 as (select *
                 from SHTG_Q2_STEP1_d5
                          join SHTG_Q2_STEP3_d1 using (patid)
                 where cohort is not null),
     pat_list as
         (
             select distinct *

             from joined1
         )
        
select count(distinct patid) as N, TG_category, NHDL_category2
from pat_list
group by TG_category, NHDL_category2;
--Q2_T6.csv
with joined1 as (select *
                 from SHTG_Q2_STEP1_d5
                          join SHTG_Q2_STEP3_d1 using (patid)
                 where cohort is not null),
     pat_list as
         (
             select distinct *

             from joined1
         )
        
select count(distinct patid) as N, LDL_category2, NHDL_category2
from pat_list
group by LDL_category2, NHDL_category2;
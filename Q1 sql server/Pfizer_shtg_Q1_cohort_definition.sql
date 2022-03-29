/* Q1 step 1 -editing for sql server version
This code defines the overall cohort for the first section of the SHTG query (Q1) as patients who
   -had a TG value in the one year study period (30-Sep-2020 to 30-Sep-2021)
   -had a TG>500, or had an LDL within the study period if their TG was <500,
   - had an NHDL within 30 days of their first TG.


   The output table is written to disk as:
 	shtg_Q1_cohort_definition_with_exclusions
        This lists all patients that meet inclusion and exclusion criteria, with their sub-cohort,  index lab values and age.
        One row per patient.
        This is used as the cohort definition for the rest of the tables

The code also outputs a general count table(T0), that will need to be saved to a csv file (Q1_table0.csv)
   

   Running time:
   running time at Pitt was <25 minutes.
   */


--Notes:
--Dates:TG and LDL dates should be enrollment period, total chol and HDL should be 30 days before.



DECLARE @DATE_START DATE = '2020-09-30';
DECLARE @DATE_END DATE = '2021-09-30' ;


select lab.patid,
                       row_number() OVER (
                           PARTITION BY lab.patid
                           ORDER BY lab.result_date ASC
                           )                     row_num,
                       lab.result_num  TG_result_num,
                       lab.result_unit result_unit,
                       lab.result_date
                    --   LAB.RAW_RESULT
                --FROM @cdm.@cdmschema.lab lab
into #TG_all
FROM lab_result_cm lab
               -- WHERE lab.result_date BETWEEN '2020-09-30' AND '2021-09-30'
                WHERE lab.result_date BETWEEN @DATE_START AND @DATE_END
AND lab.lab_loinc in ('2571-8', '12951-0')
                  AND not lab.result_unit in ('mg/d', 'g/dL', 'mL/min/{1.73_m2}') --Excluding rare weird units
                  and lab.result_num is not null
                  and lab.result_num >= 0
    --AND lab.result_num < 1000
    -- fetch first 1000 rows only
;
    select *
    into #TG
            from #TG_all
            where row_num = 1;
    select lab.patid,
                        row_number() OVER (
                            PARTITION BY lab.patid
                            ORDER BY lab.result_date asc
                            )                     row_num,
                        lab.result_num  as LDL_result_num,
                        lab.result_unit result_unit,
                        lab.result_date
into #LDL_all
                 --FROM @cdm.@cdmschema.lab lab
FROM lab_result_cm lab
                -- WHERE lab.result_date BETWEEN '2020-09-30' AND '2021-09-30'
                  WHERE lab.result_date BETWEEN @DATE_START AND @DATE_END
AND lab.lab_loinc in ('13457-7', '18262-6', '2089-1')
                   --and lab.patid in pat_list
                   and lab.result_num is not null
                   and lab.result_num >= 0
         --  AND not lab.result_unit in ('mg/d','g/dL','mL/min/{1.73_m2}') --Excluding rare weird units
         --AND lab.result_num < 1000
     ;
  select *
   into #LDL
             from #LDL_all

             where row_num = 1;

   select lab.patid,
                               row_number() OVER (
                                   PARTITION BY lab.patid
                                   ORDER BY lab.result_date ASC
                                   )                     row_num,
                               lab.result_num  total_chol_result_num,
                               lab.result_unit result_unit,
                               lab.result_date result_date
   into #total_chol_all
--FROM @cdm.@cdmschema.lab lab
FROM lab_result_cm lab
                -- WHERE lab.result_date BETWEEN '2020-09-30' AND '2021-09-30'
                  WHERE lab.result_date BETWEEN @DATE_START AND @DATE_END
                          AND lab.lab_loinc in ('2093-3')
                          and lab.result_num is not null
                          and lab.result_num >= 0
                          AND not lab.result_unit in
                                  ('mg/d', 'g/dL', 'mL/min/{1.73_m2}', 'mL/min') --Excluding rare weird units
     ;
     select *
     into #total_chol
                    from #total_chol_all
                    where row_num = 1;
     select lab.patid,
                        row_number() OVER (
                            PARTITION BY lab.patid
                            ORDER BY lab.result_date ASC
                            )                     row_num,
                        lab.result_num  HDL_result_num,
                        lab.result_unit result_unit,
                        lab.result_date
into #HDL_all
--FROM @cdm.@cdmschema.lab lab
from lab_result_cm lab
                -- WHERE lab.result_date BETWEEN '2020-09-30' AND '2021-09-30'
                  WHERE lab.result_date BETWEEN @DATE_START AND @DATE_END
                   AND lab.lab_loinc in ('2085-9')
                   and lab.result_num is not null
                   and lab.result_num >= 0
                   AND not lab.result_unit in
                           ('mg/d', 'g/dL', 'mL/min/{1.73_m2}', 'mL/min') --Excluding rare weird units
     ;

     select *
     into #HDL
             from #HDL_all
             where row_num = 1;
     /*count_labs as (
         select TG.patid,
                LDL.result_date        as LDL_date,
                LDL.LDL_result_num,
                TG.result_date         as TG_date,
                TG.TG_result_num,
                total_chol.result_date as TC_date,
                total_chol.total_chol_result_num,
                HDL.result_date        as HDL_date,
                HDL.HDL_result_num
         from TG
                  inner join LDL
                             on TG.patid = LDL.patid
                  inner join total_chol
                             on TG.patid = total_chol.patid
                  inner join HDL
                             on TG.patid = HDL.patid
     ),*/
select total_chol.patid,
                     total_chol.TOTAL_CHOL_RESULT_NUM - HDL.HDL_RESULT_NUM as NHDL,
                     total_chol.TOTAL_CHOL_RESULT_NUM                         CHOL_RESULT_NUM,
                     HDL.HDL_RESULT_NUM                                    as HDL_RESULT_NUM,
                     total_chol.RESULT_date                                as TC_date,
                     HDL.RESULT_date                                       as hdl_date
into #NHDL
              from #total_chol total_chol
                       inner join #HDL HDL
                                  on total_chol.patid = HDL.patid;

         select TG.PATID,
                LDL.LDL_RESULT_NUM,
                NHDL,
                TG.TG_RESULT_NUM,
                CHOL_RESULT_NUM,
                HDL_RESULT_NUM,
                TG.RESULT_DATE            as TG_date,
                LDL.RESULT_DATE           as LDL_date,
                HDL_DATE                  as nHDL_date,
datediff(dd,HDL_DATE,TG.RESULT_DATE) as nHDL_gap
         into #lab_list
         from #TG tg
                  left join #NHDL nhdl on tg.patid = nhdl.patid
                  left join #LDL ldl on tg.patid  = ldl.patid
         where datediff(dd, HDL_DATE,TG.RESULT_DATE) <= 30

           --Note:this is allowing for LDL to be null if TG>500

           and ((TG_RESULT_NUM <= 500 and LDL_result_num is not null and nhdl is not null)
             or (TG_RESULT_NUM > 500))
     ;

     --patients over 18
--patients with at least one encounter > 6 months ago

--This code adds columnns needed for exclusions including age and  first_encounter date
    select patid  into #pat_list from #lab_list;

         SELECT pats.patid as patid,
             /*pats.cohort,*/
                demo.sex,
                demo.race,
                demo.hispanic,
                demo.birth_date
into    #age_gender_race_ethnicity
         FROM #pat_list pats
                  INNER JOIN
 -- @cdm.@cdmschema.demographic demo
 demographic demo
 ON demo.patid = pats.patid

     ;
--First encounter, to calculate if we have 6 month pre-index.
    select patid, admit_date as first_admit_date
    into  #first_encounter
                         from (select row_number() OVER (
                             PARTITION BY encounter.patid
                             ORDER BY encounter.admit_date asc
)                         row_num,
                                      encounter.admit_date as admit_date,
                                      encounter.patid      as patid

                               from #pat_list p
                                        left join
--@cdm.@cdmschema.encounter encounter
encounter
on p.patid = encounter.patid) dummy
                         where row_num = 1
     ;

     select patid, admit_date as last_admit_date
into  #last_encounter
                        from (select row_number() OVER (
                            PARTITION BY encounter.patid
                            ORDER BY encounter.admit_date desc
                            )                                row_num,
                                     encounter.admit_date as admit_date,
                                     encounter.patid      as patid
                               from #pat_list p
                                        left join
--@cdm.@cdmschema.encounter encounter
encounter
on p.patid = encounter.patid) dummy
                        where row_num = 1
     ;


         select -- *
labs.PATID,
                labs.LDL_RESULT_NUM,
                labs.NHDL,
                labs.TG_RESULT_NUM,
                labs.CHOL_RESULT_NUM,
                labs.HDL_RESULT_NUM,
                labs.TG_date,
                labs.LDL_date,
                labs.nHDL_date,
                labs.nHDL_gap,
fe.first_admit_date,
le.last_admit_date,
dem.BIRTH_DATE,
dem.HISPANIC,
dem.RACE,
dem.SEX
into #joined
             from #lab_list labs
                      left join #first_encounter fe on labs.patid = fe.patid
                      left join #last_encounter le on labs.patid = le.patid
                      left join #age_gender_race_ethnicity dem on labs.patid = dem.patid
         ;

select #joined.*,
datediff(dd,first_admit_date, TG_DATE) as pre_index_days,
datediff(dd,TG_Date, last_admit_Date) as post_index_days,
datediff(dd,birth_date, TG_Date)/365.25 as age
into
#with_exclusions
from #joined
;
select *
into  --@dest.@destschema.shtg_Q1_cohort_definition_with_exclusions
    --CHECK Database name written to disk for site
HPLDev.dbo.shtg_Q1_cohort_definition_with_exclusions
from #with_exclusions
where age>18 and pre_index_days>180;

--Q1_Table0.csv (basic counts -  save to csv)

(select count(distinct patid)  as N, 'Total system population'  as label1, 1 as order1 from demographic
union
select count(distinct patid) ,'Have lab data',2 from #with_exclusions
    union
select count(distinct patid) ,'Have lab data and over 18',3 from #with_exclusions
where age>=18
union
select count(distinct patid) ,'Have lab data, over 18 and at least 180 days since first encounter',4 from #with_exclusions
where age>=18 and pre_index_days>=180);










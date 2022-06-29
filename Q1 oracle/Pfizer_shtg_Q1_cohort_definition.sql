/* Q1 step 1

   Note: I'm adding in upper fences for TG and LDL here, but those aren't reached by any site, so won't need to be rerun


    This code defines the overall cohort for the first section of the SHTG qery (Q1) as patients who
   -had a TG value in the one year study period (30-Sep-2020 to 30-Sep-2021)
   -had a TG>500, or had an LDL within the study period if their TG was <500,
   - had an NHDL within 30 days of their first TG.


   Outputs written are:
   table: shtg_Q1_total_counts
        This counts     the total system population,
                        patients who have the right lab data,
                        patients who are > 18 and
                        patients with at least 6 months of data.
     table: shtg_Q1_cohorts_with_ex:
        This lists all patients that meet inclusion and exclusion criteria, with their sub-cohort,  index lab values and age.
        One row per patient.
        This is used as the cohort definition for the rest of the tables

   table: shtg_cohort_definition:
        This is a temporary table needed to get the shtg_Q1_total_counts table prior to applying exclusion criteria to get shtg_Q1_cohorts_with_ex.

   Running time:
   running time at Pitt was ~25 minutes.
   */


--Notes:
--all dates need to be modified to final date range. TG and LDL dates should be enrollment period, total chol and HDL should be 30 days before.

/*
drop table shtg_cohort_definition;
drop table shtg_Q1_total_counts;
drop table shtg_Q1_cohorts_with_ex
  */

--create table shtg_cohort_definition_old_version as select * from shtg_cohort_definition;
    drop table shtg_cohort_definition;
   drop table shtg_Q1_cohorts_with_ex;
drop table shtg_q1_total_counts;
--list of patients who have triglycerides in study period
create table shtg_cohort_definition as
with TG_all as (select lab_result_cm.patid,
                       row_number() OVER (
                           PARTITION BY lab_result_cm.patid
                           ORDER BY lab_result_cm.result_date ASC
                           )                     row_num,

                       lab_result_cm.result_num  TG_result_num,
                       lab_result_cm.result_unit result_unit,
                       lab_result_cm.result_date,
                       LAB_RESULT_CM.RAW_RESULT

                FROM cdm_60_etl.lab_result_cm
                WHERE lab_result_cm.result_date BETWEEN TO_DATE('9/30/2020', 'MM/DD/YYYY') AND TO_DATE('9/30/2021', 'MM/DD/YYYY')
                  AND lab_result_cm.lab_loinc in ('2571-8', '12951-0')
                  AND not lab_result_cm.result_unit in ('mg/d', 'g/dL', 'mL/min/{1.73_m2}') --Excluding rare weird units
                  and lab_result_cm.result_num is not null
                  and lab_result_cm.result_num >= 0
    AND lab_result_cm.result_num < 30000
   -- fetch first 1000 rows only

),
     TG as (select *
            from TG_all
            where row_num = 1),
     LDL_all as (select lab_result_cm.patid,
                        row_number() OVER (
                            PARTITION BY lab_result_cm.patid
                            ORDER BY lab_result_cm.result_date asc
                            )                     row_num,
                        lab_result_cm.result_num  LDL_result_num,
                        lab_result_cm.result_unit result_unit,
                        lab_result_cm.result_date

                 FROM cdm_60_etl.lab_result_cm
                 WHERE lab_result_cm.result_date BETWEEN TO_DATE('9/30/2020', 'MM/DD/YYYY') AND TO_DATE('9/30/2021', 'MM/DD/YYYY')
                   AND lab_result_cm.lab_loinc in ('13457-7', '18262-6', '2089-1')
                   --and lab_result_cm.patid in pat_list
                   and lab_result_cm.result_num is not null
                   and lab_result_cm.result_num >= 0
        --  AND not lab_result_cm.result_unit in ('mg/d','g/dL','mL/min/{1.73_m2}') --Excluding rare weird units
         AND lab_result_cm.result_num < 10000

     ),
     LDL as (select *
             from LDL_all
             where row_num = 1),
     total_chol_all as (select lab_result_cm.patid,
                               row_number() OVER (
                                   PARTITION BY lab_result_cm.patid
                                   ORDER BY lab_result_cm.result_date ASC
                                   )                     row_num,
                               lab_result_cm.result_num  total_chol_result_num,
                               lab_result_cm.result_unit result_unit,
                               lab_result_cm.result_date result_date

                        FROM cdm_60_etl.lab_result_cm
                        WHERE lab_result_cm.result_date BETWEEN TO_DATE('08/31/2020', 'MM/DD/YYYY') AND TO_DATE('9/30/2021', 'MM/DD/YYYY')
                          AND lab_result_cm.lab_loinc in ('2093-3')
                          and lab_result_cm.result_num is not null
                          and lab_result_cm.result_num >= 0
                           and lab_result_cm.result_num <30000
           AND not lab_result_cm.result_unit in ('mg/d','g/dL','mL/min/{1.73_m2}', 'mL/min') --Excluding rare weird units


     ),
     total_chol as (select *
                    from total_chol_all
                    where row_num = 1),
     HDL_all as (select lab_result_cm.patid,
                        row_number() OVER (
                            PARTITION BY lab_result_cm.patid
                            ORDER BY lab_result_cm.result_date ASC
                            )                     row_num,
                        lab_result_cm.result_num  HDL_result_num,
                        lab_result_cm.result_unit result_unit,
                        lab_result_cm.result_date

                 FROM cdm_60_etl.lab_result_cm
                 WHERE lab_result_cm.result_date BETWEEN TO_DATE('08/31/2020', 'MM/DD/YYYY') AND TO_DATE('9/30/2021', 'MM/DD/YYYY')
                   AND lab_result_cm.lab_loinc in ('2085-9')
                 and lab_result_cm.result_num is not null
                   and lab_result_cm.result_num >= 0
                    and lab_result_cm.result_num <1000
         AND not lab_result_cm.result_unit in ('mg/d','g/dL','mL/min/{1.73_m2}', 'mL/min') --Excluding rare weird units


     ),
     HDL as (select *
             from HDL_all
             where row_num = 1),


     count_labs as (
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
     ),

     NHDL as (select total_chol.patid,
                     total_chol.TOTAL_CHOL_RESULT_NUM - HDL.HDL_RESULT_NUM as NHDL,
                     total_chol.TOTAL_CHOL_RESULT_NUM                         CHOL_RESULT_NUM,
                     HDL.HDL_RESULT_NUM                                    as HDL_RESULT_NUM,
                     total_chol.RESULT_date                                as TC_date,
                     HDL.RESULT_date                                       as hdl_date
              from total_chol
                       inner join HDL
                                  on total_chol.patid = HDL.patid),


lab_list as (
select PATID,
       LDL.LDL_RESULT_NUM,
       NHDL,
       TG.TG_RESULT_NUM,
       CHOL_RESULT_NUM,
       HDL_RESULT_NUM,
       TG.RESULT_DATE                 as TG_date,
       LDL.RESULT_DATE                as LDL_date,
       HDL_DATE                       as nHDL_date,
       TG.RESULT_DATE - HDL_DATE as nHDL_gap


from TG
         left join NHDL USING (PATID)
         left join LDL USING (PATID)

     where  TG.RESULT_DATE - HDL_DATE <=30

       --Note:this is allowing for LDL to be null if TG>500

    and( (TG_RESULT_NUM<=500 and LDL_result_num is not null and nhdl is not null)
        or (TG_RESULT_NUM>500))
      ),

     --patients over 18
--patients with at least one encounter > 6 months ago

--This code adds columnns needed for exclusions including age and  first_encounter date
pat_list as (select patid from lab_list),


     age_gender_race_ethnicity AS (
         SELECT pats.patid as patid,
             /*pats.cohort,*/
                demographic.sex,
                demographic.race,
                demographic.hispanic,
                demographic.birth_date

         FROM pat_list pats
                  INNER JOIN cdm_60_etl.demographic ON demographic.patid = pats.patid
     ),
--First encounter, to calculate if we have 6 month pre-index.
     first_encounter as (select patid, admit_date as first_admit_date
                         from (select row_number() OVER (
                             PARTITION BY encounter.patid
                             ORDER BY encounter.admit_date asc
                             )                                row_num,
                                      encounter.admit_date as admit_date,
                                      encounter.patid      as patid
                               from pat_list p
                                        left join cdm_60_etl.encounter encounter on p.patid = encounter.patid)
                         where row_num = 1
     )
        ,
     last_encounter as (select patid, admit_date as last_admit_date
                        from (select row_number() OVER (
                            PARTITION BY encounter.patid
                            ORDER BY encounter.admit_date desc
                            )                                row_num,
                                     encounter.admit_date as admit_date,
                                     encounter.patid      as patid
                              from pat_list p
                                       left join cdm_60_etl.encounter encounter on p.patid = encounter.patid)
                        where row_num = 1
     ),

 joined as
         (
             select *
             from lab_list labs
                      left join first_encounter e using (patid)
                      left join last_encounter e using (patid)
                      left join age_gender_race_ethnicity dem using (patid)

         )


--sql server age: floor(datediff(day, demographic.birth_date, '2020-08-31') / 365.25) as age

select joined.*,
       round(TG_DATE - first_admit_date)         as pre_index_days,
         round( last_admit_date-TG_DATE )         as post_index_days,
       round((TG_DATE - birth_date) / 365.25, 2) as age
from joined;

--Counts for table 0

create table shtg_Q1_total_counts as
(select count(distinct patid)  as N, 'Total system population'  as label1, 1 as order1 from cdm_60_etl.demographic
union
select count(distinct patid) ,'Have lab data',2 from shtg_cohort_definition
    union
select count(distinct patid) ,'Have lab data and over 18',3 from shtg_cohort_definition
where age>=18
union
select count(distinct patid) ,'Have lab data, over 18 and at least 180 days since first encounter',4 from shtg_cohort_definition
where age>=18 and pre_index_days>=180);

select * from shtg_q1_total_counts
order by order1;

create table shtg_Q1_cohorts_with_ex
as WITH labs as (select * from shtg_cohort_definition
where age>=18 and pre_index_days>=180),


     lab_labels as (select labs.*,
                           case
                               when TG_result_num < 150
                                   then 'TG_under_150'
                               when TG_result_num BETWEEN 150 and 500
                                   then 'TG_150_500'
                               when TG_result_num BETWEEN 500 and 880
                                   then 'TG_500_880'
                               when TG_result_num BETWEEN 880 and 2000
                                   then 'TG_880_2000'
                               when TG_result_num > 2000
                                   then 'TG_over_2000'
                               else 'other'
                               end as TG_category,
                           case
                               when LDL_result_num < 70
                                   then 'LDL_low'

                               when LDL_result_num >= 70
                                   then 'LDL_high'
                               when LDL_result_num < 0
                                   then 'LDL_below_0'
                               else 'other'
                               end as LDL_category,
                           case
                               when nHDL < 100
                                   then 'nHDL_low'

                               when nHDL >= 100
                                   then 'nHDL_high'
                               when LDL_result_num < 0
                                   then 'nHDL_below_0'
                               else 'other'
                               end as nHDL_category,
                           case
                               when LDL_result_num < 70
                                   then 'LDL_under_70'

                               when LDL_result_num between 70 and 100
                                   then 'LDL_70_to_100'

                               when LDL_result_num between 100 and 130
                                   then 'LDL_100_to_130'
                               when LDL_result_num between 130 and 160
                                   then 'LDL_130_to_160'
                               when LDL_result_num > 160
                                   then 'LDL_above 160'

                               else 'other'
                               end as LDL_category2,
                           case
                               when NHDL < 70
                                   then 'NHDL_under_70'

                               when NHDL between 70 and 100
                                   then 'NHDL_70_to_100'

                               when NHDL between 100 and 130
                                   then 'NHDL_100_to_130'
                               when NHDL between 130 and 160
                                   then 'NHDL_130_to_160'
                               when NHDL between 160 and 190
                                   then 'NHDL_160_to_190'
                               when NHDL > 190
                                   then 'NHDL_above 190'

                               else 'other'
                               end as NHDL_category2,
                           case
                               when Age < 18
                                   then 'Age_under_18'
                               when Age BETWEEN 18 and 40
                                   then 'Age_18_40'
                               when Age BETWEEN 40 and 55
                                   then 'Age_40_55'
                               when Age BETWEEN 55 and 65
                                   then 'Age_55_65'
 when Age BETWEEN 65 and 75
                                   then 'Age_65_75'
                               when Age > 75
                                   then 'Age_over_75'
                               else 'other'
                               end as Age_category
                    from labs),
     with_cohorts as (select case
                                 when TG_category = 'TG_over_2000' then 'cohort_1K'

                                 when TG_category = 'TG_880_2000' then 'cohort_1J'

                                 when TG_category = 'TG_500_880' then 'cohort_1I'

                                 when (TG_category = 'TG_150_500') AND (nHDL_category = 'nHDL_high') AND
                                      (LDL_category = 'LDL_high') then 'cohort_1E'

                                 when TG_category = 'TG_150_500' AND (nHDL_category = 'nHDL_low') AND
                                      (LDL_category = 'LDL_high') then 'cohort_1F'

                                 when TG_category = 'TG_150_500' AND (nHDL_category = 'nHDL_high') AND
                                      (LDL_category = 'LDL_low') then 'cohort_1H'

                                 when TG_category = 'TG_150_500' AND (nHDL_category = 'nHDL_low') AND
                                      (LDL_category = 'LDL_low') then 'cohort_1G'

                                 when (TG_category = 'TG_under_150') AND (nHDL_category = 'nHDL_high') AND
                                      (LDL_category = 'LDL_high') then 'cohort_1A'

                                 when TG_category = 'TG_under_150' AND (nHDL_category = 'nHDL_low') AND
                                      (LDL_category = 'LDL_high') then 'cohort_1B'

                                 when TG_category = 'TG_under_150' AND (nHDL_category = 'nHDL_high') AND
                                      (LDL_category = 'LDL_low') then 'cohort_1D'

                                 when TG_category = 'TG_under_150' AND (nHDL_category = 'nHDL_low') AND
                                      (LDL_category = 'LDL_low') then 'cohort_1C'
                                 end as COHORT,
                             lab_labels.*
                      from lab_labels)


select *
from with_cohorts

;
select count(distinct patid), cohort from shtg_Q1_cohorts_with_ex
group by cohort;










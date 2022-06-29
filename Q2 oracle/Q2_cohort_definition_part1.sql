/* SHTG Query 2 part 1 - first part of cohort definition, gathering a list of patient with LDL values in the study period, their ages and ASCVD history.

 */
create table SHTG_Q2_STEP1_d5_old as select * from SHTG_Q2_STEP1_d5;
drop table SHTG_Q2_STEP1_d5;
create table SHTG_Q2_STEP1_d5 as
 with 
TG_all as (select lab_result_cm.patid,
                  row_number() OVER (
                      PARTITION BY lab_result_cm.patid
                      ORDER BY lab_result_cm.result_date ASC
                      )                     row_num,

                  lab_result_cm.result_num  TG_result_num,
                  lab_result_cm.result_unit result_unit,
                  lab_result_cm.result_date,
                  LAB_RESULT_CM.RAW_RESULT

           FROM cdm_60_etl.lab_result_cm
           WHERE lab_result_cm.result_date BETWEEN TO_DATE('09/30/2020', 'MM/DD/YYYY') AND TO_DATE('09/30/2021', 'MM/DD/YYYY')
             AND lab_result_cm.lab_loinc in ('2571-8', '12951-0')
             AND not lab_result_cm.result_unit in ('mg/d', 'g/dL', 'mL/min/{1.73_m2}', 'mL/min') --Excluding rare weird units
             and lab_result_cm.result_num is not null
             and lab_result_cm.result_num >= 0
     and result_num<30000
    --AND lab_result_cm.result_num < 1000

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
            WHERE lab_result_cm.result_date BETWEEN TO_DATE('09/30/2020', 'MM/DD/YYYY') AND TO_DATE('09/30/2021', 'MM/DD/YYYY')
              AND lab_result_cm.lab_loinc in ('13457-7', '18262-6', '2089-1')
              --and lab_result_cm.patid in pat_list
              and lab_result_cm.result_num is not null
              and lab_result_cm.result_num >= 0
     and result_num<10000
    -- AND not lab_result_cm.result_unit in ('mg/d','g/dL','mL/min/{1.73_m2}') --Excluding rare weird units
    --AND lab_result_cm.result_num < 1000

),
LDL as (select *
        from LDL_all
        where row_num = 1
),
max_LDL as (select patid,
                   case
                       when (max(LDL_result_num) over (partition by patid)) >= 190 then 1
                       else 0 end as max_ldl_above_190
            from LDL_all
),
total_chol_all as (select lab_result_cm.patid,
                          row_number() OVER (
                              PARTITION BY lab_result_cm.patid
                              ORDER BY lab_result_cm.result_date ASC
                              )                     row_num,
                          lab_result_cm.result_num  total_chol_result_num,
                          lab_result_cm.result_unit result_unit,
                          lab_result_cm.result_date result_date

                   FROM cdm_60_etl.lab_result_cm
                   WHERE lab_result_cm.result_date BETWEEN TO_DATE('09/30/2020', 'MM/DD/YYYY') AND TO_DATE('09/30/2021', 'MM/DD/YYYY')
                     AND lab_result_cm.lab_loinc in ('2093-3')

    -- and lab_result_cm.result_num is not null
    -- and lab_result_cm.result_num >= 0
      AND not lab_result_cm.result_unit in ('mg/d', 'g/dL', 'mL/min/{1.73_m2}', 'mL/min') --Excluding rare weird units
      and result_num<30000

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
            WHERE lab_result_cm.result_date BETWEEN TO_DATE('09/01/2020', 'MM/DD/YYYY') AND TO_DATE('09/30/2021', 'MM/DD/YYYY')
              AND lab_result_cm.lab_loinc in ('2085-9')
              --  and lab_result_cm.result_num is not null
              and lab_result_cm.result_num >= 0
                  and result_num < 1000

      AND not lab_result_cm.result_unit in ('mg/d', 'g/dL', 'mL/min/{1.73_m2}', 'mL/min') --Excluding rare weird units
   

),
HDL as (select *
        from HDL_all
        where row_num = 1),

/*

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
*/

NHDL as (select total_chol.patid,
                total_chol.TOTAL_CHOL_RESULT_NUM - HDL.HDL_RESULT_NUM as NHDL,
                total_chol.TOTAL_CHOL_RESULT_NUM                         CHOL_RESULT_NUM,
                HDL.HDL_RESULT_NUM                                    as HDL_RESULT_NUM,
                total_chol.RESULT_date                                as TC_date,
                HDL.RESULT_date                                       as hdl_date
         from total_chol
                  inner join HDL
                             on total_chol.patid = HDL.patid),
     lab_list as(


select PATID,
       LDL.LDL_RESULT_NUM,
       NHDL,
       TG.TG_RESULT_NUM,
       CHOL_RESULT_NUM,
       HDL_RESULT_NUM,
       TG.RESULT_DATE            as TG_date,
       LDL.RESULT_DATE           as LDL_date,
       HDL_DATE                  as nHDL_date,
       TG.RESULT_DATE - HDL_DATE as nHDL_gap,
       max_ldl_above_190


from LDL
         left join NHDL USING (PATID)
         left join TG USING (PATID)
         left join max_LDL using (patid)),
     pat_list as (select patid, LDL_date from lab_list),

--This code adds columnns needed for exclusions including age and  first_encounter date



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
     diabetes as (select patid,

                     --    max(LDL_Date - admit_date)over (partition by patid) / 365.25  as time_since_first_diabetes_diagnosis,
                         1                                   as Diabetes
                  FROM pat_list pats
                           INNER JOIN cdm_60_etl.diagnosis como using (patid)
                  where Como.dx like 'E08%' -- diabetes

                     OR Como.dx like 'E09%' -- diabetes

                     OR Como.dx like 'E10%' -- diabetes

                     OR Como.dx like 'E11%' -- diabetes

                     OR Como.dx like 'E13%' -- diabetes

                     OR Como.dx like '249%' -- diabetes

                     OR Como.dx like '250%' -- diabetes
         group by patid
     ),

     ASCVD as (select patid,

                      max(LDL_Date - admit_date) / 365.25 as tx_since_first_ascvd,
                      1                                   as ASCVD
               FROM pat_list pats
                        INNER JOIN cdm_60_etl.diagnosis como using (patid)
               WHERE dx in ('413.9',
                            'I20.9',
                            'I23.7',
                            'I25.111',
                            'I25.118',
                            'I25.119',
                            'I25.701',
                            'I25.708',
                            'I25.709',
                            'I25.738',
                            'I25.751',
                            'I25.791',
                            '411.1',
                            '411.81',
                            '411.89',
                            '413.0',
                            '413.1',
                            'I20.0',
                            'I20.1',
                            'I20.8',
                            'I24.0',
                            'I24.8',
                            'I24.9',
                            'I25.110',
                            'I25.700',
                            'I25.710',
                            'I25.720',
                            'I25.730',
                            'I25.750',
                            'I25.760',
                            'I25.790',
                            '414.8',
                            '414.9',
                            'I25.5',
                            'I25.6',
                            'I25.89',
                            'I25.9',
                            '410.11',
                            '410.2',
                            '410.3',
                            '410.4',
                            '410.50',
                            '410.51',
                            '410.60',
                            '410.61',
                            '410.62',
                            '410.70',
                            '410.71',
                            '410.72',
                            '410.81',
                            '410.90',
                            '410.91',
                            '410.92',
                            '411.0',
                            '412',
                            'I21.01',
                            'I21.02',
                            'I21.09',
                            'I21.11',
                            'I21.19',
                            'I21.21',
                            'I21.29',
                            'I21.3',
                            'I21.4',
                            'I21.9',
                            'I21.A1',
                            'I21.A9',
                            'I22.0',
                            'I22.1',
                            'I22.2',
                            'I22.8',
                            'I22.9',
                            'I23.0',
                            'I23.3',
                            'I23.6',
                            'I23.8',
                            'I24.1',
                            'I25.2',
                            '440.20',
                            '440.21',
                            '440.22',
                            '440.23',
                            '440.24',
                            '440.29',
                            '440.30',
                            '440.31',
                            '440.32',
                            '440.4',
                            'I70.0',
                            'I70.1',
                            'I70.201',
                            'I70.202',
                            'I70.203',
                            'I70.208',
                            'I70.209',
                            'I70.21',
                            'I70.22',
                            'I70.232',
                            'I70.24',
                            'I70.25',
                            'I70.26',
                            'I70.261',
                            'I70.262',
                            'I70.263',
                            'I70.268',
                            'I70.269',
                            'I70.291',
                            'I70.292',
                            'I70.293',
                            'I70.298',
                            'I70.299',
                            'I70.3',
                            'I70.4',
                            'I70.5',
                            'I70.8',
                            'I70.90',
                            'I70.91',
                            'I70.92',
                            '346.62',
                            '346.63',
                            '433.01',
                            '433.11',
                            '433.21',
                            '433.31',
                            '433.81',
                            '433.91',
                            '434.01',
                            '434.11',
                            '434.91',
                            'V12.54',
                            'G43.601',
                            'G43.609',
                            'G43.611',
                            'G43.619',
                            'I63.00',
                            'I63.011',
                            'I63.012',
                            'I63.019',
                            'I63.02',
                            'I63.031',
                            'I63.032',
                            'I63.09',
                            'I63.10',
                            'I63.112',
                            'I63.12',
                            'I63.19',
                            'I63.311',
                            'I63.312',
                            'I63.319',
                            'I63.321',
                            'I63.323',
                            'I63.333',
                            'I63.343',
                            'I63.412',
                            'I63.413',
                            'I63.429',
                            'I63.431',
                            'I63.511',
                            'I63.519',
                            'I63.531',
                            'I63.539',
                            'I63.59'
                            )
               group by patid
     ),
     joined as
         (
             select *
             from lab_list labs
                      left join first_encounter e using (patid)
                      left join last_encounter e using (patid)
                      left join age_gender_race_ethnicity dem using (patid)
                      LEFT JOIN ASCVD USING (PATID)
                      LEFT JOIN diabetes USING (PATID)
         )
--sql server age: floor(datediff(day, demographic.birth_date, '2020-08-31') / 365.25) as age

select distinct joined.*,
       round(LDL_date - first_admit_date)         as pre_index_days,
       round(last_admit_date - LDL_DATE)          as post_index_days,
       round((LDL_DATE - birth_date) / 365.25, 2) as age
from joined
Where round((LDL_DATE - birth_date) / 365.25, 2)>18 --over 18
And  round(LDL_date - first_admit_date)  >180 --at least 6 months pre-index. 
;


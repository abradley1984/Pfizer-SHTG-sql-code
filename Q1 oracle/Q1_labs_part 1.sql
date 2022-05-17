/*This code generates a table with all labs for the cohorts, mostly for T3
The Q2 version is pretty similar, but is run before cohorts are extracted, so there may be slight differences.
Run time: ~35 mins
 */


--select * From Q1_labs_all;
--
-- drop table Q1_labs_all;*/

create table Q1_labs_all_v2 as
with pat_list as
         (
             select TG_Date as index_date, shtg_Q1_cohorts_with_ex.*
             from shtg_Q1_cohorts_with_ex

             where cohort is not null
             -- fetch first 1000 rows only
         )
        ,
     --vldl
     vldl as (select patid,
                     row_number() OVER (
                         PARTITION BY patid
                         ORDER BY lab_result_cm.result_date asc
                         )                     row_num,
                     lab_result_cm.result_num  vldl,
                     lab_result_cm.result_unit result_unit,
                     lab_result_cm.result_date result_date


              FROM pat_list
                       left join CDM_60_ETL.lab_result_cm using (patid)
              WHERE lab_result_cm.result_date BETWEEN TO_DATE('09/30/2020', 'MM/DD/YYYY') AND TO_DATE('09/30/2021', 'MM/DD/YYYY')
                AND lab_result_cm.lab_loinc in ('46986-6', '13458-5', '2091-7')
                and lab_result_cm.result_num is not null
                and lab_result_cm.result_num > 0),


--apo_b

     apo_b as (select patid,
                      row_number() OVER (
                          PARTITION BY patid
                          ORDER BY lab_result_cm.result_date asc
                          )                     row_num,
                      lab_result_cm.result_num  apob,
                      lab_result_cm.result_unit result_unit,
                      lab_result_cm.result_date result_date


               FROM pat_list
                        left join CDM_60_ETL.lab_result_cm using (patid)
               WHERE lab_result_cm.result_date BETWEEN TO_DATE('09/30/2020', 'MM/DD/YYYY') AND TO_DATE('09/30/2021', 'MM/DD/YYYY')
                 AND lab_result_cm.lab_loinc in ('1884-6', '1871-3', '1881-2')
                 and lab_result_cm.result_num is not null
                 and lab_result_cm.result_num > 0),


     --  lpa - mol and mass handled separately

     lpa_mass as (select patid,
                         row_number() OVER (
                             PARTITION BY patid
                             ORDER BY lab_result_cm.result_date asc
                             )                     row_num,
                         lab_result_cm.result_num  lpa_mass,
                         lab_result_cm.result_unit result_unit,
                         lab_result_cm.result_date result_date


                  FROM pat_list
                           left join CDM_60_ETL.lab_result_cm using (patid)
                  WHERE lab_result_cm.result_date BETWEEN TO_DATE('09/30/2020', 'MM/DD/YYYY') AND TO_DATE('09/30/2021', 'MM/DD/YYYY')
                    AND (lab_result_cm.lab_loinc in
                         ('10835-7') and not result_unit = 'nmol/L')


                    and lab_result_cm.result_num is not null
                    and lab_result_cm.result_num > 0),

     lpa_mol as (select patid,
                        row_number() OVER (
                            PARTITION BY patid
                            ORDER BY lab_result_cm.result_date asc
                            )                     row_num,
                        lab_result_cm.result_num  lpa_mol,
                        lab_result_cm.result_unit result_unit,
                        lab_result_cm.result_date result_date


                 FROM pat_list
                          left join CDM_60_ETL.lab_result_cm using (patid)
                 WHERE lab_result_cm.result_date BETWEEN TO_DATE('09/30/2020', 'MM/DD/YYYY') AND TO_DATE('09/30/2021', 'MM/DD/YYYY')
                   AND (lab_result_cm.lab_loinc in
                        ('43583-4')
                     or (lab_result_cm.lab_loinc in
                         ('10835-7') and result_unit = 'nmol/L')
                            and lab_result_cm.result_num is not null and lab_result_cm.result_num > 0))
        ,


--apo_a1

     apo_a1 as (select patid,
                       row_number() OVER (
                           PARTITION BY patid
                           ORDER BY lab_result_cm.result_date asc
                           )                     row_num,
                       lab_result_cm.result_num  apo_a1,
                       lab_result_cm.result_unit result_unit,
                       lab_result_cm.result_date result_date


                FROM pat_list
                         left join CDM_60_ETL.lab_result_cm using (patid)
                WHERE lab_result_cm.result_date BETWEEN TO_DATE('09/30/2020', 'MM/DD/YYYY') AND TO_DATE('09/30/2021', 'MM/DD/YYYY')
                  AND lab_result_cm.lab_loinc in ('1869-7', '1874-7', '55724-9')
                  and lab_result_cm.result_num is not null
                  and lab_result_cm.result_num > 0),


--nlr
     nlr as (select patid,
                    row_number() OVER (
                        PARTITION BY patid
                        ORDER BY lab_result_cm.result_date asc
                        )                     row_num,
                    lab_result_cm.result_num  nlr,
                    lab_result_cm.result_unit result_unit,
                    lab_result_cm.result_date result_date


             FROM pat_list
                      left join CDM_60_ETL.lab_result_cm using (patid)
             WHERE lab_result_cm.result_date BETWEEN TO_DATE('09/30/2020', 'MM/DD/YYYY') AND TO_DATE('09/30/2021', 'MM/DD/YYYY')
               AND lab_result_cm.lab_loinc in
                   ('770-8', '23761-0', '26511-6')
               and lab_result_cm.result_num is not null
               and lab_result_cm.result_num > 0
               and (result_unit in ('OT', '%') or result_unit is null)),


--hscrp

     hscrp as (select patid,
                      row_number() OVER (
                          PARTITION BY patid
                          ORDER BY lab_result_cm.result_date asc
                          )                     row_num,
                      lab_result_cm.result_num  hscrp,
                      lab_result_cm.result_unit result_unit,
                      lab_result_cm.result_date result_date


               FROM pat_list
                        left join CDM_60_ETL.lab_result_cm using (patid)
               WHERE lab_result_cm.result_date BETWEEN TO_DATE('09/30/2020', 'MM/DD/YYYY') AND TO_DATE('09/30/2021', 'MM/DD/YYYY')
                 AND lab_result_cm.lab_loinc in ('30522-7', '35648-5')
                 and lab_result_cm.result_num is not null
                 and lab_result_cm.result_num > 0),

     diabetes as (select distinct (patid), 1 as Diabetes
                  FROM pat_list pats
                           JOIN CDM_60_ETL.diagnosis como using (patid)
                  WHERE (dx like 'E13%' or
                         dx like 'E11%' or
                         dx like 'E10%' or
                         dx like 'E09%' or
                         dx like 'E08%')),

--a1c


     a1c as (select patid,
                    row_number() OVER (
                        PARTITION BY patid
                        ORDER BY lab_result_cm.result_date asc
                        )                     row_num,
                    lab_result_cm.result_num  a1c,
                    lab_result_cm.result_unit result_unit,
                    lab_result_cm.result_date result_date


             FROM pat_list
                      left join CDM_60_ETL.lab_result_cm using (patid)
             WHERE lab_result_cm.result_date BETWEEN TO_DATE('09/30/2020', 'MM/DD/YYYY') AND TO_DATE('09/30/2021', 'MM/DD/YYYY')
               AND lab_result_cm.lab_loinc in ('17856-6', '41995-2', '4549-2', '4548-4')
               and lab_result_cm.result_num is not null
               and lab_result_cm.result_num > 0
               and patid in (select patid from diabetes)),--only giving A1c for diabetic patients

--albumin

     albumin as (select patid,
                        row_number() OVER (
                            PARTITION BY patid
                            ORDER BY lab_result_cm.result_date asc
                            )                     row_num,
                        lab_result_cm.result_num  albumin,
                        lab_result_cm.result_unit result_unit,
                        lab_result_cm.result_date result_date


                 FROM pat_list
                          left join CDM_60_ETL.lab_result_cm using (patid)
                 WHERE lab_result_cm.result_date BETWEEN TO_DATE('09/30/2020', 'MM/DD/YYYY') AND TO_DATE('09/30/2021', 'MM/DD/YYYY')
                   AND lab_result_cm.lab_loinc in ('1751-7', '61151-7', '2862-1', '61152-5')
                   and lab_result_cm.result_num is not null
                   and lab_result_cm.result_num > 0),

--alp

     alp as (select patid,
                    row_number() OVER (
                        PARTITION BY patid
                        ORDER BY lab_result_cm.result_date asc
                        )                     row_num,
                    lab_result_cm.result_num  alp,
                    lab_result_cm.result_unit result_unit,
                    lab_result_cm.result_date result_date


             FROM pat_list
                      left join CDM_60_ETL.lab_result_cm using (patid)
             WHERE lab_result_cm.result_date BETWEEN TO_DATE('09/30/2020', 'MM/DD/YYYY') AND TO_DATE('09/30/2021', 'MM/DD/YYYY')
               AND lab_result_cm.lab_loinc in
                   ('6768-6')
               and lab_result_cm.result_num is not null
               and lab_result_cm.result_num > 0),

--alt

     alt as (select patid,
                    row_number() OVER (
                        PARTITION BY patid
                        ORDER BY lab_result_cm.result_date asc
                        )                     row_num,
                    lab_result_cm.result_num  alt,
                    lab_result_cm.result_unit result_unit,
                    lab_result_cm.result_date result_date


             FROM pat_list
                      left join CDM_60_ETL.lab_result_cm using (patid)
             WHERE lab_result_cm.result_date BETWEEN TO_DATE('09/30/2020', 'MM/DD/YYYY') AND TO_DATE('09/30/2021', 'MM/DD/YYYY')
               AND lab_result_cm.lab_loinc in ('1742-6', '1743-4', '1744-2')
               and lab_result_cm.result_num is not null
               and lab_result_cm.result_num > 0),

--ast

     ast as (select patid,
                    row_number() OVER (
                        PARTITION BY patid
                        ORDER BY lab_result_cm.result_date asc
                        )                     row_num,
                    lab_result_cm.result_num  ast,
                    lab_result_cm.result_unit result_unit,
                    lab_result_cm.result_date result_date


             FROM pat_list
                      left join CDM_60_ETL.lab_result_cm using (patid)
             WHERE lab_result_cm.result_date BETWEEN TO_DATE('09/30/2020', 'MM/DD/YYYY') AND TO_DATE('09/30/2021', 'MM/DD/YYYY')
               AND lab_result_cm.lab_loinc in ('1920-8', '30239-8')
               and lab_result_cm.result_num is not null
               and lab_result_cm.result_num > 0),

--ggt

     ggt as (select patid,
                    row_number() OVER (
                        PARTITION BY patid
                        ORDER BY lab_result_cm.result_date asc
                        )                     row_num,
                    lab_result_cm.result_num  ggt,
                    lab_result_cm.result_unit result_unit,
                    lab_result_cm.result_date result_date


             FROM pat_list
                      left join CDM_60_ETL.lab_result_cm using (patid)
             WHERE lab_result_cm.result_date BETWEEN TO_DATE('09/30/2020', 'MM/DD/YYYY') AND TO_DATE('09/30/2021', 'MM/DD/YYYY')
               AND lab_result_cm.lab_loinc in ('2324-2')
               and lab_result_cm.result_num is not null
               and lab_result_cm.result_num > 0),


--platelets

     platelets as (select patid,
                          row_number() OVER (
                              PARTITION BY patid
                              ORDER BY lab_result_cm.result_date asc
                              )                     row_num,
                          lab_result_cm.result_num  platelets,
                          lab_result_cm.result_unit result_unit,
                          lab_result_cm.result_date result_date


                   FROM pat_list
                            left join CDM_60_ETL.lab_result_cm using (patid)
                   WHERE lab_result_cm.result_date BETWEEN TO_DATE('09/30/2020', 'MM/DD/YYYY') AND TO_DATE('09/30/2021', 'MM/DD/YYYY')
                     AND lab_result_cm.lab_loinc in ('777-3', '26515-7', '49497-1', '778-1')
                     and lab_result_cm.result_num is not null
                     and lab_result_cm.result_num > 0),

--TG

     tg as (select patid,
                   row_number() OVER (
                       PARTITION BY patid
                       ORDER BY lab_result_cm.result_date asc
                       )                     row_num,
                   lab_result_cm.result_num  tg_result_num,
                   lab_result_cm.result_unit result_unit,
                   lab_result_cm.result_date result_date


            FROM pat_list
                     left join CDM_60_ETL.lab_result_cm using (patid)
            WHERE lab_result_cm.result_date BETWEEN TO_DATE('09/30/2020', 'MM/DD/YYYY') AND TO_DATE('09/30/2021', 'MM/DD/YYYY')
              AND lab_result_cm.lab_loinc in ('2571-8')
              and lab_result_cm.result_num is not null
              and lab_result_cm.result_num > 0),

--uacr

     uacr as (select patid,
                     row_number() OVER (
                         PARTITION BY patid
                         ORDER BY lab_result_cm.result_date asc
                         )                     row_num,
                     lab_result_cm.result_num  uacr,
                     lab_result_cm.result_unit result_unit,
                     lab_result_cm.result_date result_date


              FROM pat_list
                       left join CDM_60_ETL.lab_result_cm using (patid)
              WHERE lab_result_cm.result_date BETWEEN TO_DATE('09/30/2020', 'MM/DD/YYYY') AND TO_DATE('09/30/2021', 'MM/DD/YYYY')
                AND lab_result_cm.lab_loinc in ('9318-7', '13705-9', '32294-1', '14585-4')
                and lab_result_cm.result_num is not null
                and lab_result_cm.result_num > 0),
     weight as (select patid,
                       row_number() OVER (
                           PARTITION BY patid
                           ORDER BY measure_date DESC
                           ) row_num,
                       wt    weight,

                       measure_date
                from CDM_60_ETL.vital
                WHERE measure_date BETWEEN TO_DATE('09/30/2020', 'MM/DD/YYYY') AND TO_DATE('09/30/2021', 'MM/DD/YYYY')
                  and wt is not null

                    and wt>10 and wt<1000
                  and patid in (select patid from pat_list)),
     height as (select patid,
                       row_number() OVER (
                           PARTITION BY patid
                           ORDER BY measure_date DESC
                           ) row_num,
                       ht    height,

                       measure_date
                from CDM_60_ETL.vital
                WHERE measure_date BETWEEN TO_DATE('09/30/2020', 'MM/DD/YYYY') AND TO_DATE('09/30/2021', 'MM/DD/YYYY')
                  and ht is not null

                  and ht>24 and ht<120
                  and patid in (select patid from pat_list)),

     creatinine as (select *
                    from (select patid,
                                 row_number() OVER (
                                     PARTITION BY patid
                                     ORDER BY lab_result_cm.result_date asc
                                     )                      row_num,
                                 lab_result_cm.result_num   creat_result_num,
                                 lab_result_cm.result_unit  result_unit,
                                 lab_result_cm.result_date  result_date,
                                 cohort,
                                 sex,
                                 age,
                                 trunc(result_num / 0.9, 2) creat_result_num_male,
                                 trunc(result_num / 0.7, 2) creat_result_num_female

                          FROM pat_list
                                   left join CDM_60_ETL.lab_result_cm using (patid)
                          WHERE lab_result_cm.result_date BETWEEN TO_DATE('09/30/2020', 'MM/DD/YYYY') AND TO_DATE('09/30/2021', 'MM/DD/YYYY')
                            AND lab_result_cm.lab_loinc in ('2160-0', '38483-4')
                            and lab_result_cm.result_num is not null
                            --AND RESULT_NUM < 500
                            AND RESULT_NUM > 0
                         )
                    where row_num = 1),


     --eGFR =142* min(standardized Scr/K, 1)α * max(standardized Scr/K, 1)-1.200 *.9938Age *.012 [if female]*/

     egfr as (select patid,

                     cohort,
                     creat_result_num,
                     result_unit,
                     age as egfrage,

                     case
                         when (SEX = 'M' and creat_result_num_male < 1) then 142 *
                                                                             (power(creat_result_num_male, -0.302))
                             *
                                                                             (power(0.9938, TRUNC(age)))
                         when sex = 'F' and creat_result_num_female < 1 then 142 * 1.012 *
                                                                             (power(creat_result_num_female, -0.241)) *
                                                                             (1) * power(0.9938, trunc(age))
                         when (sex = 'M' and creat_result_num_male >= 1) then 142 *
                                                                              (power(creat_result_num_male, -1.2)) *
                                                                              trunc(power(0.9938, trunc(age)), 2)
                         when sex = 'F' and creat_result_num_female >= 1 then 142 * 1.012 *
                                                                              (power(creat_result_num_female, -1.2)) *
                                                                              power(0.9938, trunc(age))
                         else NULL end
                         as egfr_2021
              from creatinine--_TEST2
              where row_num = 1
     ),


     all_labs2 as (select *
                   from (
                            select patid,

                                   pat_list.cohort,
                                   a1c,
                                   albumin,
                                   platelets,
                                   ast,
                                   age,
                                   alt.alt,
                                   ggt,
                                   alp,
                                   round((pat_list.AGE * ast) / (platelets * SQRT(alt.alt)), 2) AS FIB_4,
                                   trunc(703 * weight / (height * height), 2)                   as BMI,
                                   chol_result_num - LDL_RESULT_NUM - HDL_RESULT_NUM            as TRLC,
                                   weight,
                                   TG_RESULT_NUM                                                as TG,
                                   LDL_RESULT_NUM                                               as LDL,
                                   chol_result_num                                              as TC,
                                   HDL_RESULT_NUM                                               as HDL,
                                   NHDL,
                                   apob,
                                   vldl,
                                   uacr,
                                   hscrp,
                                   nlr,
                                   apo_a1,
                                   lpa_mol,
                                   lpa_mass,
                                   egfr_2021
                                    ,
                                   creat_result_num

                            from pat_list
                                     full outer join egfr using (patid)
                                     full outer join (select * From a1c where row_num = 1) using (patid)
                                     full outer join (select * From uacr where row_num = 1) using (patid)
                                     full outer join(select * From hscrp where row_num = 1) using (patid)
                                     full outer join (select * From vldl where row_num = 1) using (patid)
                                     full outer join (select * From platelets where row_num = 1) platelets using (patid)
                                     full outer join (select * From alp where row_num = 1) alp using (patid)
                                     full outer join (select * From ast where row_num = 1) ast using (patid)
                                     full outer join (select * From alt where row_num = 1) alt using (patid)
                                     full outer join (select * From ggt where row_num = 1) ggt using (patid)
                                     full outer join (select * From albumin where row_num = 1) albumin using (patid)
                                     full outer join (select * From height where row_num = 1) using (patid)
                                     full outer join (select * From weight where row_num = 1) using (patid)
                                     full outer join (select * From apo_b where row_num = 1) using (patid)
                                     full outer join (select * From nlr where row_num = 1) using (patid)
                                     full outer join (select * From apo_a1 where row_num = 1) using (patid)

                                     full outer join (select * From lpa_mass where row_num = 1) using (patid)
                                     full outer join (select * From lpa_mol where row_num = 1) using (patid)))

--writing labs table
select *
From all_labs2;
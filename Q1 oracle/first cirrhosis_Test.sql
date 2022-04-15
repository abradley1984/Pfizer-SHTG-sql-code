select count(*), count(distinct patid)
from cirrhosis_info_11apr_22__500_patients;

create table cirrhosis_info_11apr_22_500_patients
as
with NASH as (
    SELECT x.patid
    FROM (
             SELECT diagnosis.patid
             FROM cdm_60_etl.diagnosis
             WHERE        --diagnosis.admit_date BETWEEN TO_DATE('09/01/2017', 'MM/DD/YYYY') AND TO_DATE('08/31/2022', 'MM/DD/YYYY')
                 /* AND */diagnosis.dx = 'K75.81'
                          --   AND diagnosis.enc_type = 'AV'
             GROUP BY diagnosis.patid
             HAVING COUNT(*) > 1
             UNION
             SELECT diagnosis.patid
             FROM cdm_60_etl.diagnosis
             WHERE --diagnosis.admit_date BETWEEN TO_DATE('09/01/2017', 'MM/DD/YYYY') AND TO_DATE('08/31/2022', 'MM/DD/YYYY')
                 /* AND */diagnosis.dx = 'K75.81'
               AND diagnosis.enc_type <> 'AV'
         ) x
   ),
     cirrhosis as (select pats.patid, 1 as cirrhosis
                   from nash pats
                            inner join cdm_60_etl.diagnosis ON diagnosis.patid = pats.patid
                   WHERE diagnosis.dx like (
                       'K74.6%'

                       )
          fetch first 500 rows only
     ),
     pat_list as (select patid from cirrhosis),
     first_cirrhosis AS (
         SELECT pats.patid,
                MIN(diagnosis.admit_date) first_dx_date
         FROM cirrhosis pats
                  INNER JOIN cdm_60_etl.diagnosis ON diagnosis.patid = pats.patid
         WHERE diagnosis.dx like (
             'K74.6%'
             )
         GROUP BY pats.patid
     ),
     age_gender_race_ethnicity AS (
         SELECT pats.patid,

                demographic.birth_date as birth_date,
                demographic.sex,
                demographic.race,
                demographic.hispanic,
                first_dx_date
         FROM first_cirrhosis pats
                  INNER JOIN cdm_60_etl.demographic ON demographic.patid = pats.patid
     )
        ,
     platelets AS (
         SELECT lab_result_cm.patid,
                avg(result_num) as platelets,
                result_unit     as result_unit_platelets,
                specimen_date
         FROM cdm_60_etl.lab_result_cm
         WHERE --lab_result_cm.specimen_date BETWEEN TO_DATE('09/01/2017', 'MM/DD/YYYY') AND TO_DATE('08/31/2020', 'MM/DD/YYYY')
             /*  AND*/ lab_result_cm.lab_loinc in ('777-3', '26515-7')
           AND lab_result_cm.result_num > 0
           AND lab_result_cm.result_num is not NULL
           AND patid in (select patid from cirrhosis)
         group by patid, specimen_date, result_unit),
     --  AND not lab_result_cm.result_unit in ('10*3/mL','g/dL') --Excluding rare weird units

     ast AS (
         SELECT lab_result_cm.patid,
                result_num  as ast,
                result_unit as result_unit_ast,
                specimen_date
         FROM cdm_60_etl.lab_result_cm
         WHERE --lab_result_cm.specimen_date BETWEEN TO_DATE('09/01/2017', 'MM/DD/YYYY') AND TO_DATE('08/31/2020', 'MM/DD/YYYY')
             /*AND*/ lab_result_cm.lab_loinc in (
                                                 '1920-8',
                                                 '30239-8'
             )
           AND lab_result_cm.result_num > 0
           AND lab_result_cm.result_num is not NULL
           AND patid in (select patid from cirrhosis)),
     --  AND not lab_result_cm.result_unit in ('10*3/mL','g/dL') --Excluding rare weird units

     alt AS (
         SELECT patid,
                result_num  as alt,
                result_unit as result_unit_alt,
                specimen_date
         FROM cdm_60_etl.lab_result_cm
         WHERE --lab_result_cm.specimen_date BETWEEN TO_DATE('09/01/2017', 'MM/DD/YYYY') AND TO_DATE('08/31/2020', 'MM/DD/YYYY')
             /*AND*/ lab_result_cm.lab_loinc in (
                                                 '1742-6', '1743-4', '1744-2')
           AND lab_result_cm.result_num > 0
           AND lab_result_cm.result_num is not NULL
           AND patid in (select patid from cirrhosis))
     --  AND not lab_result_cm.result_unit in ('10*3/mL','g/dL') --Excluding rare weird units
        ,
     all_labs as
         (select *
          from (select pats.patid                                       as patid,
                       alt.specimen_date,
                       platelets.specimen_date                          as plt_Date,
                       ast,
                       alt,
                       platelets,
                       abs(platelets.specimen_date - ast.specimen_date) as platelet_gap,
                       row_number() OVER (
                           PARTITION BY ast.patid, ast.specimen_date
                           ORDER BY abs(platelets.specimen_date - ast.specimen_date) asc
                           )                                               row_num

                from cirrhosis pats
                         left join ast ast on pats.patid = ast.patid
                         join alt on (ast.specimen_date = alt.specimen_date and ast.patid = alt.patid)
                         join platelets
                              on (/*ast.specimen_date = platelets.specimen_date and*/ ast.patid = platelets.patid)
                where abs(platelets.specimen_date - ast.specimen_date) < 30
               )
          where row_num = 1),
     cirrhosis_info as (select patid,
                               specimen_date,
                               plt_Date,
                               ast,
                               alt,
                               platelets,
                               age_gender_race_ethnicity.birth_date                            as bdate,
                               first_cirrhosis.first_dx_date,
                               (specimen_date - age_gender_race_ethnicity.birth_date) / 365.25 as age_at_test
                        From all_labs
                                 left join age_gender_race_ethnicity using (patid)
                                 left join first_cirrhosis using (patid))

select cirrhosis_info.*,
       round((age_at_test * ast) / (platelets * SQRT(alt)),
             2) AS FIB_4
from cirrhosis_info;
/*  select * from all_labs
 fetch first 100 rows only;*/
/*


select count(patid), count(distinct patid), 'cirrhosis'
from cirrhosis
union
select count(patid), count(distinct patid), 'alt'
from alt
union
select count(patid), count(distinct patid), 'ast'
from ast
union
select count(patid), count(distinct patid), 'platelets'
from platelets
union
select count(patid), count(distinct patid), 'all_labs'
from all_labs;


select *
from age_gender_race_ethnicity
         left join ast using (patid)
         left join alt using (patid)
         left join platelets using (patid)
*/


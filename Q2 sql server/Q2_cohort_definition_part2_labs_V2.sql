
/* This code extracts lab values for patients, some of which are needed for cohort definitions for Q2, others will be used to create Table 3.

Run time: ~36 mins


--select * from foo.dbo.Q2_labs_all;
--
-- drop table foo.dbo.Q2_labs_all;*/
/*This code generates a table that's written to disk (Q1_labs_all) with all labs for the cohorts, mostly for T3

  The Q2 version is pretty similar, but is run before cohorts are extracted, so there may be slight differences.

Run time: ~40 mins

  edits for sql server - CTE changed to #local tables
  trunc to round
  date format
 */


--select * From Q1_labs_all;
--
-- drop table Q1_labs_all;*/


select *
into #pat_list
from (
         select LDL_Date as index_date, foo.dbo.SHTG_Q2_STEP1.*
         from foo.dbo.SHTG_Q2_STEP1

        -- where cohort is not null
         -- fetch first 1000 rows only
     ) as "ids";

--vldl
select *
into #vldl
from (select a.patid,
             row_number() OVER (
                 PARTITION BY a.patid
                 ORDER BY result_date asc
                 )                     row_num,
             result_num  vldl,
             result_unit result_unit,
             result_date result_date


      FROM #pat_list a
               left join cdm.dbo.lab_result_cm b on a.patid = b.patid
      WHERE result_date BETWEEN '2020-09-30' AND '2021-09-30'

        AND lab_loinc in ('46986-6', '13458-5', '2091-7')
        and result_num is not null) as ab;


--apo_b

select *
into #apo_b
from (select a.patid,
             row_number() OVER (
                 PARTITION BY a.patid
                 ORDER BY result_date asc
                 )                     row_num,
             result_num  apob,
             result_unit result_unit,
             result_date result_date


      from #pat_list a
               left join cdm.dbo.lab_result_cm b on a.patid = b.patid
      WHERE result_date BETWEEN '2020-09-30' AND '2021-09-30'

        AND lab_loinc in ('1884-6', '1871-3', '1881-2')
        and result_num is not null) as ab;


--  lpa - mol and mass handled separately

select *
into #lpa_mass
from (select a.patid,
             row_number() OVER (
                 PARTITION BY a.patid
                 ORDER BY result_date asc
                 )                     row_num,
             result_num  lpa_mass,
             result_unit result_unit,
             result_date result_date


      from #pat_list a
               left join cdm.dbo.lab_result_cm b on a.patid = b.patid
      WHERE result_date BETWEEN '2020-09-30' AND '2021-09-30'

        AND (lab_loinc in
             ('10835-7') and not result_unit = 'nmol/L')


        and result_num is not null) as ab;

select *
into #lpa_mol
from (select a.patid,
             row_number() OVER (
                 PARTITION BY a.patid
                 ORDER BY result_date asc
                 )                     row_num,
             result_num  lpa_mol,
             result_unit result_unit,
             result_date result_date


      from #pat_list a
               left join cdm.dbo.lab_result_cm b on a.patid = b.patid
      WHERE result_date BETWEEN '2020-09-30' AND '2021-09-30'

        AND (lab_loinc in
             ('43583-4')
          or (lab_loinc in
              ('10835-7') and result_unit = 'nmol/L')
                 and result_num is not null)) as ab;


--apo_a1

select *
into #apo_a1
from (select a.patid,
             row_number() OVER (
                 PARTITION BY a.patid
                 ORDER BY result_date asc
                 )                     row_num,
             result_num  apo_a1,
             result_unit result_unit,
             result_date result_date


      from #pat_list a
               left join cdm.dbo.lab_result_cm b on a.patid = b.patid
      WHERE result_date BETWEEN '2020-09-30' AND '2021-09-30'

        AND lab_loinc in ('1869-7', '1874-7', '55724-9')
        and result_num is not null) as ab;


--nlr
select *
into #nlr
from (select a.patid,
             row_number() OVER (
                 PARTITION BY a.patid
                 ORDER BY result_date asc
                 )                     row_num,
             result_num  nlr,
             result_unit result_unit,
             result_date result_date


      from #pat_list a
               left join cdm.dbo.lab_result_cm b on a.patid = b.patid
      WHERE result_date BETWEEN '2020-09-30' AND '2021-09-30'

        AND lab_loinc in
            ('770-8', '23761-0', '26511-6')
        and result_num is not null
        and (result_unit in ('OT', '%') or result_unit is null)) as ab;


--hscrp

select *
into #hscrp
from (select a.patid,
             row_number() OVER (
                 PARTITION BY a.patid
                 ORDER BY result_date asc
                 )                     row_num,
             result_num  hscrp,
             result_unit result_unit,
             result_date result_date


      from #pat_list a
               left join cdm.dbo.lab_result_cm b on a.patid = b.patid
      WHERE result_date BETWEEN '2020-09-30' AND '2021-09-30'

        AND lab_loinc in ('30522-7', '35648-5')
        and result_num is not null) as ab;

select *
into #diabetes
from (select distinct (pats.patid), 1 as Diabetes
      from #pat_list  pats
                           JOIN cdm.dbo.diagnosis como on pats.patid = como.patid
      WHERE (dx like 'E13%'
         or
          dx like 'E11%'
         or
          dx like 'E10%'
         or
          dx like 'E09%'
         or
          dx like 'E08%')) as pD;

--a1c


select *
into #a1c
from (select a.patid,
             row_number() OVER (
                 PARTITION BY a.patid
                 ORDER BY result_date asc
                 )                     row_num,
             result_num  a1c,
             result_unit result_unit,
             result_date result_date


      from #pat_list a
               left join cdm.dbo.lab_result_cm b on a.patid = b.patid
      WHERE result_date BETWEEN '2020-09-30' AND '2021-09-30'

        AND lab_loinc in ('17856-6', '41995-2', '4549-2', '4548-4')
        and result_num is not null
        and a.patid in (select patid from #diabetes)) as ab;
--only giving A1c for diabetic patients

--albumin

select *
into #albumin
from (select a.patid,
             row_number() OVER (
                 PARTITION BY a.patid
                 ORDER BY result_date asc
                 )                     row_num,
             result_num  albumin,
             result_unit result_unit,
             result_date result_date


      from #pat_list a
               left join cdm.dbo.lab_result_cm b on a.patid = b.patid
      WHERE result_date BETWEEN '2020-09-30' AND '2021-09-30'

        AND lab_loinc in ('1751-7', '61151-7', '2862-1', '61152-5')
        and result_num is not null) as ab;

--alp

select *
into #alp
from (select a.patid,
             row_number() OVER (
                 PARTITION BY a.patid
                 ORDER BY result_date asc
                 )                     row_num,
             result_num  alp,
             result_unit result_unit,
             result_date result_date


      from #pat_list a
               left join cdm.dbo.lab_result_cm b on a.patid = b.patid
      WHERE result_date BETWEEN '2020-09-30' AND '2021-09-30'

        AND lab_loinc in
            ('6768-6')
        and result_num is not null) as ab;

--alt

select *
into #alt
from (select a.patid,
             row_number() OVER (
                 PARTITION BY a.patid
                 ORDER BY result_date asc
                 )                     row_num,
             result_num  alt,
             result_unit result_unit,
             result_date result_date


      from #pat_list a
               left join cdm.dbo.lab_result_cm b on a.patid = b.patid
      WHERE result_date BETWEEN '2020-09-30' AND '2021-09-30'

        AND lab_loinc in ('1742-6', '1743-4', '1744-2')
        and result_num is not null
        and result_num > 0) as ab;

--ast

select *
into #ast
from (select a.patid,
             row_number() OVER (
                 PARTITION BY a.patid
                 ORDER BY result_date asc
                 )                     row_num,
             result_num  ast,
             result_unit result_unit,
             result_date result_date


      from #pat_list a
               left join cdm.dbo.lab_result_cm b on a.patid = b.patid
      WHERE result_date BETWEEN '2020-09-30' AND '2021-09-30'

        AND lab_loinc in ('1920-8', '30239-8')
        and result_num is not null) as ab;

--ggt

select *
into #ggt
from (select a.patid,
             row_number() OVER (
                 PARTITION BY a.patid
                 ORDER BY result_date asc
                 )                     row_num,
             result_num  ggt,
             result_unit result_unit,
             result_date result_date


      from #pat_list a
               left join cdm.dbo.lab_result_cm b on a.patid = b.patid
      WHERE result_date BETWEEN '2020-09-30' AND '2021-09-30'

        AND lab_loinc in ('2324-2')
        and result_num is not null) as ab;


--platelets

select *
into #platelets
from (select a.patid,
             row_number() OVER (
                 PARTITION BY a.patid
                 ORDER BY result_date asc
                 )                     row_num,
             result_num  platelets,
             result_unit result_unit,
             result_date result_date


      from #pat_list a
               left join cdm.dbo.lab_result_cm b on a.patid = b.patid
      WHERE result_date BETWEEN '2020-09-30' AND '2021-09-30'

        AND lab_loinc in ('777-3', '26515-7', '49497-1', '778-1')
        and result_num is not null
        and result_num > 0) as ab;

--TG

select *
into #tg
from (select a.patid,
             row_number() OVER (
                 PARTITION BY a.patid
                 ORDER BY result_date asc
                 )                     row_num,
             result_num  tg_result_num,
             result_unit result_unit,
             result_date result_date


      from #pat_list a
               left join cdm.dbo.lab_result_cm b on a.patid = b.patid
      WHERE result_date BETWEEN '2020-09-30' AND '2021-09-30'

        AND lab_loinc in ('2571-8')
        and result_num is not null) as ab;

--uacr

select *
into #uacr
from (select a.patid,
             row_number() OVER (
                 PARTITION BY a.patid
                 ORDER BY result_date asc
                 )                     row_num,
             result_num  uacr,
             result_unit result_unit,
             result_date result_date


      from #pat_list a
               left join cdm.dbo.lab_result_cm  b on a.patid = b.patid
      WHERE result_date BETWEEN '2020-09-30' AND '2021-09-30'

        AND lab_loinc in ('9318-7', '13705-9', '32294-1', '14585-4')
        and result_num is not null) as ab;
select *
into #weight
from (select patid,
             row_number() OVER (
                 PARTITION BY patid
                 ORDER BY measure_date DESC
                 ) row_num,
             wt    weight,

             measure_date
      from cdm.dbo.vital
      WHERE measure_date BETWEEN '2020-09-30' AND '2021-09-30'
        and wt is not null
         and wt>10 and wt<1000
        and vital.patid in (select patid from #pat_list)) as v;
select *
into #height
from (select patid,
             row_number() OVER (
                 PARTITION BY patid
                 ORDER BY measure_date DESC
                 ) row_num,
             ht    height,

             measure_date
      from cdm.dbo.vital
      WHERE measure_date BETWEEN '2020-09-30' AND '2021-09-30'
        and ht is not null
         and ht>24 and ht<120
        and vital.patid in (select patid from #pat_list)) as v;

select *
into #creatinine
from (select *
      from (select a.patid,
                   row_number() OVER (
                       PARTITION BY a.patid
                       ORDER BY result_date asc
                       )                      row_num,
                   result_num   creat_result_num,
                   result_unit  result_unit,
                   result_date  result_date,
                   --cohort,
                   sex,
                   age,
                   round(result_num / 0.9, 2) creat_result_num_male,
                   round(result_num / 0.7, 2) creat_result_num_female

            from #pat_list a
                     left join cdm.dbo.lab_result_cm b on a.patid = b.patid
            WHERE result_date BETWEEN '2020-09-30' AND '2021-09-30'

              AND lab_loinc in ('2160-0', '38483-4')
              and result_num is not null
              AND RESULT_NUM < 500
              AND RESULT_NUM > 0
           ) as "p*"
      where row_num = 1) as "p**";


--eGFR =142* min(standardized Scr/K, 1)α * max(standardized Scr/K, 1)-1.200 *.9938Age *.012 [if female]*/

select *
into #egfr
from (select patid,

             --cohort,
             creat_result_num,
             result_unit,
             age as egfrage,

             case
                 when (SEX = 'M' and creat_result_num_male < 1) then 142 *
                                                                     (power(creat_result_num_male, -0.302))
                     *
                                                                     (power(0.9938, age))
                 when sex = 'F' and creat_result_num_female < 1 then 142 * 1.012 *
                                                                     (power(creat_result_num_female, -0.241)) *
                                                                     (1) * power(0.9938, age)
                 when (sex = 'M' and creat_result_num_male >= 1) then 142 *
                                                                      (power(creat_result_num_male, -1.2)) *
                                                                      round(power(0.9938, age), 2)
                 when sex = 'F' and creat_result_num_female >= 1 then 142 * 1.012 *
                                                                      (power(creat_result_num_female, -1.2)) *
                                                                      power(0.9938,age)
                 else NULL end
                 as egfr_2021
      from #creatinine--_TEST2
      where row_num = 1
     ) as c;


select *
into #all_labs2
from (
         select a.patid,

                --a.cohort,
                a1c,
                albumin,
                platelets,
                ast,
                age,
                alt.alt,
                ggt,
                alp,
                round((a.AGE * ast) / (platelets * SQRT(alt)), 2) AS FIB_4,
                round(703 * weight / (height * height), 2)        as BMI,
                chol_result_num - LDL_RESULT_NUM - HDL_RESULT_NUM as TRLC,
                weight,
                TG_RESULT_NUM                                     as TG,
                LDL_RESULT_NUM                                    as LDL,
                chol_result_num                                   as TC,
                HDL_RESULT_NUM                                    as HDL,
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

         from #pat_list a
                  full outer join #egfr b on a.patid = b.patid
                  full outer join (select * From #a1c where row_num = 1) c on a.patid = c.patid
                  full outer join (select * From #uacr where row_num = 1) d on a.patid = d.patid
                  full outer join(select * From #hscrp where row_num = 1) e on a.patid = e.patid
                  full outer join (select * From #vldl where row_num = 1) f on a.patid = f.patid
                  full outer join (select * From #platelets where row_num = 1) platelets on a.patid = platelets.patid
                  full outer join (select * From #alp where row_num = 1) alp on a.patid = alp.patid
                  full outer join (select * From #ast where row_num = 1) ast on a.patid = ast.patid
                  full outer join (select * From #alt where row_num = 1) alt on a.patid = alt.patid
                  full outer join (select * From #ggt where row_num = 1) ggt on a.patid = ggt.patid
                  full outer join (select * From #albumin where row_num = 1) albumin on a.patid = albumin.patid
                  full outer join (select * From #height where row_num = 1) ma on a.patid = ma.patid
                  full outer join (select * From #weight where row_num = 1) na on a.patid = na.patid
                  full outer join (select * From #apo_b where row_num = 1) o on a.patid = o.patid
                  full outer join (select * From #nlr where row_num = 1) p on a.patid = p.patid
                  full outer join (select * From #apo_a1 where row_num = 1) q on a.patid = q.patid

                  full outer join (select * From #lpa_mass where row_num = 1) r on a.patid = r.patid
                  full outer join (select * From #lpa_mol where row_num = 1) s on a.patid = s.patid) as abcdefpaaagamnopqrs ;

--writing labs table
--create table Q1_labs_all as
select *
into foo.dbo.Q2_labs_all_v2
From #all_labs2;
select * from foo.dbo.Q2_labs_all_v2;
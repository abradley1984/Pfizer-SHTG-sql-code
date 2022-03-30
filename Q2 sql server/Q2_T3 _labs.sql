/*This query has two parts - table 3a and table 3b that should be written to csv files.

  This code is the same for Q1 and Q2, with small changes to pat_list, and index date
Running time: 8 mins *2

  Issues to check for sql server version are marked with --CHECK comments

*/
--I'm not sure if this works, but maybe if we specify this here we can take out the cdm_60_etl. references below?
USE CDM;

--CDM name should be changed here for your site
--ALTER USER "username" WITH DEFAULT_SCHEMA = PCORI_CDM_SCHEMA;
GO

select *
into #pat_list
from (
         select LDL_date as index_date, SHTG_Q2_STEP3.*
         from SHTG_Q2_STEP3

         where cohort is not null
         -- fetch first 1000 rows only
     ) a;
select *
into #all_labs
from (select * from Q2_labs_all) a;-- generated in Q1_labs_part1

select *
into #HDL_all
from (select distinct patid,

                      --  result_num  total_chol_result_num,
                      -- result_unit result_unit,
                      --CHECK THIS - I want just the date, not the time
                      cast(b.result_date as date) result_date


      FROM #pat_list a
               left join cdm_60_etl.lab_result_cm b on a.patid = b.patid
      WHERE b.result_date BETWEEN '2019-04-01' AND '2021-09-30'
        AND b.lab_loinc in ('2085-9')
        and b.result_num is not null

        -- and result_num >= 0
        AND not b.result_unit in
                ('mg/d', 'g/dL', 'mL/min/{1.73_m2}', 'mL/min') --Excluding rare weird units
         --AND result_num < 1000

     ) c;

select *
into #total_chol_all
from (select distinct patid,
                      cohort,

                      --  result_num  total_chol_result_num,
                      -- result_unit result_unit,
                      --CHECK THIS - I want just the date, not the time
                      cast(b.result_date as date) result_date,
                      index_date


      from #pat_list a
               left join cdm_60_etl.lab_result_cm b on a.patid = b.patid

      WHERE result_date BETWEEN '2019-04-01' AND '2021-09-30'
        AND lab_loinc in ('2093-3')
        and result_num is not null

        -- and result_num >= 0
        AND not result_unit in
                ('mg/d', 'g/dL', 'mL/min/{1.73_m2}', 'mL/min') --Excluding rare weird units
         --AND result_num < 1000

     ) c;
select *
into #lipid_panel_date
from (select a.patid, a.result_date
      from #HDL_all a
               inner join #total_chol_all b on a.patid = b.patid and a.result_date = b.result_date) c;


select *
into #lipid_panel_next_closest
from (
         select c.patid,
                c.cohort,
                c.result_date,
                c.index_date,
                time_from_index,
                row_num,
                IIF(abs(time_from_index) < 90, 1, 0)  as less_than_90_days,
                IIF(abs(time_from_index) < 456, 1, 0) as less_than_15_months
         from (select a.patid,
                      a.cohort,
                      a.result_date,
                      a.index_date,
                      datediff(dd, a.result_date, a.index_date) as time_from_index,
                      row_number() OVER (
                          PARTITION BY a.patid
                          ORDER BY datediff(dd, a.result_date, a.index_date) ASC
                          )                                    row_num
               from #lipid_panel_date a
              ) c
         where row_num in (2)) d;
select *
into #nhdl_after_index
from (
         select c.patid,
                c.cohort,
                c.result_date,
                c.index_date,
                time_from_index,
                row_num,
                IIF(time_from_index between 1 and 60, 1, 0)  as within_60_days,
                IIF(time_from_index between 1 and 180, 1, 0) as within_180_days
         from (select a.patid,
                      a.cohort,
                       a.result_date,
                       a.index_date,
                      datediff(dd,  a.result_date,  a.index_date) as time_from_index,
                      row_number() OVER (
                          PARTITION BY  a.patid
                          ORDER BY abs(datediff(dd,  a.result_date,  a.index_date)) ASC
                          )                                    row_num
               from #lipid_panel_date a
              ) c
         where row_num > 1
           and time_from_index > 0) d;

select *
into #next_nhdl
from (select patid,
             cohort,
             max(within_60_days)     nhdl_within_60_days,
             max(within_180_days)    nhdl_within_180_days,
             min(result_date),
             min(time_from_index) as nhdl_time_from_index,
             index_date
      from #nhdl_after_index
      group by patid, cohort, index_date) c;
select *
into #last_TG_above_500
from (select *
      from (select patid,
                   result_num                                    TG_result_num,
                   result_unit                                   result_unit,
                   result_date,
                   index_date,
                   abs(datediff(dd, result_date, index_date)) as TG_time_from_index,
                   row_number() OVER (
                       PARTITION BY patid
                       ORDER BY abs(datediff(dd, result_date, index_date)) ASC
                       )                                         row_num

            from #pat_list a
                     left join cdm_60_etl.lab_result_cm b on a.patid = b.patid
            WHERE                                                         --result_date '2021-07-31' AND '2021-09-30'
                lab_loinc in ('2571-8', '12951-0')
              AND not result_unit in ('mg/d', 'g/dL', 'mL/min/{1.73_m2}') --Excluding rare weird units
              and result_num is not null
              and result_num >= 500
              and (datediff(dd, result_date, index_date)) <= (-1)--TG occurs before index_date
           ) c
           --and patid in (select patid from #pat_list)
           --AND result_num < 1000
      where row_num = 1
     ) d;
select *
into #diabetic_control
from (
         select count(patid) OVER (PARTITION BY cohort) as              count_patients,
--
                count(a1c) OVER (PARTITION BY cohort)   as              count_non_null,
                --median(a1c)                                             median,
                round(avg(a1c) OVER (PARTITION BY cohort), 2)           mean,
                round(stdev(a1c) OVER (PARTITION BY cohort), 2)         std,
                PERCENTILE_CONT(0.25) WITHIN
                    GROUP (ORDER BY a1c asc) OVER (PARTITION BY cohort) "pct_25",
                PERCENTILE_CONT(0.75) WITHIN
                    GROUP (ORDER BY a1c asc) OVER (PARTITION BY cohort) "pct_75",
                PERCENTILE_CONT(0.5) WITHIN
                    GROUP (ORDER BY a1c asc) OVER (PARTITION BY cohort) "Median",

                'A1C'                                                   measure1,
                cohort
         from #all_labs) as al;

select *
into #table3a
from (select *
      from #diabetic_control
      union
      select count(a.patid) OVER (PARTITION BY a.cohort)              as                count_patients,
--
             count(nhdl_time_from_index) OVER (PARTITION BY a.cohort) as                count_non_null,
             --median(a1c)                                             median,
             round(avg(nhdl_time_from_index) OVER (PARTITION BY a.cohort), 2)           mean,
             round(stdev(nhdl_time_from_index) OVER (PARTITION BY a.cohort), 2)         std,
             round(PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY nhdl_time_from_index asc) OVER (PARTITION BY a.cohort),
                   2)                                                                   "pct_25",
             round(PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY nhdl_time_from_index asc) OVER (PARTITION BY a.cohort),
                   2)                                                                   "pct_75",
             PERCENTILE_CONT(0.5) WITHIN
                 GROUP (ORDER BY nhdl_time_from_index asc) OVER (PARTITION BY a.cohort) "Median",
             'time to next nHDL (days)',
             a.cohort

      from #pat_list a
               left join #next_nhdl b on a.patid = b.patid

      union
      select count(a.patid) OVER (PARTITION BY a.cohort)            as                count_patients,
--
             count(TG_time_from_index) OVER (PARTITION BY a.cohort) as                count_non_null,

             round(avg(TG_time_from_index) OVER (PARTITION BY a.cohort), 2)           mean,
             round(stdev(TG_time_from_index) OVER (PARTITION BY a.cohort), 2)         std,

             round(PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY TG_time_from_index asc) OVER (PARTITION BY a.cohort),
                   2)                                                                 "pct_25",
             round(PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY TG_time_from_index asc) OVER (PARTITION BY a.cohort),
                   2)                                                                 "pct_75",
             PERCENTILE_CONT(0.5) WITHIN
                 GROUP (ORDER BY TG_time_from_index asc) OVER (PARTITION BY a.cohort) "Median",
             'time to last TG  (days)',
             cohort

      from #pat_list a
               left join #last_TG_above_500 b on a.patid = b.patid
           --group by cohort
      union

      select count(patid) OVER (PARTITION BY cohort) as              count_patients,
--
             count(ggt) OVER (PARTITION BY cohort)   as              count_non_null,

             round(avg(ggt) OVER (PARTITION BY cohort), 2)           mean,
             round(stdev(ggt) OVER (PARTITION BY cohort), 2)         std,
             PERCENTILE_CONT(0.25) WITHIN
                 GROUP (ORDER BY ggt asc) OVER (PARTITION BY cohort) "pct_25",
             PERCENTILE_CONT(0.75) WITHIN
                 GROUP (ORDER BY ggt asc) OVER (PARTITION BY cohort) "pct_75",
             PERCENTILE_CONT(0.5) WITHIN
                 GROUP (ORDER BY ggt asc) OVER (PARTITION BY cohort) "Median",
             'ggt'                                   as              measure1,
             cohort
      from #all_labs
           --group by cohort
      union
      select count(patid) OVER (PARTITION BY cohort)   as                                                   count_patients,
             count(albumin) OVER (PARTITION BY cohort) as                                                   count_non_null
              ,
             -- round(median(albumin), 2)                                           median,
             round(avg(albumin) OVER (PARTITION BY cohort), 2)                                              mean,
             round(stdev(albumin) OVER (PARTITION BY cohort), 2)                                            std,
             round(PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY albumin asc) OVER (PARTITION BY cohort), 2) "pct_25",
             round(PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY albumin asc) OVER (PARTITION BY cohort), 2) "pct_75",

             PERCENTILE_CONT(0.5) WITHIN
                 GROUP (ORDER BY albumin asc) OVER (PARTITION BY cohort)                                    "Median",
             'albumin',
             cohort
      from #all_labs
           --group by cohort
      union
      select count(patid) OVER (PARTITION BY cohort) as              count_patients,
             count(ast) OVER (PARTITION BY cohort)   as              count_non_null
              ,
             -- round(median(albumin), 2)                                           median,
             round(avg(ast) OVER (PARTITION BY cohort), 2)           mean,
             round(stdev(ast) OVER (PARTITION BY cohort), 2)         std,

             PERCENTILE_CONT(0.25) WITHIN
                 GROUP (ORDER BY ast asc) OVER (PARTITION BY cohort) "pct_25",
             PERCENTILE_CONT(0.75) WITHIN
                 GROUP (ORDER BY ast asc) OVER (PARTITION BY cohort) "pct_75",
             'ast',
             PERCENTILE_CONT(0.5) WITHIN
                 GROUP (ORDER BY ast asc) OVER (PARTITION BY cohort) "Median",
             cohort
      from #all_labs
           --group by cohort
      union

      select count(patid) OVER (PARTITION BY cohort) as              count_patients,
             count(alt) OVER (PARTITION BY cohort)   as              count_non_null
              ,
             -- round(median(albumin), 2)                                           median,
             round(avg(alt) OVER (PARTITION BY cohort), 2)           mean,
             round(stdev(alt) OVER (PARTITION BY cohort), 2)         std,

             PERCENTILE_CONT(0.25) WITHIN
                 GROUP (ORDER BY alt asc) OVER (PARTITION BY cohort) "pct_25",
             PERCENTILE_CONT(0.75) WITHIN
                 GROUP (ORDER BY alt asc) OVER (PARTITION BY cohort) "pct_75",
             PERCENTILE_CONT(0.5) WITHIN
                 GROUP (ORDER BY alt asc) OVER (PARTITION BY cohort) "Median",
             'alt',
             cohort
      from #all_labs
           --group by cohort
      union
      select count(patid) OVER (PARTITION BY cohort)                 count_patients,
             count(alp) OVER (PARTITION BY cohort) as                count_non_null,
             -- median(alp)                                    median,
             round(avg(alp) OVER (PARTITION BY cohort), 2)           mean,
             round(stdev(alp) OVER (PARTITION BY cohort), 2)         std,
             PERCENTILE_CONT(0.25) WITHIN
                 GROUP (ORDER BY alp asc) OVER (PARTITION BY cohort) "pct_25",
             PERCENTILE_CONT(0.75) WITHIN
                 GROUP (ORDER BY alp asc) OVER (PARTITION BY cohort) "pct_75",
             PERCENTILE_CONT(0.5) WITHIN
                 GROUP (ORDER BY alp asc) OVER (PARTITION BY cohort) "Median",
             'alp',
             cohort
      from #all_labs
           --group by cohort
      union
      select count(patid)                                                  count_patients,
             count(FIB_4) OVER (PARTITION BY cohort) as                    count_non_null,
             -- median(FIB_4)                                    median,
             round(avg(FIB_4) OVER (PARTITION BY cohort), 2)               mean,
             round(stdev(FIB_4), 2) OVER (PARTITION BY cohort)             std,
             round(PERCENTILE_CONT(0.25) WITHIN
                 GROUP (ORDER BY FIB_4 asc) OVER (PARTITION BY cohort), 2) "pct_25",
             round(PERCENTILE_CONT(0.75) WITHIN
                 GROUP (ORDER BY FIB_4 asc) OVER (PARTITION BY cohort), 2) "pct_75",
             round(PERCENTILE_CONT(0.5) WITHIN
                 GROUP (ORDER BY FIB_4 asc) OVER (PARTITION BY cohort), 2) "Median",
             'FIB_4',
             cohort
      from #all_labs
           --group by cohort
      union
      select count(patid) OVER (PARTITION BY cohort)                     count_patients,
             count(BMI) OVER (PARTITION BY cohort) as                    count_non_null,
             -- median(BMI)                                    median,
             round(avg(BMI) OVER (PARTITION BY cohort), 2)               mean,
             round(stdev(BMI), 2) OVER (PARTITION BY cohort)             std,
             round(PERCENTILE_CONT(0.25) WITHIN
                 GROUP (ORDER BY BMI asc) OVER (PARTITION BY cohort), 2) "pct_25",
             round(PERCENTILE_CONT(0.75) WITHIN
                 GROUP (ORDER BY BMI asc) OVER (PARTITION BY cohort), 2) "pct_75",
             round(PERCENTILE_CONT(0.5) WITHIN
                 GROUP (ORDER BY BMI asc) OVER (PARTITION BY cohort), 2) "Median",
             'BMI',
             cohort
      from #all_labs
           ----group by cohort
      union
      select count(patid) OVER (PARTITION BY cohort)                        count_patients,
             count(weight) OVER (PARTITION BY cohort) as                    count_non_null,
             --   median(weight)                                    median,
             round(avg(weight) OVER (PARTITION BY cohort), 2)               mean,
             round(stdev(weight) OVER (PARTITION BY cohort), 2)             std,
             PERCENTILE_CONT(0.25) WITHIN
                 GROUP (ORDER BY weight asc) OVER (PARTITION BY cohort)     "pct_25",
             PERCENTILE_CONT(0.75) WITHIN
                 GROUP (ORDER BY weight asc) OVER (PARTITION BY cohort)     "pct_75",
             round(PERCENTILE_CONT(0.5) WITHIN
                 GROUP (ORDER BY weight asc) OVER (PARTITION BY cohort), 2) "Median",
             'weight',
             cohort
      from #all_labs
           ----group by cohort
      union
      select count(patid) OVER (PARTITION BY cohort)                      count_patients,
             count(apob) OVER (PARTITION BY cohort) as                    count_non_null,
             --median(apob)                                    median,
             round(avg(apob) OVER (PARTITION BY cohort), 2)               mean,
             round(stdev(apob) OVER (PARTITION BY cohort), 2)             std,
             PERCENTILE_CONT(0.25) WITHIN
                 GROUP (ORDER BY apob asc) OVER (PARTITION BY cohort)     "pct_25",
             PERCENTILE_CONT(0.75) WITHIN
                 GROUP (ORDER BY apob asc) OVER (PARTITION BY cohort)     "pct_75",
             round(PERCENTILE_CONT(0.5) WITHIN
                 GROUP (ORDER BY apob asc) OVER (PARTITION BY cohort), 2) "Median",
             'apob',
             cohort
      from #all_labs
           --group by cohort
      union
      select count(patid) OVER (PARTITION BY cohort)                    count_patients,
             count(TG) OVER (PARTITION BY cohort) as                    count_non_null,
             -- median(TG)                                    median,
             round(avg(TG) OVER (PARTITION BY cohort), 2)               mean,
             round(stdev(TG) OVER (PARTITION BY cohort), 2)             std,
             PERCENTILE_CONT(0.25) WITHIN
                 GROUP (ORDER BY TG asc) OVER (PARTITION BY cohort)     "pct_25",
             PERCENTILE_CONT(0.75) WITHIN
                 GROUP (ORDER BY TG asc) OVER (PARTITION BY cohort)     "pct_75",
             round(PERCENTILE_CONT(0.5) WITHIN
                 GROUP (ORDER BY TG asc) OVER (PARTITION BY cohort), 2) "Median",
             'TG',
             cohort
      from #all_labs
           --group by cohort
      union
      select count(patid) OVER (PARTITION BY cohort)                     count_patients,
             count(LDL) OVER (PARTITION BY cohort) as                    count_non_null,
             --median(LDL)                                    median,
             round(avg(LDL) OVER (PARTITION BY cohort), 2)               mean,
             round(stdev(LDL) OVER (PARTITION BY cohort), 2)             std,
             PERCENTILE_CONT(0.25) WITHIN
                 GROUP (ORDER BY LDL asc) OVER (PARTITION BY cohort)     "pct_25",
             PERCENTILE_CONT(0.75) WITHIN
                 GROUP (ORDER BY LDL asc) OVER (PARTITION BY cohort)     "pct_75",
             round(PERCENTILE_CONT(0.5) WITHIN
                 GROUP (ORDER BY LDL asc) OVER (PARTITION BY cohort), 2) "Median",
             'LDL',
             cohort
      from #all_labs
           --group by cohort
      union
      select count(patid) OVER (PARTITION BY cohort)                     count_patients,
             count(HDL) OVER (PARTITION BY cohort) as                    count_non_null,
             -- median(HDL)                                                 median,
             round(avg(HDL) OVER (PARTITION BY cohort), 2)               mean,
             round(stdev(HDL) OVER (PARTITION BY cohort), 2)             std,
             PERCENTILE_CONT(0.25) WITHIN
                 GROUP (ORDER BY HDL asc) OVER (PARTITION BY cohort)     "pct_25",
             PERCENTILE_CONT(0.75) WITHIN
                 GROUP (ORDER BY HDL asc) OVER (PARTITION BY cohort)     "pct_75",
             round(PERCENTILE_CONT(0.5) WITHIN
                 GROUP (ORDER BY HDL asc) OVER (PARTITION BY cohort), 2) "Median",
             'HDL',
             cohort
      from #all_labs
           --group by cohort
      union
      select count(patid) OVER (PARTITION BY cohort)                      count_patients,
             count(nhdl) OVER (PARTITION BY cohort) as                    count_non_null,
             -- median(nhdl)                                                 median,
             round(avg(nhdl) OVER (PARTITION BY cohort), 2)               mean,
             round(stdev(nhdl) OVER (PARTITION BY cohort), 2)             std,
             PERCENTILE_CONT(0.25) WITHIN
                 GROUP (ORDER BY nhdl asc) OVER (PARTITION BY cohort)     "pct_25",
             PERCENTILE_CONT(0.75) WITHIN
                 GROUP (ORDER BY nhdl asc) OVER (PARTITION BY cohort)     "pct_75",
             round(PERCENTILE_CONT(0.5) WITHIN
                 GROUP (ORDER BY nhdl asc) OVER (PARTITION BY cohort), 2) "Median",
             'nhdl',
             cohort
      from #all_labs
      union
      select count(patid) OVER (PARTITION BY cohort)                  count_patients,
             count(vldl) OVER (PARTITION BY cohort) as                count_non_null,
             --median(vldl)                                    median,
             round(avg(vldl) OVER (PARTITION BY cohort), 2)           mean,
             round(stdev(vldl) OVER (PARTITION BY cohort), 2)         std,
             PERCENTILE_CONT(0.25) WITHIN
                 GROUP (ORDER BY vldl asc) OVER (PARTITION BY cohort) "pct_25",
             PERCENTILE_CONT(0.75) WITHIN
                 GROUP (ORDER BY vldl asc) OVER (PARTITION BY cohort) "pct_75",
             PERCENTILE_CONT(0.5) WITHIN
                 GROUP (ORDER BY vldl asc) OVER (PARTITION BY cohort) "Median",
             'vldl',
             cohort
      from #all_labs
           ----group by cohort
      union
      select count(patid)                                             count_patients,
             count(apob) OVER (PARTITION BY cohort) as                count_non_null,
             -- median(apob)                                    median,
             round(avg(apob) OVER (PARTITION BY cohort), 2)           mean,
             round(stdev(apob) OVER (PARTITION BY cohort), 2)         std,
             PERCENTILE_CONT(0.25) WITHIN
                 GROUP (ORDER BY apob asc) OVER (PARTITION BY cohort) "pct_25",
             PERCENTILE_CONT(0.75) WITHIN
                 GROUP (ORDER BY apob asc) OVER (PARTITION BY cohort) "pct_75",
             PERCENTILE_CONT(0.5) WITHIN
                 GROUP (ORDER BY apob asc) OVER (PARTITION BY cohort) "Median",
             'apob',
             cohort
      from #all_labs
           --group by cohort
      union
      select count(patid) OVER (PARTITION BY cohort)                 count_patients,
             count(nlr) OVER (PARTITION BY cohort) as                count_non_null,
             -- median(nlr)                                    median,
             round(avg(nlr) OVER (PARTITION BY cohort), 2)           mean,
             round(stdev(nlr) OVER (PARTITION BY cohort), 2)         std,
             PERCENTILE_CONT(0.25) WITHIN
                 GROUP (ORDER BY nlr asc) OVER (PARTITION BY cohort) "pct_25",
             PERCENTILE_CONT(0.75) WITHIN
                 GROUP (ORDER BY nlr asc) OVER (PARTITION BY cohort) "pct_75",
             PERCENTILE_CONT(0.5) WITHIN
                 GROUP (ORDER BY nlr asc) OVER (PARTITION BY cohort) "Median",
             'nlr',
             cohort
      from #all_labs
           --group by cohort
      union
      select count(patid) OVER (PARTITION BY cohort)                   count_patients,
             count(hscrp) OVER (PARTITION BY cohort) as                count_non_null,
             --  median(hscrp)                                    median,
             round(avg(hscrp) OVER (PARTITION BY cohort), 2)           mean,
             round(stdev(hscrp) OVER (PARTITION BY cohort), 2)         std,
             PERCENTILE_CONT(0.25) WITHIN
                 GROUP (ORDER BY hscrp asc) OVER (PARTITION BY cohort) "pct_25",
             PERCENTILE_CONT(0.75) WITHIN
                 GROUP (ORDER BY hscrp asc) OVER (PARTITION BY cohort) "pct_75",
             PERCENTILE_CONT(0.5) WITHIN
                 GROUP (ORDER BY hscrp asc) OVER (PARTITION BY cohort) "Median",
             'hscrp',
             cohort
      from #all_labs
           --group by cohort
      union
      select count(patid) OVER (PARTITION BY cohort)                    count_patients,
             count(apo_a1) OVER (PARTITION BY cohort) as                count_non_null,
             --   median(apo_a1)                                    median,
             round(avg(apo_a1) OVER (PARTITION BY cohort), 2)           mean,
             round(stdev(apo_a1) OVER (PARTITION BY cohort), 2)         std,
             PERCENTILE_CONT(0.25) WITHIN
                 GROUP (ORDER BY apo_a1 asc) OVER (PARTITION BY cohort) "pct_25",
             PERCENTILE_CONT(0.75) WITHIN
                 GROUP (ORDER BY apo_a1 asc) OVER (PARTITION BY cohort) "pct_75",
             PERCENTILE_CONT(0.5) WITHIN
                 GROUP (ORDER BY apo_a1 asc) OVER (PARTITION BY cohort) "Median",
             'apo_a1',
             cohort
      from #all_labs
           --group by cohort
      union
      select count(patid) OVER (PARTITION BY cohort)                     count_patients,
             count(lpa_mol) OVER (PARTITION BY cohort) as                count_non_null,
             --  median(lpa_mol)                                    median,
             round(avg(lpa_mol) OVER (PARTITION BY cohort), 2)           mean,
             round(stdev(lpa_mol) OVER (PARTITION BY cohort), 2)         std,
             PERCENTILE_CONT(0.25) WITHIN
                 GROUP (ORDER BY lpa_mol asc) OVER (PARTITION BY cohort) "pct_25",
             PERCENTILE_CONT(0.75) WITHIN
                 GROUP (ORDER BY lpa_mol asc) OVER (PARTITION BY cohort) "pct_75",
             PERCENTILE_CONT(0.5) WITHIN
                 GROUP (ORDER BY lpa_mol asc) OVER (PARTITION BY cohort) "Median",
             'lpa mol',
             cohort
      from #all_labs
           --group by cohort
      union
      select count(patid) OVER (PARTITION BY cohort)                      count_patients,
             count(lpa_mass) OVER (PARTITION BY cohort) as                count_non_null,
             --median(lpa_mass)                                    median,
             round(avg(lpa_mass) OVER (PARTITION BY cohort), 2)           mean,
             round(stdev(lpa_mass) OVER (PARTITION BY cohort), 2)         std,
             PERCENTILE_CONT(0.25) WITHIN
                 GROUP (ORDER BY lpa_mass asc) OVER (PARTITION BY cohort) "pct_25",
             PERCENTILE_CONT(0.75) WITHIN
                 GROUP (ORDER BY lpa_mass asc) OVER (PARTITION BY cohort) "pct_75",
             PERCENTILE_CONT(0.5) WITHIN
                 GROUP (ORDER BY lpa_mass asc) OVER (PARTITION BY cohort) "Median",
             'lpa mass',
             cohort
      from #all_labs
           --group by cohort
      union
      select count(patid) OVER (PARTITION BY cohort)                  count_patients,
             count(TRLC) OVER (PARTITION BY cohort) as                count_non_null,
             -- median(TRLC)                                    median,
             round(avg(TRLC) OVER (PARTITION BY cohort), 2)           mean,
             round(stdev(TRLC) OVER (PARTITION BY cohort), 2)         std,
             PERCENTILE_CONT(0.25) WITHIN
                 GROUP (ORDER BY TRLC asc) OVER (PARTITION BY cohort) "pct_25",
             PERCENTILE_CONT(0.75) WITHIN
                 GROUP (ORDER BY TRLC asc) OVER (PARTITION BY cohort) "pct_75",
             PERCENTILE_CONT(0.5) WITHIN
                 GROUP (ORDER BY TRLC asc) OVER (PARTITION BY cohort) "Median",
             'TRLC',
             cohort
      from #all_labs
           --group by cohort
      union
      select count(patid) OVER (PARTITION BY cohort)                           count_patients,
             count(egfr_2021) OVER (PARTITION BY cohort) as                    count_non_null,
             --round(median(egfr_2021), 2)                          median,
             round(avg(egfr_2021) OVER (PARTITION BY cohort), 2)               mean,
             round(stdev(egfr_2021) OVER (PARTITION BY cohort), 2)             std,
             round(PERCENTILE_CONT(0.25) WITHIN
                 GROUP (ORDER BY egfr_2021 asc) OVER (PARTITION BY cohort), 2) "pct_25",
             round(PERCENTILE_CONT(0.75) WITHIN
                 GROUP (ORDER BY egfr_2021 asc) OVER (PARTITION BY cohort), 2) "pct_75",
             round(PERCENTILE_CONT(0.5) WITHIN
                 GROUP (ORDER BY egfr_2021 asc) OVER (PARTITION BY cohort), 2) "Median",
             'egfr_2021',
             cohort
      from #all_labs) as "dc*ab"
--group by cohort) d;

--CHECK
select *
into #table3b
from (select count(patid),
             COUNT(CASE WHEN lpa_mol >= 125 THEN 1 END)                                 count1,
             'N_lpa_over_125_nmol'   as                                                 count_label,
             round(100 * COUNT(CASE WHEN lpa_mass >= 125 THEN 1 END) / count(patid), 2) pct1,
             'pct_lpa_over_125_nmol' as                                                 pct_label,
             'lpa_mol'                                                                  measure1,
             cohort
      from #all_labs
      group by cohort
      union
      select count(patid),
             COUNT(CASE WHEN lpa_mass >= 50 THEN 1 END)                                count1,
             'N_lpa_over_50mg'   as                                                    count_label,
             round(100 * COUNT(CASE WHEN lpa_mass >= 50 THEN 1 END) / count(patid), 2) pct1,
             'pct_lpa_over_50mg' as                                                    pct_label,
             'lpa_mass'                                                                measure1,
             cohort
      from #all_labs
      group by cohort
      union
      select count(patid),
             COUNT(CASE WHEN a1c >= 7 THEN 1 END)                                count1,
             'N_a1c_over_7'   as                                                 count_label,
             round(100 * COUNT(CASE WHEN a1c >= 7 THEN 1 END) / count(patid), 2) pct1,
             'pct_a1c_over_7' as                                                 pct_label,
             'A1C'                                                               measure1,
             cohort
      from #all_labs
      group by cohort
      union
      select count(patid),
             COUNT(CASE WHEN a1c >= 8 THEN 1 END)                                as count2,
             'N_a1c_over_8',

             round(100 * COUNT(CASE WHEN a1c >= 8 THEN 1 END) / count(patid), 2) as pct2
              ,
             'pct_a1c_over_8',
             'A1C'                                                                  measure1,
             cohort
      from #all_labs
      group by cohort
      union
      select count(patid),


             COUNT(CASE WHEN (FIB_4 >= 1.30 and AGE < 65) THEN 1 END),
             'N_fib4_over_1_30_age_under_65',

             round(100 * COUNT(CASE WHEN FIB_4 >= 1.30 THEN 1 END) / count(patid), 2) pct_fib4_over_1_30,
             'pct_fib4_over_1_30_under_65',
             'FIB4'                                                                   measure1,
             cohort
      from #all_labs
      group by cohort
      union
      select count(patid),
             COUNT(CASE WHEN (FIB_4 >= 2.0 and AGE >= 65) THEN 1 END),
             'N_fib4_over_2_age_over_65',
             round(100 * COUNT(CASE WHEN (FIB_4 >= 2.0 and AGE >= 65) THEN 1 END) / count(patid),
                   2) pct_fib4_over_2,
             'pct_fib4_over_age_over_65',
             'FIB4'   measure1,
             cohort
      from #all_labs
      group by cohort
      union
      select count(patid),
             COUNT(CASE WHEN FIB_4 >= 2.67 THEN 1 END),
             'N_fib4_over_2_67',

             round(100 * COUNT(CASE WHEN FIB_4 >= 2.67 THEN 1 END) / count(patid), 2) as pct_fib4_over_2_67
              ,
             'pct_fib4_over_2_67',
             'FIB4'                                                                      measure1,
             cohort
      from #all_labs
      group by cohort
      union
      select count(patid),
             COUNT(CASE WHEN BMI < 20 THEN 1 END)                                count1,
             'N BMI under 20',
             round(100 * COUNT(CASE WHEN BMI < 20 THEN 1 END) / count(patid), 2) pct1,
             'pct BMI under 20',
             'BMI'                                                               measure1,
             cohort
      from #all_labs
      group by cohort
      union
      select count(patid),
             COUNT(CASE WHEN BMI >= 40 THEN 1 END),
             'N BMI over 40',

             round(100 * COUNT(CASE WHEN BMI >= 40 THEN 1 END) / count(patid), 2) as pct2
              ,
             'pct BMI over 40',
             'BMI'                                                                   measure1,
             cohort
      from #all_labs
      group by cohort
      union
      select count(patid),
             COUNT(CASE WHEN BMI between 20 and 25 THEN 1 END),
             'N BMI 20 to 25',
             round(100 * COUNT(CASE WHEN BMI between 20 and 25 THEN 1 END) / count(patid), 2) pct3,
             'pct BMI 20 to 25',
             'BMI'                                                                            measure1,
             cohort
      from #all_labs
      group by cohort
      union
      select count(patid),
             COUNT(CASE WHEN BMI between 35 and 40 THEN 1 END),
             'N BMI 35 to 40',

             round(100 * COUNT(CASE WHEN BMI between 35 and 40 THEN 1 END) / count(patid), 2) as pct4
              ,
             'pct BMI 35 to 40',
             'BMI'                                                                               measure1,
             cohort
      from #all_labs
      group by cohort
      union
      select count(patid),
             COUNT(CASE WHEN BMI between 25 and 30 THEN 1 END),
             'N BMI 25 to 30',
             round(100 * COUNT(CASE WHEN BMI between 25 and 30 THEN 1 END) / count(patid), 2) pct5,
             'pct BMI 25 to 30',
             'BMI'                                                                            measure1,
             cohort
      from #all_labs
      group by cohort
      union
      select count(patid),
             COUNT(CASE WHEN BMI between 30 and 35 THEN 1 END)                                   count1,
             'N BMI 30 to 35',

             round(100 * COUNT(CASE WHEN BMI between 30 and 35 THEN 1 END) / count(patid), 2) as pct6
              ,
             'pct BMI 30 to 35',
             'BMI'                                                                               measure1,
             cohort
      from #all_labs
      group by cohort
      union
      select count(patid),
             COUNT(CASE when egfr_2021 > 90 THEN 1 END)                                count1,
             'N eGFR over 90',
             round(100 * COUNT(CASE when egfr_2021 > 90 THEN 1 END) / count(patid), 2) pct1,
             'pct eGFR over 90',
             'eGFR'                                                                    measure1,
             cohort
      from #all_labs
      group by cohort
      union
      select count(patid),
             COUNT(CASE when egfr_2021 < 15 THEN 1 END),
             'N eGFR under 15',

             round(100 * COUNT(CASE when egfr_2021 < 15 THEN 1 END) / count(patid), 2) as pct2
              ,
             'pct eGFR under 15',
             'eGFR'                                                                       measure1,
             cohort
      from #all_labs
      group by cohort
      union
      select count(patid),
             COUNT(CASE when egfr_2021 between 60 and 90 THEN 1 END),
             'N eGFR 60 to 90',
             round(100 * COUNT(CASE when egfr_2021 between 60 and 90 THEN 1 END) / count(patid), 2) pct3,
             'pct eGFR 60 to 90',
             'eGFR'                                                                                 measure1,
             cohort
      from #all_labs
      group by cohort

      union
      select count(patid),
             COUNT(CASE when egfr_2021 between 45 and 60 THEN 1 END),
             'N eGFR 45 to 60',
             round(100 * COUNT(CASE when egfr_2021 between 45 and 60 THEN 1 END) / count(patid), 2) pct5,
             'pct eGFR 45 to 60',
             'eGFR'                                                                                 measure1,
             cohort
      from #all_labs
      group by cohort
      union
      select count(patid),
             COUNT(CASE when egfr_2021 between 30 and 45 THEN 1 END)                                   count1,
             'N eGFR 30 to 45',

             round(100 * COUNT(CASE when egfr_2021 between 30 and 45 THEN 1 END) / count(patid), 2) as pct6
              ,
             'pct eGFR 30 to 45',
             'eGFR'                                                                                    measure1,
             cohort
      from #all_labs
      group by cohort
      union
      select count(patid),
             COUNT(CASE when egfr_2021 between 15 and 30 THEN 1 END),
             'N eGFR 15 to 30',

             round(100 * COUNT(CASE when egfr_2021 between 15 and 30 THEN 1 END) / count(patid), 2) as pct4
              ,
             'pct eGFR 15 to 30',
             'eGFR'                                                                                    measure1,
             cohort
      from #all_labs
      group by cohort
      union
      select count(patid),
             COUNT(CASE when LDL > 160 THEN 1 END)                                count1,
             'N LDL over 160',
             round(100 * COUNT(CASE when LDL > 160 THEN 1 END) / count(patid), 2) pct1,
             'pct LDL over 160',
             'LDL'                                                                measure1,
             cohort
      from #all_labs
      group by cohort
      union
      select count(patid),
             COUNT(CASE when LDL < 70 THEN 1 END),
             'N LDL under 70',

             round(100 * COUNT(CASE when LDL < 70 THEN 1 END) / count(patid), 2) as pct2
              ,
             'pct LDL under 70',
             'LDL'                                                                  measure1,
             cohort
      from #all_labs
      group by cohort
      union
      select count(patid),
             COUNT(CASE when LDL between 130 and 160 THEN 1 END),
             'N LDL 130 to 160',
             round(100 * COUNT(CASE when LDL between 130 and 160 THEN 1 END) / count(patid), 2) pct3,
             'pct LDL 130 to 160',
             'LDL'                                                                              measure1,
             cohort
      from #all_labs
      group by cohort

      union
      select count(patid),
             COUNT(CASE when LDL between 100 and 130 THEN 1 END),
             'N LDL 100 to 130',
             round(100 * COUNT(CASE when LDL between 100 and 130 THEN 1 END) / count(patid), 2) pct5,
             'pct LDL 100 to 130',
             'LDL'                                                                              measure1,
             cohort
      from #all_labs
      group by cohort
      union
      select count(patid),
             COUNT(CASE when LDL between 70 and 100 THEN 1 END)                                   count1,
             'N LDL 70 to 100',

             round(100 * COUNT(CASE when LDL between 70 and 100 THEN 1 END) / count(patid), 2) as pct6
              ,
             'pct LDL 70 to 100',
             'LDL'                                                                                measure1,
             cohort
      from #all_labs
      group by cohort
      union
      select count(patid),
             COUNT(CASE when TG > 2000 THEN 1 END)                                count1,
             'N TG over 2000',
             round(100 * COUNT(CASE when TG > 2000 THEN 1 END) / count(patid), 2) pct1,
             'pct TG over 2000',
             'TG'                                                                 measure1,
             cohort
      from #all_labs
      group by cohort
      union
      select count(patid),
             COUNT(CASE when TG < 500 THEN 1 END),
             'N TG under 500',

             round(100 * COUNT(CASE when TG < 500 THEN 1 END) / count(patid), 2) as pct2
              ,
             'pct TG under 500',
             'TG'                                                                   measure1,
             cohort
      from #all_labs
      group by cohort
      union
      select count(patid),
             COUNT(CASE when TG between 1000 and 2000 THEN 1 END),
             'N TG 1000 to 2000',
             round(100 * COUNT(CASE when TG between 1000 and 2000 THEN 1 END) / count(patid), 2) pct3,
             'pct TG 1000 to 2000',
             'TG'                                                                                measure1,
             cohort
      from #all_labs
      group by cohort

      union
      select count(patid),
             COUNT(CASE when TG between 880 and 1000 THEN 1 END),
             'N TG 880 to 1000',
             round(100 * COUNT(CASE when TG between 880 and 1000 THEN 1 END) / count(patid), 2) pct5,
             'pct TG 880 to 1000',
             'TG'                                                                               measure1,
             cohort
      from #all_labs
      group by cohort
      union
      select count(patid),
             COUNT(CASE when TG between 500 and 880 THEN 1 END)                                   count1,
             'N TG 500 to 880 ',

             round(100 * COUNT(CASE when TG between 500 and 880 THEN 1 END) / count(patid), 2) as pct6
              ,
             'pct TG 500 to 880 ',
             'TG'                                                                                 measure1,
             cohort
      from #all_labs
      group by cohort
      union
      select count(patid),
             COUNT(CASE when TG between 150 and 500 THEN 1 END)                                   count1,
             'N TG 150 to 500',

             round(100 * COUNT(CASE when TG between 150 and 500 THEN 1 END) / count(patid), 2) as pct6
              ,
             'pct TG 150 to 500',
             'TG'                                                                                 measure1,
             cohort
      from #all_labs
      group by cohort
      union
      select count(patid),
             COUNT(CASE when nHDL > 190 THEN 1 END)                                count1,
             'N nHDL over 190',
             round(100 * COUNT(CASE when nHDL > 190 THEN 1 END) / count(patid), 2) pct1,
             'pct nHDL over 190',
             'nHDL'                                                                measure1,
             cohort
      from #all_labs

      group by cohort
      union
      select count(patid),
             COUNT(CASE when nHDL between 160 and 190 THEN 1 END),
             'N nHDL 160 to 190',
             round(100 * COUNT(CASE when nHDL between 160 and 190 THEN 1 END) / count(patid), 2) pct3,
             'pct nHDL 160 to 190',
             'nHDL'                                                                              measure1,
             cohort
      from #all_labs
      group by cohort

      union
      select count(patid),
             COUNT(CASE when nHDL between 130 and 160 THEN 1 END),
             'N nHDL 130 to 160',
             round(100 * COUNT(CASE when nHDL between 130 and 160 THEN 1 END) / count(patid), 2) pct5,
             'pct nHDL 130 to 160',
             'nHDL'                                                                              measure1,
             cohort
      from #all_labs
      group by cohort
      union
      select count(patid),
             COUNT(CASE when nHDL between 100 and 130 THEN 1 END)                                   count1,
             'N nHDL 100 to 130',

             round(100 * COUNT(CASE when nHDL between 100 and 130 THEN 1 END) / count(patid), 2) as pct6
              ,
             'pct nHDL 100 to 130',
             'nHDL'                                                                                 measure1,
             cohort
      from #all_labs
      group by cohort
      union
      select count(patid),
             COUNT(CASE when apob > 130 THEN 1 END)                                count1,
             'N apob over 130',
             round(100 * COUNT(CASE when apob > 130 THEN 1 END) / count(patid), 2) pct1,
             'pct apob over 130',
             'apob'                                                                measure1,
             cohort
      from #all_labs
      group by cohort
      union
      select count(patid),
             COUNT(CASE when vldl > 30 THEN 1 END)                                count1,
             'N vldl over 30',
             round(100 * COUNT(CASE when vldl > 30 THEN 1 END) / count(patid), 2) pct1,
             'pct vldl over 30',
             'vldl'                                                               measure1,
             cohort
      from #all_labs
      group by cohort
      union
      select count(patid),
             COUNT(CASE when nhdl_within_60_days = 1 THEN 1 END)                                count1,
             'N repeat NHDL within 60 days',
             round(100 * COUNT(CASE when nhdl_within_60_days = 1 THEN 1 END) / count(patid), 2) pct1,
             'pct repeat NHDL within 60 days',
             'repeat NHDL within 60 days'                                                       measure1,
             cohort
      from #next_nhdl
      group by cohort
      union
      select count(patid),
             COUNT(CASE when nhdl_within_180_days = 1 THEN 1 END)                                count1,
             'N repeat NHDL within 180 days',
             round(100 * COUNT(CASE when nhdl_within_180_days = 1 THEN 1 END) / count(patid), 2) pct1,
             'pct repeat NHDL within 180 days',
             'repeat NHDL within 180 days'                                                       measure1,
             cohort
      from #next_nhdl
      group by cohort
      union
      select count(a.patid),
             COUNT(CASE when less_than_90_days = 1 THEN 1 END)                                  count1,
             'N lipid panel within 90 days',
             round(100 * COUNT(CASE when less_than_90_days = 1 THEN 1 END) / count(a.patid), 2) pct1,
             'pct lipid panel within 90 days',
             'lipid panel within 90 days'                                                       measure1,
             a.cohort
      from #pat_list a
               left join #lipid_panel_next_closest b on a.patid = b.patid
           --group by cohort
      union
      select count(a.patid),
             COUNT(CASE when less_than_15_months = 1 THEN 1 END)                                  count1,
             'N lipid panel within 15 months',
             round(100 * COUNT(CASE when less_than_15_months = 1 THEN 1 END) / count(a.patid), 2) pct1,
             'pct lipid panel within 15 months',
             'lipid panel within 15 months'                                                       measure1,
             a.cohort
      from #pat_list a
               left join #lipid_panel_next_closest b on a.patid = b.patid
         --group by cohort


         /*order by 7, 6, 5*/) c;
select *
from #table3a;
select *
from #table3b;

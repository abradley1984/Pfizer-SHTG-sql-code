/*This query has two parts - table 3a and table 3b, gotten by uncommenting the second line at the end.

Running time: 8 mins *2
*/

with pat_list as
        (select a.*, LDL_Date as index_date from SHTG_Q2_STEP3_d5 a
    where cohort is not null),
      all_labs as (select Q2_labs_all.*, cohort from Q2_labs_all left join pat_list on pat_list.patid =Q2_labs_all.patid),-- generated in Q2_labs_part1


     HDL_all as (select distinct patid,

                                 --  lab_result_cm.result_num  total_chol_result_num,
                                 -- lab_result_cm.result_unit result_unit,
                                 trunc(lab_result_cm.result_date) result_date


                 FROM pat_list
                          left join cdm_60_etl.lab_result_cm using (patid)
                 WHERE lab_result_cm.result_date BETWEEN TO_DATE('04/01/2019', 'MM/DD/YYYY') AND TO_DATE('09/30/2021', 'MM/DD/YYYY')
                   AND lab_result_cm.lab_loinc in ('2085-9')
                   and lab_result_cm.result_num is not null

                   -- and lab_result_cm.result_num >= 0
                   AND not lab_result_cm.result_unit in
                           ('mg/d', 'g/dL', 'mL/min/{1.73_m2}', 'mL/min') --Excluding rare weird units
         --AND lab_result_cm.result_num < 1000

     ),

     total_chol_all as (select distinct patid,
                                        cohort,

                                        --  lab_result_cm.result_num  total_chol_result_num,
                                        -- lab_result_cm.result_unit result_unit,
                                        trunc(lab_result_cm.result_date) result_date,
                                        index_date


                        FROM pat_list
                                 left join cdm_60_etl.lab_result_cm using (patid)

                        WHERE lab_result_cm.result_date BETWEEN TO_DATE('04/01/2019', 'MM/DD/YYYY') AND TO_DATE('09/30/2021', 'MM/DD/YYYY')
                          AND lab_result_cm.lab_loinc in ('2093-3')
                          and lab_result_cm.result_num is not null

                          -- and lab_result_cm.result_num >= 0
                          AND not lab_result_cm.result_unit in
                                  ('mg/d', 'g/dL', 'mL/min/{1.73_m2}', 'mL/min') --Excluding rare weird units
         --AND lab_result_cm.result_num < 1000

     ),
     lipid_panel_date as (select *
                          from HDL_all
                                   inner join total_chol_all using (patid, result_date)),


     lipid_panel_next_closest as (
         select patid,
                cohort,
                result_date,
                index_date,
                time_from_index,
                row_num,
                case when abs(time_from_index) < 90 then 1 else 0 end  as less_than_90_days,
                case when abs(time_from_index) < 456 then 1 else 0 end as less_than_15_months
         from (select patid,
                      cohort,
                      result_date,
                      index_date,
                      result_date - index_date as time_from_index,
                      row_number() OVER (
                          PARTITION BY patid
                          ORDER BY abs(result_date - index_date) ASC
                          )                       row_num
               from lipid_panel_date
              )
         where row_num in (2)),
     nhdl_after_index as (
         select patid,
                cohort,
                result_date,
                index_date,
                time_from_index,
                row_num,
                case when time_from_index between 1 and 60 then 1 else 0 end  as within_60_days,
                case when time_from_index between 1 and 180 then 1 else 0 end as within_180_days
         from (select patid,
                      cohort,
                      result_date,
                      index_date,
                      result_date - index_date as time_from_index,
                      row_number() OVER (
                          PARTITION BY patid
                          ORDER BY abs(result_date - index_date) ASC
                          )                       row_num
               from lipid_panel_date
              )
         where row_num > 1
           and time_from_index > 0),
     next_nhdl as (select patid,
                          cohort,
                          max(within_60_days)     nhdl_within_60_days,
                          max(within_180_days)    nhdl_within_180_days,
                          min(result_date),
                          min(time_from_index) as nhdl_time_from_index,
                          index_date
                   from nhdl_after_index
                   group by patid, cohort, index_date),
     last_TG_above_500 as (select *
                           from (select patid,
                                        lab_result_cm.result_num         TG_result_num,
                                        lab_result_cm.result_unit        result_unit,
                                        lab_result_cm.result_date,
                                        index_date,
                                        abs(result_date - index_date) as TG_time_from_index,
                                        row_number() OVER (
                                            PARTITION BY patid
                                            ORDER BY abs(result_date - index_date) ASC
                                            )                            row_num

                                 FROM pat_list
                                          left join cdm_60_etl.lab_result_cm using (patid)
                                 WHERE                                                                       --lab_result_cm.result_date BETWEEN TO_DATE('07/31/2020', 'MM/DD/YYYY') AND TO_DATE('09/30/2021', 'MM/DD/YYYY')
                                     lab_result_cm.lab_loinc in ('2571-8', '12951-0')
                                   AND not lab_result_cm.result_unit in ('mg/d', 'g/dL', 'mL/min/{1.73_m2}') --Excluding rare weird units
                                   and lab_result_cm.result_num is not null
                                   and lab_result_cm.result_num >= 500
                                   and (result_date - index_date) <= (-1)--TG occurs before index_date
                                )
                                --and patid in (select patid from pat_list)
                                --AND lab_result_cm.result_num < 1000
                           where row_num = 1
     ),
     diabetic_control as (
         select count(patid)                                   count_patients,
                count(case when a1c is not null then 1 end) as count_non_null,
                median(a1c)                                    median,
                trunc(avg(a1c), 2)                             mean,
                trunc(STDDEV(a1c), 2)                          std,
                PERCENTILE_CONT(0.25) WITHIN
                    GROUP (ORDER BY a1c asc)                   "pct_25",
                PERCENTILE_CONT(0.75) WITHIN
                    GROUP (ORDER BY a1c asc)                   "pct_75",
/*
                COUNT(CASE WHEN a1c >= 7 THEN 1 END)                                as count_over_7,
                COUNT(CASE WHEN a1c >= 8 THEN 1 END)                                as count_over_8,
                trunc(100 * COUNT(CASE WHEN a1c >= 7 THEN 1 END) / count(patid), 2) as pct_over_7,
                trunc(100 * COUNT(CASE WHEN a1c >= 8 THEN 1 END) / count(patid), 2) as pct_over_8
              */
                'A1C'                                          measure1,
                cohort
         from all_labs
         group by cohort),

     table3a as (select *
                 from diabetic_control
                 union
                 select count(patid)                                                                     count_patients,

                        count(case when nhdl_time_from_index is not null then 1 end) as                  count_non_null,
                        trunc(median(nhdl_time_from_index), 2)                                           median,
                        trunc(avg(nhdl_time_from_index), 2)                                              mean,
                        trunc(STDDEV(nhdl_time_from_index), 2)                                           std,
                        trunc(PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY nhdl_time_from_index asc), 2) "pct_25",
                        trunc(PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY nhdl_time_from_index asc), 2) "pct_75",
                        'time to next nHDL (days)',
                        cohort

                 from pat_list
                          left join next_nhdl using (patid, cohort)
                 group by cohort
                 union
                 select count(patid)                                                                   count_patients,

                        count(case when TG_time_from_index is not null then 1 end) as                  count_non_null,
                        trunc(median(TG_time_from_index), 2)                                           median,
                        trunc(avg(TG_time_from_index), 2)                                              mean,
                        trunc(STDDEV(TG_time_from_index), 2)                                           std,
                        trunc(PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY TG_time_from_index asc), 2) "pct_25",
                        trunc(PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY TG_time_from_index asc), 2) "pct_75",
                        'time to last TG > 500 (days)',
                        cohort

                 from pat_list
                          left join last_TG_above_500 using (patid)
                 group by cohort
                 union
                 select count(patid)                                   count_patients,
                        count(case when ggt is not null then 1 end) as count_non_null,
                        median(ggt)                                    median,
                        trunc(avg(ggt), 2)                             mean,
                        trunc(STDDEV(ggt), 2)                          std,
                        PERCENTILE_CONT(0.25) WITHIN
                            GROUP (ORDER BY ggt asc)                   "pct_25",
                        PERCENTILE_CONT(0.75) WITHIN
                            GROUP (ORDER BY ggt asc)                   "pct_75",
                        'ggt'                                       as measure1,
                        cohort
                 from all_labs
                 group by cohort
                 union
                 select count(patid)                                                        count_patients,
                        count(case when albumin is not null then 1 end) as                  count_non_null
                         ,
                        trunc(median(albumin), 2)                                           median,
                        trunc(avg(albumin), 2)                                              mean,
                        trunc(STDDEV(albumin), 2)                                           std,
                        trunc(PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY albumin asc), 2) "pct_25",
                        trunc(PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY albumin asc), 2) "pct_75",
                        'albumin',
                        cohort
                 from all_labs
                 group by cohort
                 union
                 select count(patid)                                   count_patients,
                        count(case when ast is not null then 1 end) as count_non_null,
                        median(ast)                                    median,
                        trunc(avg(ast), 2)                             mean,
                        trunc(STDDEV(ast), 2)                          std,
                        PERCENTILE_CONT(0.25) WITHIN
                            GROUP (ORDER BY ast asc)                   "pct_25",
                        PERCENTILE_CONT(0.75) WITHIN
                            GROUP (ORDER BY ast asc)                   "pct_75",
                        'ast',
                        cohort
                 from all_labs
                 group by cohort
                 union
                 select count(patid)                                   count_patients,
                        count(case when alt is not null then 1 end) as count_non_null,
                        median(alt)                                    median,
                        trunc(avg(alt), 2)                             mean,
                        trunc(STDDEV(alt), 2)                          std,
                        PERCENTILE_CONT(0.25) WITHIN
                            GROUP (ORDER BY alt asc)                   "pct_25",
                        PERCENTILE_CONT(0.75) WITHIN
                            GROUP (ORDER BY alt asc)                   "pct_75",
                        'alt',
                        cohort
                 from all_labs
                 group by cohort
                 union
                 select count(patid)                                   count_patients,
                        count(case when alp is not null then 1 end) as count_non_null,
                        median(alp)                                    median,
                        trunc(avg(alp), 2)                             mean,
                        trunc(STDDEV(alp), 2)                          std,
                        PERCENTILE_CONT(0.25) WITHIN
                            GROUP (ORDER BY alp asc)                   "pct_25",
                        PERCENTILE_CONT(0.75) WITHIN
                            GROUP (ORDER BY alp asc)                   "pct_75",
                        'alp',
                        cohort
                 from all_labs
                 group by cohort
                 union
                 select count(patid)                                     count_patients,
                        count(case when FIB_4 is not null then 1 end) as count_non_null,
                        median(FIB_4)                                    median,
                        trunc(avg(FIB_4), 2)                             mean,
                        trunc(STDDEV(FIB_4), 2)                          std,
                        trunc(PERCENTILE_CONT(0.25) WITHIN
                            GROUP (ORDER BY FIB_4 asc), 2)               "pct_25",
                        trunc(PERCENTILE_CONT(0.75) WITHIN
                            GROUP (ORDER BY FIB_4 asc), 2)               "pct_75",
                        'FIB_4',
                        cohort
                 from all_labs
                 group by cohort
                 union
                 select count(patid)                                   count_patients,
                        count(case when BMI is not null then 1 end) as count_non_null,
                        median(BMI)                                    median,
                        trunc(avg(BMI), 2)                             mean,
                        trunc(STDDEV(BMI), 2)                          std,
                        trunc(PERCENTILE_CONT(0.25) WITHIN
                            GROUP (ORDER BY BMI asc), 2)               "pct_25",
                        trunc(PERCENTILE_CONT(0.75) WITHIN
                            GROUP (ORDER BY BMI asc), 2)               "pct_75",
                        'BMI',
                        cohort
                 from all_labs
                 group by cohort
                 union
                 select count(patid)                                      count_patients,
                        count(case when weight is not null then 1 end) as count_non_null,
                        median(weight)                                    median,
                        trunc(avg(weight), 2)                             mean,
                        trunc(STDDEV(weight), 2)                          std,
                        PERCENTILE_CONT(0.25) WITHIN
                            GROUP (ORDER BY weight asc)                   "pct_25",
                        PERCENTILE_CONT(0.75) WITHIN
                            GROUP (ORDER BY weight asc)                   "pct_75",
                        'weight',
                        cohort
                 from all_labs
                 group by cohort
                 union
                 select count(patid)                                    count_patients,
                        count(case when apob is not null then 1 end) as count_non_null,
                        median(apob)                                    median,
                        trunc(avg(apob), 2)                             mean,
                        trunc(STDDEV(apob), 2)                          std,
                        PERCENTILE_CONT(0.25) WITHIN
                            GROUP (ORDER BY apob asc)                   "pct_25",
                        PERCENTILE_CONT(0.75) WITHIN
                            GROUP (ORDER BY apob asc)                   "pct_75",
                        'apob',
                        cohort
                 from all_labs
                 group by cohort
                 union
                 select count(patid)                                  count_patients,
                        count(case when TG is not null then 1 end) as count_non_null,
                        median(TG)                                    median,
                        trunc(avg(TG), 2)                             mean,
                        trunc(STDDEV(TG), 2)                          std,
                        PERCENTILE_CONT(0.25) WITHIN
                            GROUP (ORDER BY TG asc)                   "pct_25",
                        PERCENTILE_CONT(0.75) WITHIN
                            GROUP (ORDER BY TG asc)                   "pct_75",
                        'TG',
                        cohort
                 from all_labs
                 group by cohort
                 union
                 select count(patid)                                   count_patients,
                        count(case when LDL is not null then 1 end) as count_non_null,
                        median(LDL)                                    median,
                        trunc(avg(LDL), 2)                             mean,
                        trunc(STDDEV(LDL), 2)                          std,
                        PERCENTILE_CONT(0.25) WITHIN
                            GROUP (ORDER BY LDL asc)                   "pct_25",
                        PERCENTILE_CONT(0.75) WITHIN
                            GROUP (ORDER BY LDL asc)                   "pct_75",
                        'LDL',
                        cohort
                 from all_labs
                 group by cohort
                 union
                 select count(patid)                                   count_patients,
                        count(case when HDL is not null then 1 end) as count_non_null,
                        median(HDL)                                    median,
                        trunc(avg(HDL), 2)                             mean,
                        trunc(STDDEV(HDL), 2)                          std,
                        PERCENTILE_CONT(0.25) WITHIN
                            GROUP (ORDER BY HDL asc)                   "pct_25",
                        PERCENTILE_CONT(0.75) WITHIN
                            GROUP (ORDER BY HDL asc)                   "pct_75",
                        'HDL',
                        cohort
                 from all_labs
                 group by cohort
                 union
                 select count(patid)                                    count_patients,
                        count(case when nhdl is not null then 1 end) as count_non_null,
                        median(nhdl)                                    median,
                        trunc(avg(nhdl), 2)                             mean,
                        trunc(STDDEV(nhdl), 2)                          std,
                        PERCENTILE_CONT(0.25) WITHIN
                            GROUP (ORDER BY nhdl asc)                   "pct_25",
                        PERCENTILE_CONT(0.75) WITHIN
                            GROUP (ORDER BY nhdl asc)                   "pct_75",
                        'nhdl',
                        cohort
                 from all_labs
                 group by cohort
                 union
                 select count(patid)                                    count_patients,
                        count(case when vldl is not null then 1 end) as count_non_null,
                        median(vldl)                                    median,
                        trunc(avg(vldl), 2)                             mean,
                        trunc(STDDEV(vldl), 2)                          std,
                        PERCENTILE_CONT(0.25) WITHIN
                            GROUP (ORDER BY vldl asc)                   "pct_25",
                        PERCENTILE_CONT(0.75) WITHIN
                            GROUP (ORDER BY vldl asc)                   "pct_75",
                        'vldl',
                        cohort
                 from all_labs
                 group by cohort
                 union
                 select count(patid)                                    count_patients,
                        count(case when apob is not null then 1 end) as count_non_null,
                        median(apob)                                    median,
                        trunc(avg(apob), 2)                             mean,
                        trunc(STDDEV(apob), 2)                          std,
                        PERCENTILE_CONT(0.25) WITHIN
                            GROUP (ORDER BY apob asc)                   "pct_25",
                        PERCENTILE_CONT(0.75) WITHIN
                            GROUP (ORDER BY apob asc)                   "pct_75",
                        'apob',
                        cohort
                 from all_labs
                 group by cohort
                 union
                 select count(patid)                                   count_patients,
                        count(case when nlr is not null then 1 end) as count_non_null,
                        median(nlr)                                    median,
                        trunc(avg(nlr), 2)                             mean,
                        trunc(STDDEV(nlr), 2)                          std,
                        PERCENTILE_CONT(0.25) WITHIN
                            GROUP (ORDER BY nlr asc)                   "pct_25",
                        PERCENTILE_CONT(0.75) WITHIN
                            GROUP (ORDER BY nlr asc)                   "pct_75",
                        'nlr',
                        cohort
                 from all_labs
                 group by cohort
                 union
                 select count(patid)                                     count_patients,
                        count(case when hscrp is not null then 1 end) as count_non_null,
                        median(hscrp)                                    median,
                        trunc(avg(hscrp), 2)                             mean,
                        trunc(STDDEV(hscrp), 2)                          std,
                        PERCENTILE_CONT(0.25) WITHIN
                            GROUP (ORDER BY hscrp asc)                   "pct_25",
                        PERCENTILE_CONT(0.75) WITHIN
                            GROUP (ORDER BY hscrp asc)                   "pct_75",
                        'hscrp',
                        cohort
                 from all_labs
                 group by cohort
                 union
                 select count(patid)                                      count_patients,
                        count(case when apo_a1 is not null then 1 end) as count_non_null,
                        median(apo_a1)                                    median,
                        trunc(avg(apo_a1), 2)                             mean,
                        trunc(STDDEV(apo_a1), 2)                          std,
                        PERCENTILE_CONT(0.25) WITHIN
                            GROUP (ORDER BY apo_a1 asc)                   "pct_25",
                        PERCENTILE_CONT(0.75) WITHIN
                            GROUP (ORDER BY apo_a1 asc)                   "pct_75",
                        'apo_a1',
                        cohort
                 from all_labs
                 group by cohort
                 union
                 select count(patid)                                       count_patients,
                        count(case when lpa_mol is not null then 1 end) as count_non_null,
                        median(lpa_mol)                                    median,
                        trunc(avg(lpa_mol), 2)                             mean,
                        trunc(STDDEV(lpa_mol), 2)                          std,
                        PERCENTILE_CONT(0.25) WITHIN
                            GROUP (ORDER BY lpa_mol asc)                   "pct_25",
                        PERCENTILE_CONT(0.75) WITHIN
                            GROUP (ORDER BY lpa_mol asc)                   "pct_75",
                        'lpa mol',
                        cohort
                 from all_labs
                 group by cohort
                 union
                 select count(patid)                                        count_patients,
                        count(case when lpa_mass is not null then 1 end) as count_non_null,
                        median(lpa_mass)                                    median,
                        trunc(avg(lpa_mass), 2)                             mean,
                        trunc(STDDEV(lpa_mass), 2)                          std,
                        PERCENTILE_CONT(0.25) WITHIN
                            GROUP (ORDER BY lpa_mass asc)                   "pct_25",
                        PERCENTILE_CONT(0.75) WITHIN
                            GROUP (ORDER BY lpa_mass asc)                   "pct_75",
                        'lpa mass',
                        cohort
                 from all_labs
                 group by cohort
                 union
                 select count(patid)                                    count_patients,
                        count(case when TRLC is not null then 1 end) as count_non_null,
                        median(TRLC)                                    median,
                        trunc(avg(TRLC), 2)                             mean,
                        trunc(STDDEV(TRLC), 2)                          std,
                        PERCENTILE_CONT(0.25) WITHIN
                            GROUP (ORDER BY TRLC asc)                   "pct_25",
                        PERCENTILE_CONT(0.75) WITHIN
                            GROUP (ORDER BY TRLC asc)                   "pct_75",
                        'TRLC',
                        cohort
                 from all_labs
                 group by cohort
                 union
                 select count(patid)                                         count_patients,
                        count(case when egfr_2021 is not null then 1 end) as count_non_null,
                        trunc(median(egfr_2021), 2)                          median,
                        trunc(avg(egfr_2021), 2)                             mean,
                        trunc(STDDEV(egfr_2021), 2)                          std,
                        trunc(PERCENTILE_CONT(0.25) WITHIN
                            GROUP (ORDER BY egfr_2021 asc), 2)               "pct_25",
                        trunc(PERCENTILE_CONT(0.75) WITHIN
                            GROUP (ORDER BY egfr_2021 asc), 2)               "pct_75",
                        'egfr_2021',
                        cohort
                 from all_labs
                 group by cohort)
        ,


     table3b as (select count(patid),
                        COUNT(CASE WHEN lpa_mol >= 125 THEN 1 END)                                 count1,
                        'N_lpa_over_125_nmol'   as                                                 count_label,
                        trunc(100 * COUNT(CASE WHEN lpa_mass >= 125 THEN 1 END) / count(patid), 2) pct1,
                        'pct_lpa_over_125_nmol' as                                                 pct_label,
                        'lpa_mol'                                                                  measure1,
                        cohort
                 from all_labs
                 group by cohort
                 union
                 select count(patid),
                        COUNT(CASE WHEN lpa_mass >= 50 THEN 1 END)                                count1,
                        'N_lpa_over_50mg'   as                                                    count_label,
                        trunc(100 * COUNT(CASE WHEN lpa_mass >= 50 THEN 1 END) / count(patid), 2) pct1,
                        'pct_lpa_over_50mg' as                                                    pct_label,
                        'lpa_mass'                                                                measure1,
                        cohort
                 from all_labs
                 group by cohort
                 union
                 select count(patid),
                        COUNT(CASE WHEN a1c >= 7 THEN 1 END)                                count1,
                        'N_a1c_over_7'   as                                                 count_label,
                        trunc(100 * COUNT(CASE WHEN a1c >= 7 THEN 1 END) / count(patid), 2) pct1,
                        'pct_a1c_over_7' as                                                 pct_label,
                        'A1C'                                                               measure1,
                        cohort
                 from all_labs
                 group by cohort
                 union
                 select count(patid),
                        COUNT(CASE WHEN a1c >= 8 THEN 1 END)                                as count2,
                        'N_a1c_over_8',

                        trunc(100 * COUNT(CASE WHEN a1c >= 8 THEN 1 END) / count(patid), 2) as pct2
                         ,
                        'pct_a1c_over_8',
                        'A1C'                                                                  measure1,
                        cohort
                 from all_labs
                 group by cohort
                 union
                 select count(patid),


                        COUNT(CASE WHEN (FIB_4 >= 1.30 and AGE < 65) THEN 1 END),
                        'N_fib4_over_1_30_age_under_65',

                        trunc(100 * COUNT(CASE WHEN FIB_4 >= 1.30 THEN 1 END) / count(patid), 2) pct_fib4_over_1_30,
                        'pct_fib4_over_1_30_under_65',
                        'FIB4'                                                                   measure1,
                        cohort
                 from all_labs
                 group by cohort
                 union
                 select count(patid),
                        COUNT(CASE WHEN (FIB_4 >= 2.0 and AGE >= 65) THEN 1 END),
                        'N_fib4_over_2_age_over_65',
                        trunc(100 * COUNT(CASE WHEN (FIB_4 >= 2.0 and AGE >= 65) THEN 1 END) / count(patid),
                              2) pct_fib4_over_2,
                        'pct_fib4_over_age_over_65',
                        'FIB4'   measure1,
                        cohort
                 from all_labs
                 group by cohort
                 union
                 select count(patid),
                        COUNT(CASE WHEN FIB_4 >= 2.67 THEN 1 END),
                        'N_fib4_over_2_67',

                        trunc(100 * COUNT(CASE WHEN FIB_4 >= 2.67 THEN 1 END) / count(patid), 2) as pct_fib4_over_2_67
                         ,
                        'pct_fib4_over_2_67',
                        'FIB4'                                                                      measure1,
                        cohort
                 from all_labs
                 group by cohort
                 union
                 select count(patid),
                        COUNT(CASE WHEN BMI < 20 THEN 1 END)                                count1,
                        'N BMI under 20',
                        trunc(100 * COUNT(CASE WHEN BMI < 20 THEN 1 END) / count(patid), 2) pct1,
                        'pct BMI under 20',
                        'BMI'                                                               measure1,
                        cohort
                 from all_labs
                 group by cohort
                 union
                 select count(patid),
                        COUNT(CASE WHEN BMI >= 40 THEN 1 END),
                        'N BMI over 40',

                        trunc(100 * COUNT(CASE WHEN BMI >= 40 THEN 1 END) / count(patid), 2) as pct2
                         ,
                        'pct BMI over 40',
                        'BMI'                                                                   measure1,
                        cohort
                 from all_labs
                 group by cohort
                 union
                 select count(patid),
                        COUNT(CASE WHEN BMI between 20 and 25 THEN 1 END),
                        'N BMI 20 to 25',
                        trunc(100 * COUNT(CASE WHEN BMI between 20 and 25 THEN 1 END) / count(patid), 2) pct3,
                        'pct BMI 20 to 25',
                        'BMI'                                                                            measure1,
                        cohort
                 from all_labs
                 group by cohort
                 union
                 select count(patid),
                        COUNT(CASE WHEN BMI between 35 and 40 THEN 1 END),
                        'N BMI 35 to 40',

                        trunc(100 * COUNT(CASE WHEN BMI between 35 and 40 THEN 1 END) / count(patid), 2) as pct4
                         ,
                        'pct BMI 35 to 40',
                        'BMI'                                                                               measure1,
                        cohort
                 from all_labs
                 group by cohort
                 union
                 select count(patid),
                        COUNT(CASE WHEN BMI between 25 and 30 THEN 1 END),
                        'N BMI 25 to 30',
                        trunc(100 * COUNT(CASE WHEN BMI between 25 and 30 THEN 1 END) / count(patid), 2) pct5,
                        'pct BMI 25 to 30',
                        'BMI'                                                                            measure1,
                        cohort
                 from all_labs
                 group by cohort
                 union
                 select count(patid),
                        COUNT(CASE WHEN BMI between 30 and 35 THEN 1 END)                                   count1,
                        'N BMI 30 to 35',

                        trunc(100 * COUNT(CASE WHEN BMI between 30 and 35 THEN 1 END) / count(patid), 2) as pct6
                         ,
                        'pct BMI 30 to 35',
                        'BMI'                                                                               measure1,
                        cohort
                 from all_labs
                 group by cohort
                 union
                 select count(patid),
                        COUNT(CASE when egfr_2021 > 90 THEN 1 END)                                count1,
                        'N eGFR over 90',
                        trunc(100 * COUNT(CASE when egfr_2021 > 90 THEN 1 END) / count(patid), 2) pct1,
                        'pct eGFR over 90',
                        'eGFR'                                                                    measure1,
                        cohort
                 from all_labs
                 group by cohort
                 union
                 select count(patid),
                        COUNT(CASE when egfr_2021 < 15 THEN 1 END),
                        'N eGFR under 15',

                        trunc(100 * COUNT(CASE when egfr_2021 < 15 THEN 1 END) / count(patid), 2) as pct2
                         ,
                        'pct eGFR under 15',
                        'eGFR'                                                                       measure1,
                        cohort
                 from all_labs
                 group by cohort
                 union
                 select count(patid),
                        COUNT(CASE when egfr_2021 between 60 and 90 THEN 1 END),
                        'N eGFR 60 to 90',
                        trunc(100 * COUNT(CASE when egfr_2021 between 60 and 90 THEN 1 END) / count(patid), 2) pct3,
                        'pct eGFR 60 to 90',
                        'eGFR'                                                                                 measure1,
                        cohort
                 from all_labs
                 group by cohort

                 union
                 select count(patid),
                        COUNT(CASE when egfr_2021 between 45 and 60 THEN 1 END),
                        'N eGFR 45 to 60',
                        trunc(100 * COUNT(CASE when egfr_2021 between 45 and 60 THEN 1 END) / count(patid), 2) pct5,
                        'pct eGFR 45 to 60',
                        'eGFR'                                                                                 measure1,
                        cohort
                 from all_labs
                 group by cohort
                 union
                 select count(patid),
                        COUNT(CASE when egfr_2021 between 30 and 45 THEN 1 END)                                   count1,
                        'N eGFR 30 to 45',

                        trunc(100 * COUNT(CASE when egfr_2021 between 30 and 45 THEN 1 END) / count(patid), 2) as pct6
                         ,
                        'pct eGFR 30 to 45',
                        'eGFR'                                                                                    measure1,
                        cohort
                 from all_labs
                 group by cohort
                 union
                 select count(patid),
                        COUNT(CASE when egfr_2021 between 15 and 30 THEN 1 END),
                        'N eGFR 15 to 30',

                        trunc(100 * COUNT(CASE when egfr_2021 between 15 and 30 THEN 1 END) / count(patid), 2) as pct4
                         ,
                        'pct eGFR 15 to 30',
                        'eGFR'                                                                                    measure1,
                        cohort
                 from all_labs
                 group by cohort
                 union
                 select count(patid),
                        COUNT(CASE when LDL > 160 THEN 1 END)                                count1,
                        'N LDL over 160',
                        trunc(100 * COUNT(CASE when LDL > 160 THEN 1 END) / count(patid), 2) pct1,
                        'pct LDL over 160',
                        'LDL'                                                                measure1,
                        cohort
                 from all_labs
                 group by cohort
                 union
                 select count(patid),
                        COUNT(CASE when LDL < 70 THEN 1 END),
                        'N LDL under 70',

                        trunc(100 * COUNT(CASE when LDL < 70 THEN 1 END) / count(patid), 2) as pct2
                         ,
                        'pct LDL under 70',
                        'LDL'                                                                  measure1,
                        cohort
                 from all_labs
                 group by cohort
                 union
                 select count(patid),
                        COUNT(CASE when LDL between 130 and 160 THEN 1 END),
                        'N LDL 130 to 160',
                        trunc(100 * COUNT(CASE when LDL between 130 and 160 THEN 1 END) / count(patid), 2) pct3,
                        'pct LDL 130 to 160',
                        'LDL'                                                                              measure1,
                        cohort
                 from all_labs
                 group by cohort

                 union
                 select count(patid),
                        COUNT(CASE when LDL between 100 and 130 THEN 1 END),
                        'N LDL 100 to 130',
                        trunc(100 * COUNT(CASE when LDL between 100 and 130 THEN 1 END) / count(patid), 2) pct5,
                        'pct LDL 100 to 130',
                        'LDL'                                                                              measure1,
                        cohort
                 from all_labs
                 group by cohort
                 union
                 select count(patid),
                        COUNT(CASE when LDL between 70 and 100 THEN 1 END)                                   count1,
                        'N LDL 70 to 100',

                        trunc(100 * COUNT(CASE when LDL between 70 and 100 THEN 1 END) / count(patid), 2) as pct6
                         ,
                        'pct LDL 70 to 100',
                        'LDL'                                                                                measure1,
                        cohort
                 from all_labs
                 group by cohort
                 union
                 select count(patid),
                        COUNT(CASE when TG > 2000 THEN 1 END)                                count1,
                        'N TG over 2000',
                        trunc(100 * COUNT(CASE when TG > 2000 THEN 1 END) / count(patid), 2) pct1,
                        'pct TG over 2000',
                        'TG'                                                                 measure1,
                        cohort
                 from all_labs
                 group by cohort
                 union
                 select count(patid),
                        COUNT(CASE when TG < 500 THEN 1 END),
                        'N TG under 500',

                        trunc(100 * COUNT(CASE when TG < 500 THEN 1 END) / count(patid), 2) as pct2
                         ,
                        'pct TG under 500',
                        'TG'                                                                   measure1,
                        cohort
                 from all_labs
                 group by cohort
                 union
                 select count(patid),
                        COUNT(CASE when TG between 1000 and 2000 THEN 1 END),
                        'N TG 1000 to 2000',
                        trunc(100 * COUNT(CASE when TG between 1000 and 2000 THEN 1 END) / count(patid), 2) pct3,
                        'pct TG 1000 to 2000',
                        'TG'                                                                                measure1,
                        cohort
                 from all_labs
                 group by cohort

                 union
                 select count(patid),
                        COUNT(CASE when TG between 880 and 1000 THEN 1 END),
                        'N TG 880 to 1000',
                        trunc(100 * COUNT(CASE when TG between 880 and 1000 THEN 1 END) / count(patid), 2) pct5,
                        'pct TG 880 to 1000',
                        'TG'                                                                               measure1,
                        cohort
                 from all_labs
                 group by cohort
                 union
                 select count(patid),
                        COUNT(CASE when TG between 500 and 880 THEN 1 END)                                   count1,
                        'N TG 500 to 880 ',

                        trunc(100 * COUNT(CASE when TG between 500 and 880 THEN 1 END) / count(patid), 2) as pct6
                         ,
                        'pct TG 500 to 880 ',
                        'TG'                                                                                 measure1,
                        cohort
                 from all_labs
                 group by cohort
                 union
                 select count(patid),
                        COUNT(CASE when TG between 150 and 500 THEN 1 END)                                   count1,
                        'N TG 150 to 500',

                        trunc(100 * COUNT(CASE when TG between 150 and 500 THEN 1 END) / count(patid), 2) as pct6
                         ,
                        'pct TG 150 to 500',
                        'TG'                                                                                 measure1,
                        cohort
                 from all_labs
                 group by cohort
                 union
                 select count(patid),
                        COUNT(CASE when nHDL > 190 THEN 1 END)                                count1,
                        'N nHDL over 190',
                        trunc(100 * COUNT(CASE when nHDL > 190 THEN 1 END) / count(patid), 2) pct1,
                        'pct nHDL over 190',
                        'nHDL'                                                                measure1,
                        cohort
                 from all_labs

                 group by cohort
                 union
                 select count(patid),
                        COUNT(CASE when nHDL between 160 and 190 THEN 1 END),
                        'N nHDL 160 to 190',
                        trunc(100 * COUNT(CASE when nHDL between 160 and 190 THEN 1 END) / count(patid), 2) pct3,
                        'pct nHDL 160 to 190',
                        'nHDL'                                                                              measure1,
                        cohort
                 from all_labs
                 group by cohort

                 union
                 select count(patid),
                        COUNT(CASE when nHDL between 130 and 160 THEN 1 END),
                        'N nHDL 130 to 160',
                        trunc(100 * COUNT(CASE when nHDL between 130 and 160 THEN 1 END) / count(patid), 2) pct5,
                        'pct nHDL 130 to 160',
                        'nHDL'                                                                              measure1,
                        cohort
                 from all_labs
                 group by cohort
                 union
                 select count(patid),
                        COUNT(CASE when nHDL between 100 and 130 THEN 1 END)                                   count1,
                        'N nHDL 100 to 130',

                        trunc(100 * COUNT(CASE when nHDL between 100 and 130 THEN 1 END) / count(patid), 2) as pct6
                         ,
                        'pct nHDL 100 to 130',
                        'nHDL'                                                                                 measure1,
                        cohort
                 from all_labs
                 group by cohort
                 union
                 select count(patid),
                        COUNT(CASE when apob > 130 THEN 1 END)                                count1,
                        'N apob over 130',
                        trunc(100 * COUNT(CASE when apob > 130 THEN 1 END) / count(patid), 2) pct1,
                        'pct apob over 130',
                        'apob'                                                                measure1,
                        cohort
                 from all_labs
                 group by cohort
                 union
                 select count(patid),
                        COUNT(CASE when vldl > 30 THEN 1 END)                                count1,
                        'N vldl over 30',
                        trunc(100 * COUNT(CASE when vldl > 30 THEN 1 END) / count(patid), 2) pct1,
                        'pct vldl over 30',
                        'vldl'                                                               measure1,
                        cohort
                 from all_labs
                 group by cohort
                 union
                 select count(patid),
                        COUNT(CASE when nhdl_within_60_days = 1 THEN 1 END)                                count1,
                        'N repeat NHDL within 60 days',
                        trunc(100 * COUNT(CASE when nhdl_within_60_days = 1 THEN 1 END) / count(patid), 2) pct1,
                        'pct repeat NHDL within 60 days',
                        'repeat NHDL within 60 days'                                                       measure1,
                        cohort
                 from next_nhdl
                 group by cohort
                 union
                 select count(patid),
                        COUNT(CASE when nhdl_within_180_days = 1 THEN 1 END)                                count1,
                        'N repeat NHDL within 180 days',
                        trunc(100 * COUNT(CASE when nhdl_within_180_days = 1 THEN 1 END) / count(patid), 2) pct1,
                        'pct repeat NHDL within 180 days',
                        'repeat NHDL within 180 days'                                                       measure1,
                        cohort
                 from next_nhdl
                 group by cohort
                 union
                 select count(patid),
                        COUNT(CASE when less_than_90_days = 1 THEN 1 END)                                count1,
                        'N lipid panel within 90 days',
                        trunc(100 * COUNT(CASE when less_than_90_days = 1 THEN 1 END) / count(patid), 2) pct1,
                        'pct lipid panel within 90 days',
                        'lipid panel within 90 days'                                                     measure1,
                        cohort
                 from pat_list
                          left join lipid_panel_next_closest using (patid, cohort)
                 group by cohort
                 union
                 select count(patid),
                        COUNT(CASE when less_than_15_months = 1 THEN 1 END)                                count1,
                        'N lipid panel within 15 months',
                        trunc(100 * COUNT(CASE when less_than_15_months = 1 THEN 1 END) / count(patid), 2) pct1,
                        'pct lipid panel within 15 months',
                        'lipid panel within 15 months'                                                     measure1,
                        cohort
                 from pat_list
                          left join lipid_panel_next_closest using (patid, cohort)
                 group by cohort


                 order by 7, 6, 5)
--select * from table3a;
select * from table3b;

--To do -edit insurance categories to apply to other sites
--Check provider categories?
--combine race, smoking categories

--with pat_list as (select * from htg_step3_with_exclusions_d1),
with pat_list as (select * from shtg_Q1_cohorts_with_exclusions),
     smoking AS (select *
                 from (
                          select patid,
                                 row_number() OVER (
                                     PARTITION BY patid
                                     ORDER BY vital.measure_date desc
                                     )            row_num,
                                 vital.smoking as smoking,
                                 cohort

                          FROM pat_list
                                   left join cdm_60_etl.vital using (patid)
                          WHERE vital.smoking IS NOT NULL
                            AND not vital.smoking in ('NI', 'OT', 'UN'))
                 where row_num = 1),
     smoking_category as (select patid,
                                 cohort,
                                 smoking,
                                 case
                                     when smoking in ('01', '02', '07', '08') then 'Current smoker'
                                     when smoking in ('NI', 'UN', '05', '06', 'OT') then 'NI/unknown/refuse to answer'
                                     when smoking = '03' then 'Former smoker'
                                     when smoking = '04' then 'Never smoker'

                                     else 'check_categorization'
                                     end as smoking_category


                          from smoking),
     race_category as (select patid,
                              cohort,
                              race,
                              hispanic,
                              case
                                  when race in ('01', '04', '06', 'OT') then 'Other'
                                  when race in ('NI', 'UN', '07') then 'NI/unknown/refuse to answer'
                                  when race = '03' then 'Black/African American'
                                  when race = '05' then 'White'
                                  when race = '02' then 'Asian'
                                  else 'check_categorization'
                                  end as race_category,
                              case
                                  when hispanic in ('R', 'NI', 'UN', 'OT') then 'NI/unknown/refuse to answer'
                                  when hispanic = 'Y' then 'hispanic'
                                  when hispanic = 'N' then 'non-hispanic'
                                  else 'check_categorization'
                                  end as hispanic_category

                       from pat_list),
     sex_category as (select patid,
                             cohort,
                             sex,
                             case
                                 when sex = 'M' then 'Male'
                                 when sex = 'F' then 'Female'
                                 when sex = 'OT' then 'Other'
                                 else 'NI/unknown/refuse to answer'
                                 end
                                 as sex_category


                      from pat_list),
    /* age_Category as (select patid, case
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
                          else 'uhoh'
                          end as Age_category
               from pat_list),*/
     insurance as (select *
                   from pat_list
                            left join CDM_60_ETL.encounter e using (patid)
                   where e.admit_date BETWEEN TO_DATE('9/30/2020', 'MM/DD/YYYY') AND TO_DATE('9/30/2021', 'MM/DD/YYYY')
                     and raw_payer_type_primary is not null),
     insurance_type as (select patid,
                               COHORT,
                               raw_payer_type_primary,
                               raw_payer_id_primary,
                               case
                                   when raw_payer_id_primary in (
                                                                 'X',
                                                                 '3',
                                                                 '104',
                                                                 '143',
                                                                 '151',
                                                                 '127',
                                                                 '157',
                                                                 '155',
                                                                 '103')
                                       then 'Medicaid'
                                   when raw_payer_id_primary in ('147',
                                                                 '159',
                                                                 'N',
                                                                 '137',
                                                                 '2M',
                                                                 '2',
                                                                 '152',
                                                                 'MC',
                                                                 '150',
                                                                 '142',
                                                                 '156',
                                                                 '101',
                                                                 'M',
                                                                 'UM',
                                                                 '2'
                                       ) then 'Medicare'
                                   when raw_payer_id_primary in ('116', '111', '3C', 'cc', '145',
                                                                 '4A',
                                                                 '4M',
                                                                 '138',
                                                                 'I4',
                                                                 '134',
                                                                 'IC',
                                                                 'HA',
                                                                 '2B',
                                                                 '4',
                                                                 '158',
                                                                 '107',
                                                                 'DB',
                                                                 'CM',
                                                                 'B',
                                                                 '119',
                                                                 '0',
                                                                 '4H',
                                                                 '149',
                                                                 'C',
                                                                 '132',
                                                                 '133',
                                                                 '10',
                                                                 'CG',
                                                                 'AD',
                                                                 'MS',
                                                                 '131',
                                                                 'MU',
                                                                 'GA',
                                                                 'US',
                                                                 '100',
                                                                 '144',
                                                                 '1',
                                                                 'Q',
                                                                 '153',
                                                                 'UH',
                                                                 '102',
                                                                 'BE',
                                                                 '108',
                                                                 '112'
                                       ) then 'Commercial'

                                   when raw_payer_id_primary is null then 'No Information'
                                   else 'Other'
                                   end as insurance_type
                        from insurance),
     providers as (
         select patid,
                provider_specialty_primary,
                cohort,

                case
                    when provider_specialty_primary in
                         ('208D00000X', '163WG0000X', '207Q00000X', '207QA0000X', '207QA0505X', '207R00000X',
                          '207RA0000X',
                          '207RG0300X', '2083P0901X', '261QP2300X', '363LP2300X', '364SF0001X') then 'primary_care'
                    when provider_specialty_primary in
                         ('207RC0000X', '207RA0001X', '207RC0001X', '207RI0011X', '2080P0202X') then 'cardiology'
                    when provider_specialty_primary in
                         ('163WE0003X', '207P00000X', '207PE0004X', '207PP0204X', '207PS0010X', '207PT0002X',
                          '2080P0204X', '261QE0002X', '364SE0003X') then 'emergency medicine'
                    when provider_specialty_primary in ('207RG0100X') then 'GI'
                    when provider_specialty_primary in ('207RE0101X', '2080P0205X') then 'endo'
                    else 'other'
                    end as provider_specialty
         from pat_list
                  left join cdm_60_etl.encounter using (patid)
                  left join cdm_60_etl.provider on encounter.providerid = provider.providerid
         where provider_specialty_primary in
               ('208D00000X', '163WG0000X', '207Q00000X', '207RC0000X', '207RA0001X', '207RC0001X', '207RI0011X',
                '2080P0202X', '163WE0003X',
                '207P00000X', '207PE0004X', '207PP0204X', '207PS0010X', '207PT0002X', '2080P0204X', '261QE0002X',
                '364SE0003X', '207RE0101X', '2080P0205X', '207RG0100X', '207QA0000X',
                '207QA0505X', '207R00000X', '207RA0000X', '207RG0300X', '2083P0901X', '261QP2300X', '363LP2300X',
                '364SF0001X')
           And encounter.admit_date BETWEEN TO_DATE('9/30/2020', 'MM/DD/YYYY') AND TO_DATE('9/30/2021', 'MM/DD/YYYY'))

/*select distinct patid, cohort, insurance_type, raw_payer_type_primary from insurance_type
order by patid*/
        ,
     Table1_pre as (select '1' as order1, 'Total' as label1, 'Total_count' as label2, count(distinct patid) as N, cohort
                    from pat_list
                    group by cohort
                   union
                    select '2' as order1, 'Age', Age_category, count(distinct patid) as N, cohort
                    from pat_list
                    group by cohort, Age_category
                    union
                    select '2' as order1, 'age', 'Mean age', trunc(avg(age), 2) as N, cohort
                    from pat_list
                    group by cohort
                    union
                    select '2' as order1, 'age', 'Median age', trunc(median(age), 2) as N, cohort
                    from pat_list
                    group by cohort
                    union
                    select '2' as order1, 'age', 'STD age', trunc(STDDEV(age), 2) as N, cohort
                    from pat_list
                    group by cohort
                    union

                    select '2' as order1,
                           'age',
                           'pct_25',
                           PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY age asc)
                                  "pct_25",
                           cohort
                    from pat_list
                    group by cohort
                    union
                    select '2' as order1,
                           'age',
                           'pct_75',
                           PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY age asc)
                                  "pct_75",
                           cohort
                    from pat_list
                    group by cohort
                    union

                    select '3' as order1, 'sex', SEX_category, count(distinct patid) as N, cohort
                    from sex_category
                    group by cohort, SEX_category

                    union
                    select '4' as order1, 'race', RACE_category, count(distinct patid) as N, cohort
                    from race_category
                    group by cohort, race_category
                    union
                    select '5' as order1, 'hispanic ethnicity', hispanic_category, count(distinct patid) as N, cohort
                    from race_category
                    group by cohort, hispanic_category
                    union
                    select '8' as order1, 'Insurance', insurance_type, count(distinct patid), cohort
                    from insurance_type
                    group by insurance_type, cohort

                    union
                    select '8' as order1, 'Insurance', 'has_insurance_info', count(distinct patid), cohort
                    from insurance_type

                    group by cohort
                    union
                    select '6' as order1, 'Smoking', smoking_category, count(distinct patid), cohort
                    from smoking_category
                    group by cohort, smoking_category
                    union
                    select '9' as order1, 'pre-index_days', 'Mean', trunc(avg(PRE_INDEX_DAYS)) as N, cohort
                    from pat_list
                    group by cohort
                    union
                    select '9' as order1, 'pre-index_days', 'Median', trunc(median(PRE_INDEX_DAYS)) as N, cohort
                    from pat_list
                    group by cohort
                    union
                    select '9' as order1, 'pre-index_days', 'STD', trunc(STDDEV(PRE_INDEX_DAYS)) as N, cohort
                    from pat_list
                    group by cohort
                    union
                    select '9' as order1,
                           'pre-index_days',
                           'pct_25',
                           PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY PRE_INDEX_DAYS asc)
                                  "pct_25",
                           cohort
                    from pat_list
                    group by cohort
                    union
                    select '9' as order1,
                           'pre-index_days',
                           'pct_75',
                           PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY PRE_INDEX_DAYS asc)
                                  "pct_75",
                           cohort
                    from pat_list
                    group by cohort
                    union

                    select '7' as order1, 'Provider', provider_specialty, count(distinct patid), cohort
                    from providers
                    group by cohort, provider_specialty
                    union
                    select '7' as order1, 'Provider', 'provider_info_available', count(distinct patid), cohort
                    from providers
                    group by cohort
                    union
                    select '2' as order1, 'Age', 'has_age_info', count(distinct patid), cohort
                    from pat_list
                    where Age is not null
                    group by cohort

     ),
     totals as (select N as N_cohort_total, cohort  From Table1_pre where label1 = 'Total' ),

     percentages as (select order1, Cohort, label1, label2, N, N_cohort_total,
                            case  when (Table1_pre.label2 in ('pct_75','pct_25')

        or Table1_pre.label2 like ('Mean%')
             or Table1_pre.label2 like ('Median%')
              or Table1_pre.label2 like ('STD%'))
              then 0
              else
              trunc(100 * N/N_cohort_total,2)
               end
               as percentage1
                     from Table1_pre
                              left join totals using (cohort)

     )


select * from percentages
order by cohort, order1;
from Table1_pre
order by cohort, order1

/* pivot (

sum(N) FOR cohort in ('cohort_A', 'cohort_B', 'cohort_C', 'cohort_D', 'cohort_E', 'cohort_F', 'cohort_G', 'cohort_H', 'cohort_I',' cohort_J','cohort_K')
 )*/

;
/* Generates demographics table (T1) for all cohorts.
   Save to Csv file
   Same for Q1 and Q2, just editing initial pat_list
   Running time: ~2 minutes

   --Edits for sql server: changing percentile and median syntax
   from:
    PERCENTILE_CONT(0.25) WITHIN
GROUP (ORDER BY age asc)
   to:
    PERCENTILE_CONT(0.25) WITHIN
GROUP (ORDER BY age asc) OVER (PARTITION BY cohort)

  -Median is percentile 0.5
   Changing trunc to round
--Possible issue marked with CHECK
 */


select *
into #pat_list
from
                                   foo.dbo.shtg_Q1_cohort_with_exclusions ;
select *
into #smoking
from (
    select a.patid,
    row_number() OVER (
      PARTITION BY a.patid
    ORDER BY measure_date desc
    ) row_num,
    smoking as smoking,
    cohort
    FROM #pat_list a
    left join cdm.dbo.vital  b on a.patid = b.patid
    WHERE smoking IS NOT NULL
    AND not smoking in ('NI', 'OT', 'UN')) c
where row_num = 1;
select a.patid,
       a.cohort,
       smoking,
       case
           when smoking in ('01', '02', '07', '08') then 'Current smoker'
           when smoking in ('NI', 'UN', '05', '06', 'OT') then 'NI/unknown/refuse to answer'
           when smoking is Null then 'NI/unknown/refuse to answer'

           when smoking = '03' then 'Former smoker'
           when smoking = '04' then 'Never smoker'

           else 'check_categorization'
           end as smoking_category

into #smoking_category
from #pat_list a
    left join #smoking  b on a.patid = b.patid;

select patid,
       cohort,
       race,
       hispanic,
       case
           when race in ('01', '04', '06', 'OT') then 'Other'
           when race in ('NI', 'UN', '07') then 'NI/unknown/refuse to answer'
           when race is Null then 'NI/unknown/refuse to answer'
           when race = '03' then 'Black/African American'
           when race = '05' then 'White'
           when race = '02' then 'Asian'
           else 'check_categorization'
           end as race_category,
       case
           when hispanic in ('R', 'NI', 'UN', 'OT') then 'NI/unknown/refuse to answer'
           when hispanic is Null then 'NI/unknown/refuse to answer'
           when hispanic = 'Y' then 'hispanic'
           when hispanic = 'N' then 'non-hispanic'
           else 'check_categorization'
           end as hispanic_category
into #race_category
from #pat_list;

select patid,
       cohort,
       sex,
       case
           when sex = 'M' then 'Male'
           when sex = 'F' then 'Female'
           when sex = 'OT' then 'Other'
           else 'NI/unknown/refuse to answer'
           end
           as sex_category

into #sex_category
from #pat_list ;
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

select a.*, e.payer_type_primary
into #insurance
from #pat_list a
    left join cdm.dbo.encounter e  on a.patid = e.patid
where e.admit_date BETWEEN '2020-09-30'
  AND '2021-09-30'
  and payer_type_primary is not null
  and not payer_type_primary in ('UN'
    , 'NI');


select patid,
       COHORT,
       payer_type_primary,
       case
           when payer_type_primary in (
                                       '2',
                                       '21',
                                       '29')
               then 'Medicaid'
           when payer_type_primary in ('1',
                                       '11',
                                       '19',
                                       '111',
                                       '112',
                                       '122'
               ) then 'Medicare'
           when payer_type_primary in ('5',
                                       '51',
                                       '521',
                                       '561',
                                       '6'
               ) then 'Commercial'
           when payer_type_primary is null then 'No Information'
           when payer_type_primary = 'UN' then 'No Information'
           else 'Other'
           end as insurance_type
into #insurance_type
from #insurance;

select a.patid,
    p.provider_specialty_primary,
    a.cohort,
    case
    when  p.provider_specialty_primary in
    ('208D00000X', '163WG0000X', '207Q00000X', '207QA0000X', '207QA0505X', '207R00000X',
    '207RA0000X',
    '207RG0300X', '2083P0901X', '261QP2300X', '363LP2300X', '364SF0001X') then 'primary_care'
    when  p.provider_specialty_primary in
    ('207RC0000X', '207RA0001X', '207RC0001X', '207RI0011X', '2080P0202X') then 'cardiology'
    when  p.provider_specialty_primary in
    ('163WE0003X', '207P00000X', '207PE0004X', '207PP0204X', '207PS0010X', '207PT0002X',
    '2080P0204X', '261QE0002X', '364SE0003X') then 'emergency medicine'
    when  p.provider_specialty_primary in ('207RG0100X') then 'GI'
    when  p.provider_specialty_primary in ('207RE0101X', '2080P0205X') then 'endo'
    else 'other'
    end as provider_specialty
into #providers
from #pat_list a
    left join cdm.dbo.encounter  e on a.patid = e.patid
    left join cdm.dbo.provider p
on e.providerid = p.providerid
where  p.provider_specialty_primary in
    ('208D00000X'
    , '163WG0000X'
    , '207Q00000X'
    , '207RC0000X'
    , '207RA0001X'
    , '207RC0001X'
    , '207RI0011X'
    , '2080P0202X'
    , '163WE0003X'
    , '207P00000X'
    , '207PE0004X'
    , '207PP0204X'
    , '207PS0010X'
    , '207PT0002X'
    , '2080P0204X'
    , '261QE0002X'
    , '364SE0003X'
    , '207RE0101X'
    , '2080P0205X'
    , '207RG0100X'
    , '207QA0000X'
    , '207QA0505X'
    , '207R00000X'
    , '207RA0000X'
    , '207RG0300X'
    , '2083P0901X'
    , '261QP2300X'
    , '363LP2300X'
    , '364SF0001X')
  And e.admit_date BETWEEN '2020-09-30'
  AND '2021-09-30'
    ;

--Both cardiology and endocrinology
--CHECK - I'm getting an issue here, but I don't know what it means. I want a list of patients that have both a cardiology and endo provider
select b.patid as patid, 'both_endo_cardio' as both_endo_cardio
into   #cardio_plus_endo
from (select a.patid/*, provider_specialty as provider_specialty_a*/ from #providers a where a.provider_specialty = 'endo') b
    inner join (select c.patid patid /*, provider_specialty as provider_specialty_b*/ from #providers c where c.provider_specialty = 'cardiology') d
 on b.patid =d.patid  ;

  select * into #Table1_pre from
    (
select '1' as order1, 'Total' as label1, 'Total_count' as label2, count(distinct patid) as N, cohort
from #pat_list
group by cohort
union
select '2' as order1, 'Age', Age_category, count(distinct patid) as N, cohort
from #pat_list
group by cohort, Age_category
union
select '2' as order1, 'age', 'Mean age', round(avg(age), 2) as N, cohort
from #pat_list
group by cohort
/*union
select '2' as order1, 'age', 'Median age', round(median(age), 2) as N, cohort
from #pat_list
group by cohort*/
union
select '2' as order1, 'age', 'STD age', round(stdev(age), 2) as N, cohort
from #pat_list
group by cohort
union

select '2' as order1,
    'age',
    'pct_25',
    PERCENTILE_CONT(0.25) WITHIN
GROUP (ORDER BY age asc) OVER (PARTITION BY cohort) "pct_25",
    cohort
from #pat_list
--group by cohort
union
select '2' as order1,
    'age',
    'pct_75',
    PERCENTILE_CONT(0.75) WITHIN
GROUP (ORDER BY age asc) OVER (PARTITION BY cohort)
    "pct_75",
    cohort
from #pat_list
--group by cohort
union
select '2' as order1,
    'age',
    'Median',
    PERCENTILE_CONT(0.5) WITHIN
GROUP (ORDER BY age asc) OVER (PARTITION BY cohort)
    "Median",
    cohort
from #pat_list
union

select '3' as order1, 'sex', SEX_category, count(distinct patid) as N, cohort
from #sex_category
group by cohort, SEX_category

union
select '4' as order1, 'race', RACE_category, count(distinct patid) as N, cohort
from #race_category
group by cohort, race_category
union
select '5' as order1, 'hispanic ethnicity', hispanic_category, count(distinct patid) as N, cohort
from #race_category
group by cohort, hispanic_category
union
select '8' as order1, 'Insurance', insurance_type, count(distinct patid), cohort
from #insurance_type
group by insurance_type, cohort

union
select '8' as order1, 'Insurance', 'has_insurance_info', count(distinct patid), cohort
from #insurance

group by cohort
union
select '6' as order1, 'Smoking', smoking_category, count(distinct a.patid), a.cohort
from #pat_list a
    left join #smoking_category  b on a.patid = b.patid
group by a.cohort, smoking_category
union
select '9' as order1, 'pre-index_days', 'Mean', avg(PRE_INDEX_DAYS) as N, cohort
from #pat_list
group by cohort
/*union
select '9' as order1, 'pre-index_days', 'Median', round(median(PRE_INDEX_DAYS)) as N, cohort
from #pat_list
group by cohort*/
union
select '9' as order1, 'pre-index_days', 'STD', stdev(PRE_INDEX_DAYS) as N, cohort
from #pat_list
group by cohort
union
select '9' as order1,
    'pre-index_days',
    'pct_25',
    PERCENTILE_CONT(0.25) WITHIN
GROUP (ORDER BY PRE_INDEX_DAYS asc) OVER (PARTITION BY cohort)
    "pct_25",
    cohort
from #pat_list
--group by cohort
union
select '9' as order1,
    'pre-index_days',
    'Median',
    PERCENTILE_CONT(0.5) WITHIN
GROUP (ORDER BY PRE_INDEX_DAYS asc) OVER (PARTITION BY cohort)
    "Median",
    cohort
from #pat_list
union
select '9' as order1,
    'pre-index_days',
    'pct_75',
    PERCENTILE_CONT(0.75) WITHIN
GROUP (ORDER BY PRE_INDEX_DAYS asc) OVER (PARTITION BY cohort)
    "pct_75",
    cohort
from #pat_list
--group by cohort
union

select '7' as order1, 'Provider', provider_specialty, count(distinct patid), cohort
from #providers
group by cohort, provider_specialty
union

select '7' as order1, 'Provider', both_endo_cardio, count(distinct patid), cohort
from #cardio_plus_endo
group by cohort, both_endo_cardio
union
select '7' as order1, 'Provider', 'provider_info_available', count(distinct patid), cohort
from #providers
group by cohort
union
select '2' as order1, 'Age', 'has_age_info', count(distinct patid), cohort
from #pat_list
where Age is not null
group by cohort
    ) c;


select N as N_cohort_total, cohort
into #totals
From #Table1_pre
where label1 = 'Total';


select order1,
    a.Cohort,
    label1,
    label2,
    N,
    N_cohort_total,
       IIF((a.label2 in ('pct_75', 'pct_25')
           or a.label2 like ('Mean%')
           or a.label2 like ('Median%')
           or a.label2 like ('STD%')), 0, round(100 * N / N_cohort_total, 2))
    as percentage1
into  #percentages
from #Table1_pre a
    left join #totals b on a.Cohort = b.Cohort
    ;

--Table 1 with percentages - save to file.
select *
from #percentages
order by cohort, order1;

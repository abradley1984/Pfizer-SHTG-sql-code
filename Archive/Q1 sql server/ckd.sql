DECLARE @DATE_END DATE = '2022-05-31';
drop table if exists #age_gender_race_ethnicity
SELECT demo.study_id                                          as study_id,
       sex,
       race,
       hispanic,
       birth_date,
       round(datediff(dd, birth_date, @DATE_END) / 365.25, 2) as age
into #age_gender_race_ethnicity
FROM [VaxHez].live.DEMOGRAPHIC_PITT demo;

drop table if exists #labs;
SELECT [STUDY_ID]
     , [LAB_RESULT_CM_ID]
     , [ENCOUNTERID]
     , [LAB_LOINC]
     , [LAB_ORDER_DATE]
     , cast([RESULT_DATE] as date)   result_date
     , cast([RESULT_NUM] as float)   result_num
     , [RESULT_MODIFIER]
     , [RESULT_UNIT]
     , [NORM_RANGE_LOW]
     , [NORM_RANGE_HIGH]
     , [ABN_IND]
     , [SPECIMEN_SOURCE]
     , cast([SPECIMEN_DATE] as date) specimen_date
into #labs
from [live].[LAB_RESULT_PITT];


drop table if exists #creatinine_most_recent;
select *
into #creatinine_most_recent
from (
         select study_id,
                row_number() OVER (
                    PARTITION BY study_id
                    ORDER BY specimen_date desc
                    )      as              row_num,
                result_num as              creat_result_num,
                result_unit,
                specimen_date,
                lab_loinc,

                round(result_num / 0.9, 2) creat_result_num_male,
                round(result_num / 0.7, 2) creat_result_num_female
         from #labs
         where lab_loinc in ('2160-0', '38483-4')
           and result_num is not null
           AND RESULT_NUM < 30
           AND RESULT_NUM > 0
     ) as all_labs
where row_num = 1;

drop table if exists #creatinine;

select a.study_id,
       a.age,
       a.sex,
       creat_result_num,
       result_unit,
       specimen_date,
       lab_loinc,

       creat_result_num_male,
       creat_result_num_female
into #creatinine
from #age_gender_race_ethnicity a
         left join #creatinine_most_recent b on a.study_id = b.study_id;

select *
from #creatinine;

--eGFR =142* min(standardized Scr/K, 1)α * max(standardized Scr/K, 1)-1.200 *.9938Age *.012 [if female]*/
drop table if exists #egfr;
select *
into #egfr
from (select study_id,

             creat_result_num,
             result_unit,
             age as age,
             sex,
             case
                 when (SEX = 'M' and creat_result_num_male < 1) then 142 *
                                                                     (power(creat_result_num_male, -0.302))
                     *
                                                                     (power(0.9938, round(age, 0)))
                 when sex = 'F' and creat_result_num_female < 1 then 142 * 1.012 *
                                                                     (power(creat_result_num_female, -0.241)) *
                                                                     (1) * power(0.9938, round(age, 0))
                 when (sex = 'M' and creat_result_num_male >= 1) then 142 *
                                                                      (power(creat_result_num_male, -1.2)) *
                                                                      round(power(0.9938, round(age, 0)), 2)
                 when sex = 'F' and creat_result_num_female >= 1 then 142 * 1.012 *
                                                                      (power(creat_result_num_female, -1.2)) *
                                                                      power(0.9938, round(age, 0))
                 else NULL end
                 as egfr_2021
      from #creatinine
     ) as c;
select *
from #egfr;





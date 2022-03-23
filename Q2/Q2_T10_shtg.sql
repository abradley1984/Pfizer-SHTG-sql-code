with pat_list as
    (select * from SHTG_Q2_STEP1_d6 left join SHTG_Q2_STEP3_d1),

     diabetes as ( select patid ,diabetes from SHTG_Q2_STEP1_d5),

     BMI as (select patid,BMI from Q2_LABS_ALL),
     BMI_category as (select patid, BMI,
                             CASE WHEN BMI < 30 then 'BMI under 30'
          WHEN BMI >= 40 THEN 'BMI over 40'
                                  WHEN BMI between 30 and 35 THEN 'BMI 30 to 35'
        WHEN BMI between 35 and 40 THEN 'BMI 35 to 40'
                                 else 'BMI null'
            end as BMI_category ,
     case when BMI>=30 then 1 end as obesity from BMI),
   /*  select avg(BMI), BMI_category, count(patid) from BMI_category
         group  by BMI_category;*/



nash as (select distinct patid, 1 as NASH from pat_list
 INNER JOIN cdm_60_etl.diagnosis como using (patid)
     Where dx in ('K75.81', '571.8', 'K76.0') ),


    combined as( select patid, cohort, BMI_category,diabetes, ascvd, obesity,nash ,v_high_risk,enhanced_risk,
            case when diabetes =1 and nash=1 then 'N and D'
  when (diabetes =0 or diabetes is null) and nash=1 then 'Nash only'
  when (nash =0 or nash is null) and diabetes=1 then 'Diabetes only'
 when (nash =0 or nash is null) and (diabetes =0 or diabetes is null) and obesity =1 then 'Obesity only'
else 'None'
end
as t10_category
from  pat_list
         left join BMI_category using(patid)
left join nash using(patid)
left join diabetes using(patid))

select count (patid ), t10_category, BMI_category,v_high_risk,enhanced_risk, ascvd from combined group by t10_category, v_high_risk,enhanced_risk,  ascvd,BMI_category  ;
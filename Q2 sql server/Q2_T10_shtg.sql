/* T10 - only for Q2
   This table is categorizing patients into Obesity, NASH and Diabetes groups, looking at some labs */

select * into #pat_list from
    (select * from foo.dbo.SHTG_Q2_STEP3
        where cohort is not null) as SQ;

    /* diabetes as ( select patid ,diabetes from foo.dbo.SHTG_Q2_STEP3_d2),*/

     select * into #BMI from (select patid,BMI from foo.dbo.Q2_LABS_ALL) as pB;
     select * into #BMI_category from (select patid, BMI,
                             CASE WHEN BMI < 30 then 'BMI under 30'
          WHEN BMI >= 40 THEN 'BMI over 40'
                                  WHEN BMI between 30 and 35 THEN 'BMI 30 to 35'
        WHEN BMI between 35 and 40 THEN 'BMI 35 to 40'
                                 else 'BMI null'
            end as BMI_category ,
     case when BMI>=30 then 1 end as obesity from #BMI) as B;
   /*  select avg(BMI), BMI_category, count(patid) from BMI_category
         group  by BMI_category;*/



select * into #nash from (select distinct patid, 1 as NASH from #pat_list a
 INNER JOIN cdm.dbo.diagnosis como on a.patid=como.patid
     Where dx in ('K75.81', '571.8', 'K76.0') ) as pN;


    select * into #combined from( select a.patid, cohort, BMI_category,diabetes, ascvd, obesity,nash ,v_high_risk,enhanced_risk,
            case when diabetes =1 and nash=1 then 'N and D'
  when (diabetes =0 or diabetes is null) and nash=1 then 'Nash only'
  when (nash =0 or nash is null) and diabetes=1 then 'Diabetes only'
 when (nash =0 or nash is null) and (diabetes =0 or diabetes is null) and obesity =1 then 'Obesity only'
else 'None'
end
as t10_category
from  #pat_list a
         left join #BMI_category b on a.patid=b.patid
left join #nash  c on a.patid=c.patid
/*left join diabetes using(patid)*/) as abc;

select count (patid ), t10_category, BMI_category,v_high_risk,enhanced_risk, ascvd from #combined group by t10_category, v_high_risk,enhanced_risk,  ascvd,BMI_category  ;
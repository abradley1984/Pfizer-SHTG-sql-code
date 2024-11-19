select * from cdm_60_etl.lab_result_cm
select * from cdm_60_prod.diagnosis
select * from cdm_60_prod.encounter
    select count(*) from SHTG_Q2_STEP1_D5_PRE_EXC

last_encounter as (select patid, admit_date as last_admit_date
                        from (select row_number() OVER (
                            PARTITION BY encounter.patid
                            ORDER BY encounter.admit_date desc
                            )                                row_num,
                                     encounter.admit_date as admit_date,
                                     encounter.patid      as patid
                              from pat_list p
                                       left join cdm_60_prod.encounter encounter on p.patid = encounter.patid)
                        where  admit_date <=TO_DATE('09/30/2021', 'MM/DD/YYYY')
                      and row_num = 1
--SHTG_Pfizer Q2
-- Add in data needed for cohorts (Various lab and dx criteria based on AHA guidelines), and get cohort groupings.
-- Run time:
--create table SHTG_Q2_STEP3 as
--WITH
     select * into #PAT_LIST from
     (SELECT * FROM foo.dbo.shtg_Q2_STEP1
     where age>=18 and pre_index_days>=180) as id;

     select * into #labs_all from (select * from Q2_labs_all) as [Q2la*];
     --Risk status
     --Recent ACS (12 months)
     select * into #recent_ACS from (select pats.patid,


                           1 as recent_ACS
                    from #pat_list pats
                             INNER JOIN cdm.dbo.diagnosis   como on pats.patid=como.patid
                    WHERE dx in ('413.9', --dealing with MI separately
                                 'I20.9',--Angina codes
                        /*'I23.7',*/
                                 'I25.111',--
                                 'I25.118',
                                 'I25.119',
                                 'I25.701',
                                 'I25.708',
                                 'I25.709',
                                 'I25.738',
                                 'I25.751',
                                 'I25.791',
                                 '411.1',
                                 '411.81',
                                 '411.89',
                                 '413.0',
                                 '413.1',
                                 'I20.0',
                                 'I20.1',
                                 'I20.8',
                                 'I24.0',
                                 'I24.8',
                                 'I24.9',
                                 'I25.110',
                                 'I25.700',
                                 'I25.710',
                                 'I25.720',
                                 'I25.730',
                                 'I25.750',
                                 'I25.760',
                                 'I25.790',
                                 '414.8',
                                 '414.9',
                                 'I25.5',
                                 'I25.6',
                                 'I25.89',
                                 'I25.9'
                        /*'410.11',
                        '410.2',
                        '410.3',
                        '410.4',
                        '410.50',
                        '410.51',
                        '410.60',
                        '410.61',
                        '410.62',
                        '410.70',
                        '410.71',
                        '410.72',
                        '410.81',
                        '410.90',
                        '410.91',
                        '410.92',
                        '411.0',
                        '412',
                        'I21.01',
                        'I21.02',
                        'I21.09',
                        'I21.11',
                        'I21.19',
                        'I21.21',
                        'I21.29',
                        'I21.3',
                        'I21.4',
                        'I21.9',
                        'I21.A1',
                        'I21.A9',*//*
                            'I22.0',
                            'I22.1',
                            'I22.2',
                            'I22.8',
                            'I22.9',
                            'I23.0',
                            'I23.3',
                            'I23.6',
                            'I23.8',
                            'I24.1',
                            'I25.2',*/
                        )
                      and como.admit_date BETWEEN '2020-09-30' AND '2021-09-30'
                    group by pats.patid
     ) as prA;
     --one ASCVD event - MI, stroke, PCI
     select * into #MI from (
         select distinct pats.patid,

                          1 as MI


         from #pat_list pats
                  INNER JOIN cdm.dbo.diagnosis   como on pats.patid=como.patid
         where (Como.dx like '410%' -- MI

             OR Como.dx = '411.0' -- MI

             OR Como.dx = '411.81' -- MI

             OR Como.dx = '412' -- MI

             OR Como.dx like 'I21%' -- MI

             OR Como.dx like 'I22%' -- MI

             OR Como.dx like '123%' -- MI




             OR Como.dx = 'I25.2' -- MI)

                   )
         group by pats.patid
     ) as pM;
     select * into #stroke from (
         select pats.patid,

                  1 as stroke--,


         from #pat_list pats
                  INNER JOIN cdm.dbo.diagnosis   como on pats.patid=como.patid
         where (
                       Como.dx like '433%' -- STROKE

                       OR Como.dx like '434%' -- STROKE

                       OR Como.dx = '997.02' -- STROKE

                       OR Como.dx like 'I63%' -- STROKE


              OR Como.dx like 'I97.81%' -- STROKE
             OR Como.dx like 'I97.82%' -- STROKE

                   )
         group by pats.patid
     ) as ps;
     select * into #PAD from (
         select distinct pats.patid,


                         1 as PAD


         from #pat_list pats
                  INNER JOIN cdm.dbo.diagnosis   como on pats.patid=como.patid
         where (
                       dx in ('440.20',
                              '440.21',
                              '440.22',
                              '440.23',
                              '440.24',
                              '440.29',
                              '440.30',
                              '440.31',
                              '440.32',
                              '440.4',
                              'I70.0',
                              'I70.1',
                              'I70.201',
                              'I70.202',
                              'I70.203',
                              'I70.208',
                              'I70.209',
                              'I70.21',
                              'I70.22',
                              'I70.232',
                              'I70.24',
                              'I70.25',
                              'I70.26',
                              'I70.261',
                              'I70.262',
                              'I70.263',
                              'I70.268',
                              'I70.269',
                              'I70.291',
                              'I70.292',
                              'I70.293',
                              'I70.298',
                              'I70.299',
                              'I70.3',
                              'I70.4',
                              'I70.5',
                              'I70.8',
                              'I70.90',
                              'I70.91',
                              'I70.92') -- 'PAD'

                   )
     ) as pP
        ;
     select * into #multiple_stroke from (
         select patid, IIF(encounter_count > 1, 1, 0) as multiple_stroke
         from (select e.patid,
                      count(e.encounterid)                                                       as encounter_count,
                      max(e.admit_date) as max_adm_date,
                      min(e.admit_date) as min_adm_date,
                      (datediff(dd,max(e.admit_date), min(e.admit_date)) / 10) * 10 as gap
               from cdm.dbo.encounter e
                        join cdm.dbo.diagnosis Como on (e.patid = Como.patid and  e.encounterid = Como.encounterid)

               where e.patid in (Select patid from #pat_list a)
                 and (
                       Como.dx like '433%' -- STROKE

                       OR Como.dx like '434%' -- STROKE

                       OR Como.dx = '997.02' -- STROKE

                       OR Como.dx like 'I63%' -- STROKE


                   )
                 and e.enc_Type in ('EI', 'IP')
                 -- and DRG in ('061', '062', '063', '064', '065', '066')
               group by e.patid
               having count(e.encounterid) > 1) as eC

         where gap
                   > 30) as pms;
     select * into #multiple_MI from (
         select patid, gap, IIF(encounter_count > 1, 1, 0) as multiple_MI
         from (select patid,
                      count(encounterid)                                           as encounter_count,
                      max(diagnosis.admit_date) as max_adm_date,
                      min(diagnosis.admit_date) as min_adm_date,
                      datediff(dd,max(diagnosis.admit_date), min(diagnosis.admit_date)) as gap
               from cdm.dbo.diagnosis


               where diagnosis.patid in (Select patid from #pat_list a)
                   and diagnosis.enc_Type in ('EI', 'IP')
                   and (((dx like '410%' -- MI

                       OR dx like 'I21%')-- MI)


                       and pdx = 'P')
                  OR dx like 'I22%') -- MI)

               group by patid
               having count(encounterid) > 1) as d


         where gap
                   > 30) as pgmM;
     select * into #multiple_PCI from (

 select patid, PCI_gap, IIF(encounter_count > 1, 1, 0) as multiple_PCI
         from (select a.patid,
                      count(encounterid)                                           as encounter_count,

                -- 'PCI'                             as Comorbidity_name,
               -- 1 as PCI--,
            -- ,   max(admit_date),
                 min(admit_date) as min_adm_date,
                 --max(admit_date) - min(admit_date) as PCI_gap
				 datediff(dd,max(b.admit_date), min(b.admit_date)) as PCI_gap
         from #pat_list a
                  left join cdm.dbo.procedures b on a.patid=b.patid
         where PX in ('92920', '92921', '92924', '92925', '92928', '92929', '92933', '92934', '92937', '92938', '92941',
                      '92943', '92944', '92973', '92974', '92975', '92978', '92979', '93571', '93572', 'C9600', 'C9601',
                      'C9602', 'C9603', 'C9604', 'C9605', 'C9606', 'C9607', 'C9608')
         group by a.patid) as ab
         where PCI_gap>30) as pPgmP;
     select * into #CKD from (select patid, IIF(egfr_2021 < 60, 1, 0) as CKD
             from #labs_all) as pC
        ;


     --hypercholesterolemia or max_LDL>190

     select * into #hypercholesterolemia from (select distinct pats.patid,
                                                               IIF((dx = 'E78.01' or max_ldl_above_190 = 1), 1, 0) as hypercholesterolemia

                              from #pat_list pats
                                       left JOIN cdm.dbo.diagnosis   como on pats.patid=como.patid
                              where (
                                  dx = 'E78.01' --'familial hypercholesterolemia'
                                  )
                                 or max_ldl_above_190 = 1) as ph;
     select * into #PCI from (
         select a.patid,

                -- 'PCI'                             as Comorbidity_name,
                1 as PCI--,
             /*    max(admit_date),
                 min(admit_date),
                 max(admit_date) - min(admit_date) as PCI_gap*/
         from #pat_list a
                  left join cdm.dbo.procedures b on a.patid=b.patid
         where PX in ('92920', '92921', '92924', '92925', '92928', '92929', '92933', '92934', '92937', '92938', '92941',
                      '92943', '92944', '92973', '92974', '92975', '92978', '92979', '93571', '93572', 'C9600', 'C9601',
                      'C9602', 'C9603', 'C9604', 'C9605', 'C9606', 'C9607', 'C9608')
         group by a.patid) as pP;

     select * into #hypertension from (select distinct pats.patid, IIF(dx = 'I10', 1, 0) as hypertension

                      from #pat_list pats
                               INNER JOIN cdm.dbo.diagnosis   como on pats.patid=como.patid
                      where (
                                Como.dx = 'I10' -- hypertension

                                )) as ph;

     --current smoker
     select * into #smoking from (
         select patid, IIF(smoking in ('01', '02', '05', '07', '08'), 1, 0) as current_smoker
         from (
                  select a.patid,
                         row_number() OVER (
                             PARTITION BY a.patid
                             ORDER BY b.measure_date desc
                             )            row_num,
                         b.smoking as smoking
                  from #pat_list a
                           left join cdm.dbo.vital b on a.patid=b.patid
                  WHERE b.smoking IS NOT NULL
                    AND not b.smoking in ('NI', 'OT', 'UN')) as prns
         where row_num = 1) as pcs
        ;
     select * into #congestive_HF from (
         select distinct pats.patid,

                         --   'congestive_HF' as Comorbidity_name,
                         1 as congestive_HF

         from #pat_list pats
                  INNER JOIN cdm.dbo.diagnosis   como on pats.patid=como.patid
         where Como.dx in ('I50.20',
                           'I50.21',
                           'I50.22',
                           'I50.23',
                           'I50.3',
                           'I50.30',
                           'I50.31',
                           'I50.32',
                           'I50.33',
                           'I50.4',
                           'I50.40',
                           'I50.41',
                           'I50.42',
                           'I50.43',
                           'I50.8'
             )
     ) as pcH;

     select * into #TIA_IHD from (select distinct pats.patid,

                                 --   'congestive_HF' as Comorbidity_name,
                                 1 as TIA_IHD

                 from #pat_list pats
                          INNER JOIN cdm.dbo.diagnosis   como on pats.patid=como.patid
                 where Como.dx like 'G45%' -- TIA
                    OR Como.dx like '435%' -- TIA

                    OR Como.dx like 'I20%' -- IHD

                    OR Como.dx like 'I21%' -- IHD

                    OR Como.dx like 'I22%' -- IHD

                    OR Como.dx like 'I23%' -- IHD

                    OR Como.dx like 'I24%' -- IHD

                    OR Como.dx like 'I25%' -- IHD
     ) as pTI;
     select * into #LDL_all from (select lab_result_cm.patid,
                        row_number() OVER (
                            PARTITION BY lab_result_cm.patid
                            ORDER BY lab_result_cm.result_date desc
                            )                     row_num,
                        lab_result_cm.result_num  LDL_result_num,
                        lab_result_cm.result_unit result_unit,
                        lab_result_cm.result_date

                 FROM cdm.dbo.lab_result_cm
                 WHERE -- WHERE lab_result_cm.result_date BETWEEN '2020-09-30' AND '2021-09-30'

                     lab_result_cm.lab_loinc in ('13457-7', '18262-6', '2089-1')
                   --and lab_result_cm.patid in pat_list
                   and lab_result_cm.result_num is not null
                   --  and lab_result_cm.result_num >= 100
                   and patid in (select patid from #pat_list a)
        AND not lab_result_cm.result_unit in ('mg/d', 'g/dL', 'mL/min/{1.73_m2}', 'mL/min') --Excluding rare weird units   --AND lab_result_cm.result_num < 1000

     ) as lrc;
     select * into #LDL_most_recent_high_100 from (select patid,
                                         1              as first_LDL_above_100,
                                         result_date    as first_result_date,
                                         LDL_result_num as first_result_num
                                  from #LDL_all
                                  where row_num = 1
                                    and LDL_result_num > 100
     ) as La
        ;
     select * into #LDL_most_recent_high_160 from (select patid,
                                         1              as first_LDL_above_160,
                                         result_date    as first_result_date,
                                         LDL_result_num as first_result_num
                                  from
                                       #LDL_all
                                  where row_num = 1
                                    and LDL_result_num > 160
     ) as La
        ;

     --second most recent, over 3 months since first
     select * into #LDL_second_most_recent_100 from (select a.patid,
                                           first_result_date,
                                           first_result_num,
                                           LDL_result_num as second_result_num,
                                           row_number() OVER (
                                               PARTITION BY a.patid
                                               ORDER BY result_date desc
                                               )             row_num,
                                           result_date
                                    from #LDL_most_recent_high_100 a
                                             left join #LDL_all LDL_all on a.patid=LDL_all.patid
                                    where not row_num = 1
                                      and datediff(dd, LDL_all.result_date, first_result_date) > 90 --over 3 months since first
     ) as aLa
         select * into #LDL_second_most_recent_160 from (select a.patid,
                                           first_result_date,
                                           first_result_num,
                                           LDL_result_num as second_result_num,
                                           row_number() OVER (
                                               PARTITION BY a.patid
                                               ORDER BY result_date desc
                                               )             row_num,
                                           result_date
                                    from #LDL_most_recent_high_160 a
                                             left join #LDL_all LDL_all  on a.patid=LDL_all.patid
                                    where not row_num = 1
                                      and datediff(dd, LDL_all.result_date, first_result_date) > 90 --over 3 months since first
     ) as aLa;
     select * into #statins from (
         select distinct a.patid, 1 as Statin_ezetimibe
         from #pat_list a
                  left join cdm.dbo.prescribing b on a.patid=b.patid

         where /*prescribing.rx_order_Date BETWEEN '2020-09-30' AND '2021-09-30'
             and*/ rxnorm_cui in
                   ('83366', '153165', '617312', '617314', '83366', '83367', '153165', '617310', '617318', '83366',
                    '83367', '153165', '617311', '617320', '83366', '83367', '153165', '259255', '262095', '83366',
                    '83367', '153165', '617311', '617320', '83366', '83367', '153165', '259255', '262095', '83366',
                    '83367', '153165', '617310', '617318', '83366', '83367', '153165', '617312', '617314', '83367',
                    '215567', '309123', '596723', '215567', '221072', '309124', '596723', '215567', '221072', '313936',
                    '596723', '215567', '221072', '309125', '596723', '153303', '215567', '221072', '309124', '596723',
                    '215567', '215567', '221072', '284424', '309125', '596723', '215567', '153302', '215567', '221072',
                    '309123', '596723', '215567', '215567', '221072', '261244', '313936', '596723', '215567', '221072',
                    '41127', '103918', '151972', '310404', '41127', '72875', '103919', '151972', '310405', '41127',
                    '72875', '151972', '360507', '687048', '284764', '41127', '72875', '103919', '151972', '310405',
                    '41127', '72875', '103918', '151972', '310404', '41127', '72875', '151972', '360507', '687048',
                    '72875', '433848', '541841', '997004', '1233888', '352420', '6472', '224938', '352420', '433849',
                    '541841', '997006', '1233869', '1233878', '352420', '6472', '224938', '352420', '359731', '541841',
                    '997007', '1233870', '1233883', '352420', '6472', '224938', '352420', '359732', '541841', '884383',
                    '1233871', '352420', '6472', '197903', '224938', '209013', '6472', '197904', '206257', '224938',
                    '6472', '197905', '206258', '224938', '6472', '197904', '206257', '224938', '352420', '541841',
                    '352420', '6472', '197903', '209013', '224938', '352420', '541841', '352420', '6472', '197905',
                    '206258', '224938', '352420', '541841', '352420', '6472', '352420', '433848', '6472', '352420',
                    '433849', '6472', '352420', '359731', '6472', '352420', '359732', '6472', '433848', '541841',
                    '997004', '6472', '433849', '541841', '997006', '6472', '359731', '541841', '997007', '6472',
                    '359732', '541841', '884383', '6472', '224938', '352420', '861634', '861640', '861648', '861650',
                    '861612', '861634', '861640', '861652', '861654', '861612', '861634', '861640', '861643', '861646',
                    '2001255', '861612', '861634', '861640', '861648', '861650', '2001255', '861612', '861634',
                    '861640',
                    '861652', '861654', '2001255', '861612', '861634', '861640', '861643', '861646', '861612', '861634',
                    '2001255', '2001266', '2001268', '861634', '2001252', '2001254', '2001255', '2001260', '861634',
                    '2001252', '2001255', '2001262', '2001264', '2001252', '2001268', '2001266', '2001255', '2001252',
                    '861634', '2001252', '2001254', '2001255', '2001260', '861634', '2001252', '2001255', '2001262',
                    '2001264', '861634', '1944734', '861634', '1944734', '861634', '1944734', '861634', '904483',
                    '42463',
                    '203144', '203333', '904458', '904460', '42463', '203144', '203333', '904467', '904469', '42463',
                    '203144', '203333', '904475', '904477', '42463', '203144', '203333', '904481', '904483', '42463',
                    '203144', '203333', '904458', '904460', '42463', '203144', '203333', '904467', '904469', '42463',
                    '203144', '203333', '904475', '904477', '42463', '203144', '203333', '904481', '301542', '320864',
                    '323828', '859747', '859749', '301542', '320864', '323828', '859751', '859753', '301542', '320864',
                    '323828', '859419', '859421', '301542', '320864', '323828', '859424', '859426', '301542', '320864',
                    '323828', '859424', '859426', '2167558', '2167558', '301542', '320864', '323828', '859747',
                    '859749',
                    '2167558', '2167558', '301542', '320864', '323828', '859751', '859753', '2167558', '2167558',
                    '301542', '320864', '323828', '859419', '859421', '2167558', '2167558', '301542', '320864',
                    '323828',
                    '2167558', '2167573', '2167575', '2167558', '301542', '320864', '323828', '2167557', '2167558',
                    '2167563', '2167558', '301542', '320864', '323828', '2167558', '2167565', '2167567', '2167558',
                    '301542', '320864', '323828', '2167558', '2167569', '2167571', '2167558', '301542', '323828',
                    '2167558', '2167573', '2167575', '301542', '323828', '2167557', '2167558', '2167563', '301542',
                    '323828', '2167558', '2167565', '2167567', '301542', '323828', '2167558', '2167569', '2167571',
                    '213319', '1944257', '1944257', '1944264', '1944266', '36567', '1790679', '1944257', '1944262',
                    '36567', '1944257', '1944264', '1944266', '36567', '196503', '1790679', '1944257', '1944262',
                    '36567',
                    '196503', '36567', '152923', '196503', '198211', '36567', '196503', '200345', '213319', '36567',
                    '196503', '208220', '312962', '36567', '104490', '196503', '314231', '36567', '104491', '196503',
                    '312961', '36567', '196503', '208220', '312962', '1944257', '36567', '104490', '196503', '314231',
                    '1944257', '36567', '104491', '196503', '312961', '1944257', '36567', '152923', '196503', '198211',
                    '1944257', '36567', '196503', '200345', '1312410', '1312417', '1312424', '36567', '593411',
                    '621590',
                    '1312423', '1312429', '1372754', '1189803', '1312410', '1312417', '1312424', '36567', '593411',
                    '621590', '1312409', '1372754', '1189805', '1189809', '1189822', '1312410', '1312415', '1312417',
                    '1312424', '36567', '593411', '621590', '1312416', '1372754', '1189805', '1189809', '1189822',
                    '1312410', '1312417', '1312422', '1312424', '36567', '593411', '621590', '1312423', '1372754',
                    '1189805', '1189809', '1189822', '1312410', '1312417', '1312424', '1312429', '1312424', '36567',
                    '593411', '621590', '1189821', '1189827', '1372754', '1189803', '1312410', '1312417', '1312424',
                    '36567', '593411', '621590', '1189804', '1372754', '1189805', '1189809', '1189818', '1189822',
                    '1312410', '1312417', '1312424', '36567', '593411', '621590', '1189808', '1372754', '1189805',
                    '1189809', '1189814', '1189822', '1312410', '1312417', '1312424', '36567', '593411', '621590',
                    '1189821', '1372754', '1189805', '1189809', '1189822', '1189827', '1312410', '1312417', '1312424',
                    '36567', '593411', '621590', '1312409', '1312415', '1372754', '1189803', '1312410', '1312417',
                    '1312424', '36567', '593411', '621590', '1312416', '1312422', '1372754', '1189803', '36567',
                    '593411',
                    '621590', '1189804', '1189818', '1372754', '1189803', '1312410', '1312417', '1312424', '36567',
                    '593411', '621590', '1189808', '1189814', '1372754', '1189803', '1312410', '1312417', '327008',
                    '644112', '791846', '352387', '757733', '757745', '6472', '7393', '327008', '582042', '791831',
                    '791835', '791838', '791839', '791843', '6472', '7393', '327008', '582043', '791831', '791835',
                    '791839', '791842', '791843', '6472', '7393', '327008', '582041', '791831', '791834', '791835',
                    '791839', '791843', '6472', '7393', '327008', '644112', '791831', '791835', '791839', '791843',
                    '791846', '6472', '7393', '327008', '582042', '791838', '352387', '757733', '757745', '6472',
                    '7393',
                    '327008', '582043', '791842', '352387', '757733', '757745', '757748', '6472', '7393', '327008',
                    '582041', '791834', '352387', '757733', '757736', '757745', '6472', '7393', '36567', '761907',
                    '1372731', '763225', '763228', '763229', '763233', '999936', '999943', '7393', '36567', '999935',
                    '999939', '1372731', '803516', '7393', '36567', '999942', '999946', '1372731', '803516', '7393',
                    '36567', '999935', '1372731', '763225', '763229', '763233', '999936', '999939', '999943', '7393',
                    '36567', '999942', '1372731', '763225', '763229', '763233', '999936', '999943', '999946', '7393',
                    '36567', '761909', '763232', '1372731', '803516', '7393', '36567', '762970', '763236', '1372731',
                    '803516', '7393', '36567', '761907', '763228', '1372731', '803516', '7393', '36567', '761909',
                    '1372731', '763225', '763229', '763232', '763233', '999936', '999943', '7393', '36567', '762970',
                    '1372731', '763225', '763229', '763233', '763236', '999936', '999943', '7393', '1422085', '83366',
                    '83367', '341248', '1422086', '1422087', '1422092', '1422085', '83366', '83367', '341248',
                    '1422087',
                    '1422093', '1422095', '1422085', '83366', '83367', '341248', '1422087', '1422096', '1422098',
                    '1422085', '83366', '83367', '341248', '1422087', '1422099', '1422101', '2536055', '2536060',
                    '301542', '323828', '341248', '2535745', '2535748', '2536055', '2536062', '301542', '323828',
                    '341248', '2535748', '2535749', '2536055', '2536064', '301542', '323828', '341248', '2535747',
                    '2535748', '2536055', '2536066', '301542', '323828', '341248', '2535748', '2535750', '1245449',
                    '36567', '341248', '476345', '484211', '495215', '1245420', '36567', '341248', '476349', '484211',
                    '495215', '1245430', '36567', '341248', '476350', '484211', '495215', '1245441', '36567', '341248',
                    '476351', '484211', '495215', '1191', '1191', '215436', '42463', '6574', '1897', '1191', '215436',
                    '904669', '904668', '42463', '6574', '1897', '1191', '215436', '904661', '904660', '42463', '6574',
                    '1897', '1897', '6574', '42463', '215436', '1191', '1897', '6574', '42463', '904664', '904665',
                    '215436', '1191', '1897', '6574', '42463', '215436', '904483', '904481', '203333', '203144',
                    '42463',
                    '904477', '904475', '203333', '203144', '42463', '904469', '904467', '203333', '203144', '42463',
                    '904460', '904458', '203333', '42463', '203144', '17767', '83366', '83367', '104416', '404773',
                    '404914', '597977', '750227', '17767', '83366', '83367', '104416', '404773', '404914', '597980',
                    '750231', '17767', '83366', '83367', '104416', '404773', '404914', '597987', '750199', '17767',
                    '83366', '83367', '104416', '404773', '404914', '597967', '750203', '17767', '83366', '83367',
                    '104416', '404773', '404914', '597971', '750223', '17767', '83366', '83367', '104416', '404773',
                    '404914', '597974', '750219', '83366', '83367', '617314', '617312', '153165')
            OR rxnorm_cui IN
               ('83367', '83366', '617318', '617310', '153165', '83367', '83366', '341248', '1422087', '1422092',
                '1422085', '83366', '83367', '341248', '1422087', '1422093', '83367', '83366', '1422086', '1422085',
                '1422101', '1422099', '1422087', '341248', '83367', '83366', '1422085', '1422098', '1422096', '1422087',
                '341248', '83367', '83366', '1422085', '1422095', '17767', '83366', '83367', '104416', '404773',
                '404914', '597977', '750227', '750196', '750200', '750204', '750208', '750212', '750216', '750220',
                '750224', '750228', '750232', '750236', '17767', '83366', '83367', '104416', '404773', '404914',
                '597987', '750199', '750196', '750200', '750204', '750208', '750212', '750216', '750220', '750224',
                '750228', '750232', '750236', '17767', '83366', '83367', '104416', '404773', '404914', '597980',
                '750231', '750196', '750200', '750204', '750208', '750212', '750216', '750220', '750224', '750228',
                '750232', '750236', '17767', '83366', '83367', '104416', '404773', '404914', '597967', '750203',
                '750196', '750200', '750204', '750208', '750212', '750216', '750220', '750224', '750228', '750232',
                '750236', '17767', '83366', '83367', '104416', '404773', '404914', '597984', '750235', '750196',
                '750200', '750204', '750208', '750212', '750216', '750220', '750224', '750228', '750232', '750236',
                '17767', '83366', '83367', '104416', '404773', '404914', '597990', '750207', '750196', '750200',
                '750204', '750208', '750212', '750216', '750220', '750224', '750228', '750232', '750236', '17767',
                '83366', '83367', '104416', '404011', '404773', '404914', '750239', '750196', '750200', '750204',
                '750208', '750212', '750216', '750220', '750224', '750228', '750232', '750236', '17767', '83366',
                '83367', '104416', '404013', '404773', '404914', '750211', '750196', '750200', '750204', '750208',
                '750212', '750216', '750220', '750224', '750228', '750232', '750236', '17767', '83366', '83367',
                '104416', '404773', '404914', '597971', '750196', '750200', '750204', '750208', '750212', '750216',
                '750220', '750223', '750224', '750228', '750232', '750236', '17767', '83366', '83367', '104416',
                '404773', '404914', '597974', '750196', '750200', '750204', '750208', '750212', '750216', '750219',
                '750220', '750224', '750228', '750232', '750236', '17767', '83366', '83367', '104416', '404773',
                '404914', '597993', '750196', '750200', '750204', '750208', '750212', '750215', '750216', '750220',
                '750224', '750228', '750232', '750236', '17767', '83366', '83367', '104416', '404773', '404914',
                '597977', '750227', '17767', '83366', '83367', '104416', '404773', '404914', '597980', '750231',
                '17767', '83366', '83367', '104416', '404773', '404914', '597984', '750235', '17767', '83366', '83367',
                '104416', '404011', '404773', '404914', '750239', '17767', '83366', '83367', '104416', '404773',
                '404914', '597987', '750199', '17767', '83366', '83367', '104416', '404773', '404914', '597967',
                '750203', '17767', '83366', '83367', '104416', '404773', '404914', '597990', '750207', '876514',
                '17767', '83366', '83367', '104416', '404013', '404773', '404914', '750211', '17767', '83366', '83367',
                '104416', '404773', '404914', '597971', '750223', '17767', '83366', '83367', '104416', '404773',
                '404914', '597974', '750219', '17767', '83366', '83367', '104416', '404773', '404914', '597993',
                '750215')
            --ezetimibe
            or rxnorm_cui IN
               ('1422085', '83366', '83367', '341248', '1422086', '1422087', '1422092', '1422085', '83366', '83367',
                '341248', '1422087', '1422093', '1422095', '1422085', '83366', '83367', '341248', '1422087', '1422096',
                '1422098', '1422085', '83366', '83367', '341248', '1422087', '1422099', '1422101', '2536055', '2536060',
                '301542', '323828', '341248', '2535745', '2535748', '2536055', '2536062', '301542', '323828', '341248',
                '2535748', '2535749', '2536055', '2536064', '301542', '323828', '341248', '2535747', '2535748',
                '2536055', '2536066', '301542', '323828', '341248', '2535748', '2535750', '1245449', '36567', '341248',
                '476345', '484211', '495215', '1245420', '36567', '341248', '476349', '484211', '495215', '1245430',
                '36567', '341248', '476350', '484211', '495215', '1245441', '36567', '341248', '476351', '484211',
                '495215',
                '2282403',
                '2283229',
                '2283231',
                '2283236',
                '2283230',
                '341248',
                '349556',
                '352304',
                '353099')

         group by a.patid
     ) as pSe;

     select * into #LDL_persistent_high_100 from (select a.patid, 1 as LDL_persistent_high_100
                                 from #LDL_second_most_recent_100 a
                                          left join #statins b on a.patid=b.patid
                                 where row_num = 1
                                   and second_result_num > 100
                                   and Statin_Ezetimibe = 1) as p;
     select * into #LDL_persistent_high_160 from (select a.patid, 1 as LDL_persistent_high_160
                                 from #LDL_second_most_recent_160 a

                                 where row_num = 1
                                   and second_result_num > 160
     ) as p;

     select * into #v_high_risk_combined from (select  a.patid                  as patid,
                                                       IIF(LDL_persistent_high_100 = 1, 1, 0) as LDL_persistent_high_100,
                                                       IIF(recent_ACS = 1, 1, 0)              as recent_ACS,
                                                       IIF(PAD = 1, 1, 0)                     as PAD,
                                                       IIF(MI = 1, 1, 0)                      as MI,
                                                       IIF(stroke = 1, 1, 0)                  as stroke,
                                                       IIF(multiple_MI = 1, 1, 0)             as multiple_MI,
                                                       IIF(multiple_stroke = 1, 1, 0)         as multiple_stroke,
                                                       IIF(multiple_PCI = 1, 1, 0)            as multiple_PCI,
                                                       IIF((age >= 65), 1, 0)                 as age_over_65,
                                                       IIF(hypercholesterolemia = 1, 1, 0)    as hypercholesterolemia,
                                                       IIF(PCI = 1, 1, 0)                     as PCI,

                                     coalesce(diabetes, 0)                                    as diabetes,
                                                       IIF(hypertension = 1, 1, 0)            as hypertension,
                                                       IIF(CKD = 1, 1, 0)                     as CKD,

                                                       IIF(current_smoker = 1, 1, 0)          as current_smoker,

                                     --persistently elevated LDL-C
                                                       IIF(congestive_HF = 1, 1, 0)           as congestive_HF


                              from #pat_list a
                                       left join #LDL_persistent_high_100 b on a.patid=b.patid
                                       left join #stroke c on a.patid=c.patid
                                       left join #MI d on a.patid=d.patid
                                       left join #recent_ACS e on a.patid=e.patid
                                       left join #hypercholesterolemia f on a.patid=f.patid
                                       left join #PCI g on a.patid=g.patid
                                       left join #CKD h on a.patid=h.patid
                                       left join #hypertension i on a.patid=i.patid
                                       left join #PAD j on a.patid=j.patid
                                       left join #congestive_HF k on a.patid=k.patid

                                       left join #multiple_stroke l on a.patid=l.patid
                                       left join #multiple_MI m on a.patid=m.patid
                                            left join #multiple_PCI n on a.patid=n.patid


                                       left join #smoking p on a.patid=p.patid

     ) as abcdefghijklmnp;

     select * into #v_high_risk_category from (select recent_ACS + MI + stroke + multiple_stroke+ multiple_MI   + PAD as major_ascvd,
                                     case
                                         when recent_ACS + MI + stroke + multiple_MI + multiple_stroke + PAD > 1
                                             then 'v high risk'
                                         when (recent_ACS + MI + stroke + multiple_MI + multiple_stroke + PAD  = 1) and
                                              age_over_65 + hypercholesterolemia  + PCI+ multiple_PCI + diabetes + hypertension + CKD +
                                              current_smoker + congestive_HF + LDL_persistent_high_100 > 1
                                             then 'v high risk'
                                         else
                                             'not v high risk' end                                  as v_high_risk,
                                    v.*


                              from #v_high_risk_combined v) as [mavhrv.*];


     select * into #add_categories from (select a.patid,
                               case
                                   when LDL_result_num < 70
                                       then 'LDL_low'

                                   when LDL_result_num >= 70
                                       then 'LDL_high'
                                   when LDL_result_num < 0
                                       then 'LDL_below_0'
                                   else 'other'
                                   end                                      as LDL_category,
                               case
                                   when TG_result_num < 150 then 'TG_under_150'
                                   when TG_result_num BETWEEN 150 and 500
                                       then 'TG_150_500'
                                   when TG_result_num BETWEEN 500 and 880
                                       then 'TG_500_880'
                                   when TG_result_num BETWEEN 880 and 2000
                                       then 'TG_880_2000'
                                   when TG_result_num > 2000
                                       then 'TG_over_2000'

                                   else 'other'
                                   end                                      as TG_category,
                               case
                                   when LDL_result_num < 70
                                       then 'LDL_under_70'

                                   when LDL_result_num between 70 and 100
                                       then 'LDL_70_to_100'

                                   when LDL_result_num between 100 and 130
                                       then 'LDL_100_to_130'
                                   when LDL_result_num between 130 and 160
                                       then 'LDL_130_to_160'
                                   when LDL_result_num > 160
                                       then 'LDL_above 160'

                                   else 'other'
                                   end                                      as LDL_category2,
                               case
                                   when NHDL < 70
                                       then 'NHDL_under_70'

                                   when NHDL between 70 and 100
                                       then 'NHDL_70_to_100'

                                   when NHDL between 100 and 130
                                       then 'NHDL_100_to_130'
                                   when NHDL between 130 and 160
                                       then 'NHDL_130_to_160'
                                   when NHDL between 160 and 190
                                       then 'NHDL_160_to_190'
                                   when NHDL > 190
                                       then 'NHDL_above 190'

                                   else 'other'
                                   end                                      as NHDL_category2,
--
                               case

                                   when Age BETWEEN 40 and 75
                                       then 'Age_40_75'
                                   when Age > 75
                                       then 'Age_over_75'
                                   else 'other'
                                   end                                      as Age_category,
                                                IIF(Age >= 65, 1, 0)        as age_over_65,

                               coalesce(ASCVD, MI, stroke, PAD, TIA_IHD, 0) as ASCVD,
                               coalesce(diabetes, 0)                        as diabetes,
                               coalesce(max_ldl_above_190, 0)               as max_ldl_above_190

                        from #pat_list a
                                 left join #MI mi on a.patid = mi.patid
                                 left join #stroke st on a.patid = st.patid
                                 left join #PAD pad on a.patid = pad.patid
                                 left join #TIA_IHD ihd on a.patid = ihd.patid
     ) as amspi;


     --enhanced

     select * into #TG_all from (select lab_result_cm.patid,
                       row_number() OVER (
                           PARTITION BY lab_result_cm.patid
                           ORDER BY lab_result_cm.result_date desc
                           )                     row_num,
                       lab_result_cm.result_num  TG_result_num,
                       lab_result_cm.result_unit result_unit,
                       lab_result_cm.result_date

                FROM cdm.dbo.lab_result_cm
                WHERE -- WHERE lab_result_cm.result_date BETWEEN '2020-09-30' AND '2021-09-30'

                    lab_result_cm.lab_loinc in ('2571-8')
                  --and lab_result_cm.patid in pat_list
                  and lab_result_cm.result_num is not null
                  --  and lab_result_cm.result_num >= 100
                  and patid in (select patid from #pat_list a)
         -- AND not lab_result_cm.result_unit in ('mg/d','g/dL','mL/min/{1.73_m2}') --Excluding rare weird units
         --AND lab_result_cm.result_num < 1000

     ) as lrc;
     select * into #TG_most_recent_high_175 from (select patid,
                                        1             as first_TG_above_175,
                                        result_date   as first_result_date,
                                        TG_result_num as first_result_num
                                 from #TG_all
                                 where row_num = 1
                                   and TG_result_num > 175
     ) as Ta
        ;

     --second most recent, over 3 months since first
     select * into #TG_second_most_recent_175 from (select a.patid,
                                          first_result_date,
                                          first_result_num,
                                          TG_result_num as second_result_num,
                                          row_number() OVER (
                                              PARTITION BY a.patid
                                              ORDER BY result_date desc
                                              )            row_num,
                                          result_date
                                   from #TG_most_recent_high_175 a
                                            left join #TG_all TG_all on a.patid=TG_all.patid
                                   where not row_num = 1
                                     and first_result_date - TG_all.result_date > 90 --over 3 months since first
     ) as aTa;


     select * into #TG_persistent_high_175 from (select patid, 1 as TG_persistent_high_175
                                from #TG_second_most_recent_175

                                where row_num = 1
                                  and second_result_num > 175
     ) as p;
     select * into #risk_enhancers from (select distinct pats.patid, 1 as diagnosis_risk_enhanced

                        from #pat_list pats
                                 INNER JOIN cdm.dbo.diagnosis Como on pats.patid=Como.patid
                        where (
                                      Como.dx = 'Z82.49' --family_hx_ascvd
                                      or Como.dx = 'E88.1' -- metabolic_syndrome
                                      or Como.dx like 'B20%' --HIV
                                      or Como.dx like 'L40%' --psoriasis
                                      or Como.dx = 'V08' --HIV (ICD9)
                                      or Como.dx like 'M05%' --arthritis
                                      or Como.dx like 'O14%' --preeclampsia
                                      or Como.dx in ('642.40', '642.50')--preeclampsia ICD9
                                      or Como.dx = 'E28.31' -- premature menopause
                                  )) as pdre;
     select * into #lab_enhancers from (select patid,
                                               IIF(
                                                       (egfr_2021 < 60 or hscrp >= 2 or lpa_mass > 50 or lpa_mass > 125 or apob > 130),
                                                       1, 0) as lab_enhancers
                       from #labs_all) as ple;


     select * into #enhanced from (SELECT a.patid,

                         coalesce(CKD, 0)                     as CKD,
                         coalesce(diagnosis_risk_enhanced, 0) as diagnosis_risk_enhanced,
                         coalesce(lab_enhancers, 0)           as lab_enhancers,
                         coalesce(LDL_persistent_high_160, 0) as LDL_persistent_high_160,
                         coalesce(TG_persistent_high_175, 0)  as TG_persistent_high_175
                  from #pat_list a
                           left join #lab_enhancers  b on a.patid=b.patid
                           left join #risk_enhancers  c on a.patid=c.patid
                           left join #LDL_persistent_high_160  d on a.patid=d.patid
                           left join #TG_persistent_high_175  e on a.patid=e.patid
                           left join #CKD  f on a.patid=f.patid
     ) as abcdef
        ;
    select * into #enhanced_category from (select patid,
                                                  IIF(diagnosis_risk_enhanced + lab_enhancers + CKD +
                                                      LDL_persistent_high_160 +
                                                      TG_persistent_high_175 > 0, 'enhanced_risk', 'no_enhanced_risk') as enhanced_risk --need to add "persistent" labs

                                  --case when(hypertension=1) then 1 else 0 end as high_risk
                           from #enhanced) as per;
     select * into #cohorts from (
         select a.patid,
                TG_CATEGORY,
                LDL_category2,
                nhdl_category2,
                v_high_risk,
               enhanced_risk,
                add_categories.ASCVD,
                add_categories.diabetes,
                case
                    when add_categories.ascvd = 1 and v_high_risk = 'not v high risk' and
                         not Age_category = 'Age_over_75' then 'Cohort_2A'
                    when add_categories.ascvd = 1 and v_high_risk = 'not v high risk' and Age_category = 'Age_over_75'
                        then 'Cohort_2B'
                    when add_categories.ascvd = 1 and v_high_risk = 'v high risk' then 'Cohort_2C'
                    when add_categories.ascvd = 0 and enhanced_risk = 'enhanced_risk' and
                         add_categories.diabetes = 1 and Age_category = 'Age_40_75' then 'Cohort_2D'
                    when add_categories.ascvd = 0 and enhanced_risk = 'no_enhanced_risk' and
                         add_categories.diabetes = 1 and Age_category = 'Age_40_75' then 'Cohort_2E'
                    when add_categories.ascvd = 0 and enhanced_risk = 'enhanced_risk' and
                         add_categories.diabetes = 1 and Age_category = 'Age_over_75' then 'Cohort_2F'
                    when add_categories.ascvd = 0 and enhanced_risk = 'no_enhanced_risk' and
                         add_categories.diabetes = 1 and Age_category = 'Age_over_75' then 'Cohort_2G'
                    when add_categories.ascvd = 0 and add_categories.diabetes = 0 and
                         add_categories.max_ldl_above_190 = 1 then 'Cohort_2H'
                    when TG_category = 'TG_over_2000' then 'cohort_2K'

                    when TG_category = 'TG_880_2000' then 'cohort_2J'

                    when TG_category = 'TG_500_880' then 'cohort_2I'
                    end as cohort

         from #pat_list a
                  left join #v_high_risk_category v on a.patid = v.patid
                  left join #enhanced_category e on a.patid = e.patid
                  left join #add_categories  add_categories on a.patid = add_categories.patid) as aveac;


select *
into foo.dbo.shtg_Q2_STEP3
from
    #PAT_LIST a  join #cohorts b on a.patid = b.patid where cohort is not null;



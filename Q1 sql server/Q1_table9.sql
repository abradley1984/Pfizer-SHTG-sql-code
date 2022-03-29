/* T9 - risk factors, only for Q1.
   This is not currently saving to file but could be.


 */


with pat_list as (select patid, cohort, TG_DATE
                  from shtg_Q1_cohorts_with_exclusions
    -- fetch first 100 rows only
),
     labs_all as (select * from Q1_labs_all),
     labs as (select patid,
                     cohort,
                     uacr,
                     egfr_2021,
                     nhdl,
                     hscrp,
                     CASE when (egfr_2021 < 60 or uacr >= 30) THEN 1 else 0 END as microvascular_disease,
                     CASE when (nhdl > 130) THEN 1 else 0 END                   as nhdl_over_130,
                     CASE when (hscrp >= 3) THEN 1 else 0 END                   as hscrp_over_3

              from labs_all)
        ,
     smoking AS (
         select patid, case when smoking in ('01', '02', '05', '07', '08') then 1 else 0 end as current_smoker
         from (
                  select patid,
                         row_number() OVER (
                             PARTITION BY patid
                             ORDER BY vital.measure_date desc
                             )            row_num,
                         vital.smoking as smoking,
                         cohort
                  FROM pat_list a
                           left join cdm_60_etl.vital b on a.patid = b.patid
                  WHERE vital.smoking IS NOT NULL
                    AND not vital.smoking in ('NI', 'OT', 'UN')) a
         where row_num = 1)
        ,
     age_65 as (
         select patid, cohort, case when age > 65 then 1 else 0 end as age_over_65
         from shtg_Q1_cohorts_with_exclusions)
        ,
     retinopathy as (
         select distinct patid,
                         cohort,
                         'retinopathy' as Comorbidity_name,
                         1             as retinopathy


         from pat_list a
                  INNER JOIN cdm_60_etl.diagnosis  b on a.patid = b.patid
         where (Como.dx IN ('H31.021',--RETINOPATHY
                            'H31.022',
                            'H31.023',
                            'H31.029',
                            'H35.00',
                            'H35.021',
                            'H35.022',
                            'H35.023',
                            'H35.029',
                            'H35.031',
                            'H35.032',
                            'H35.033',
                            'H35.039',
                            'H35.20',
                            'H35.21',
                            'H35.22',
                            'H35.23',
                            'H35.711',
                            'H35.712',
                            'H35.713',
                            'H35.719')
                   )
         group by patid, cohort),
     diabetes_10y as (
         select distinct patid,
                         cohort,
                         'diabetes_10y' as Comorbidity_name,
                         1              as diabetes_10y

         from pat_list pats
                  INNER JOIN cdm_60_etl.diagnosis  b on pats.patid = b.patid
         where (Como.dx like 'E08%' -- diabetes

             OR Como.dx like 'E09%' -- diabetes

             OR Como.dx like 'E10%' -- diabetes

             OR Como.dx like 'E11%' -- diabetes

             OR Como.dx like 'E13%' -- diabetes

             OR Como.dx like '249%' -- diabetes

             OR Como.dx like '250%' -- diabetes
             )
           and
               admit_date
             < '2019-04-01'
         group by patid, cohort, admit_date
     )
        ,

--TIA in last 5 years
     TIA as (
         select distinct patid,
                         cohort,
                         'TIA' as Comorbidity_name,
                         1     as TIA

         from pat_list pats
                  INNER JOIN cdm_60_etl.diagnosis como on pats.patid = como.patid
         where (dx LIKE 'G45%' --'TIA'
             OR dx LIKE '435%' --'TIA'
             )
           and admit_date BETWEEN '2020-09-30' AND '2021-09-30'
         group by patid, cohort
     ),
     PAD as (
         select distinct patid,
                         cohort,
                         'PAD' as Comorbidity_name,
                         1     as PAD

         from pat_list pats
                  INNER JOIN cdm_60_etl.diagnosis como on pats.patid = como.patid
         where (Como.dx in
                ('440.20', '440.21', '440.22', '440.23', '440.24', '440.29', '440.30', '440.31', '440.32', '440.4',
                 'I70.0', 'I70.1', 'I70.201', 'I70.202', 'I70.203', 'I70.208', 'I70.209', 'I70.21', 'I70.22', 'I70.232',
                 'I70.24', 'I70.25', 'I70.26', 'I70.261', 'I70.262', 'I70.263', 'I70.268', 'I70.269', 'I70.291',
                 'I70.292', 'I70.293', 'I70.298', 'I70.299', 'I70.3', 'I70.4', 'I70.5', 'I70.8', 'I70.90', 'I70.91',
                 'I70.92')-- PAD
                   )
             /* and admit_date BETWEEN '2020-09-30' AND '2021-09-30'*/
         group by patid, cohort
     ),
     CAD as (
         select distinct patid,
                         cohort,
                         'CAD' as Comorbidity_name,
                         1     as CAD


         from pat_list pats
                  INNER JOIN cdm_60_etl.diagnosis como on pats.patid = como.patid
         where (Como.dx IN ('Z95.1', 'Z95.5', 'Z98.61')

                   -- MULTIVESSEL CAD
                   )
         group by patid, cohort
     ),
     MI as (
         select distinct patid,
                         cohort,
                         'MI'                              as Comorbidity_name,
                         1                                 as MI,
                         max(admit_date),
                         min(admit_date),
                         max(admit_date) - min(admit_date) as MI_gap,
                         count(distinct admit_date)

         from pat_list pats
                  INNER JOIN cdm_60_etl.diagnosis como on pats.patid = como.patid
         where (Como.dx like '410%' -- MI

             OR Como.dx = '411.0' -- MI

             OR Como.dx = '411.81' -- MI

             OR Como.dx = '412' -- MI

             OR Como.dx like 'I21%' -- MI

             OR Como.dx like 'I22%' -- MI

             OR Como.dx like '123%' -- MI


-- ?? IN SPREADSHEET FOR I24 AND I25

--OR Como.dx = 'I24.0' -- MI

             OR Como.dx = 'I25.2' -- MI)
                   )
         group by patid, cohort
     ),
     subsequent_MI as (
         select distinct patid,
                         cohort,
                         'MI'                                                 as Comorbidity_name,
                         1                                                    as MI,
                         max(admit_date),
                         min(admit_date),
                         max(admit_date) - min(admit_date)                    as MI_gap,
                         count(distinct admit_date),
                         max(case when Como.dx like 'I22%' then 1 else 0 end) as subsequent_MI_I22

         from pat_list pats
                  INNER JOIN cdm_60_etl.diagnosis como on pats.patid = como.patid
         where /*((Como.dx like '410%' -- MI

             OR Como.dx like 'I21%' -- MI
                    )
             and not pdx = 'S')

            OR*/ Como.dx like 'I22%' -- MI subsequent

--removed complications, old MI codes for second MI


         group by patid, cohort
     )
        ,
     stroke as (
         select patid,
                cohort,
                'stroke'                          as Comorbidity_name,
                1                                 as stroke,
                max(admit_date),
                min(admit_date),
                max(admit_date) - min(admit_date) as stroke_gap

         from pat_list pats
                  INNER JOIN cdm_60_etl.diagnosis como on pats.patid = como.patid
         where (
                       Como.dx like '433%' -- STROKE

                       OR Como.dx like '434%' -- STROKE

                       OR Como.dx = '997.02' -- STROKE

                       OR Como.dx like 'I63%' -- STROKE

                       OR Como.dx like 'I97.8%' -- STROKE

                   )
         group by patid, cohort
     ),
     PCI as (
         select patid,
                cohort,
                'PCI'                             as Comorbidity_name,
                1                                 as PCI,
                max(admit_date),
                min(admit_date),
                max(admit_date) - min(admit_date) as PCI_gap
         from pat_list a
                  left join cdm_60_etl.procedures b on a.patid = b.patid
         where PX in ('92920', '92921', '92924', '92925', '92928', '92929', '92933', '92934', '92937', '92938', '92941',
                      '92943', '92944', '92973', '92974', '92975', '92978', '92979', '93571', '93572', 'C9600', 'C9601',
                      'C9602', 'C9603', 'C9604', 'C9605', 'C9606', 'C9607', 'C9608')
         group by patid, cohort),

     statins as (
         select distinct patid, cohort, 1 as Statin
         from pat_list a
                  left join cdm_60_etl.prescribing b on a.patid = b.patid

         where prescribing.rx_order_Date BETWEEN '2020-09-30' AND '2021-09-30'
             and rxnorm_cui in
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
                  '2001255', '861612', '861634', '861640', '861648', '861650', '2001255', '861612', '861634', '861640',
                  '861652', '861654', '2001255', '861612', '861634', '861640', '861643', '861646', '861612', '861634',
                  '2001255', '2001266', '2001268', '861634', '2001252', '2001254', '2001255', '2001260', '861634',
                  '2001252', '2001255', '2001262', '2001264', '2001252', '2001268', '2001266', '2001255', '2001252',
                  '861634', '2001252', '2001254', '2001255', '2001260', '861634', '2001252', '2001255', '2001262',
                  '2001264', '861634', '1944734', '861634', '1944734', '861634', '1944734', '861634', '904483', '42463',
                  '203144', '203333', '904458', '904460', '42463', '203144', '203333', '904467', '904469', '42463',
                  '203144', '203333', '904475', '904477', '42463', '203144', '203333', '904481', '904483', '42463',
                  '203144', '203333', '904458', '904460', '42463', '203144', '203333', '904467', '904469', '42463',
                  '203144', '203333', '904475', '904477', '42463', '203144', '203333', '904481', '301542', '320864',
                  '323828', '859747', '859749', '301542', '320864', '323828', '859751', '859753', '301542', '320864',
                  '323828', '859419', '859421', '301542', '320864', '323828', '859424', '859426', '301542', '320864',
                  '323828', '859424', '859426', '2167558', '2167558', '301542', '320864', '323828', '859747', '859749',
                  '2167558', '2167558', '301542', '320864', '323828', '859751', '859753', '2167558', '2167558',
                  '301542', '320864', '323828', '859419', '859421', '2167558', '2167558', '301542', '320864', '323828',
                  '2167558', '2167573', '2167575', '2167558', '301542', '320864', '323828', '2167557', '2167558',
                  '2167563', '2167558', '301542', '320864', '323828', '2167558', '2167565', '2167567', '2167558',
                  '301542', '320864', '323828', '2167558', '2167569', '2167571', '2167558', '301542', '323828',
                  '2167558', '2167573', '2167575', '301542', '323828', '2167557', '2167558', '2167563', '301542',
                  '323828', '2167558', '2167565', '2167567', '301542', '323828', '2167558', '2167569', '2167571',
                  '213319', '1944257', '1944257', '1944264', '1944266', '36567', '1790679', '1944257', '1944262',
                  '36567', '1944257', '1944264', '1944266', '36567', '196503', '1790679', '1944257', '1944262', '36567',
                  '196503', '36567', '152923', '196503', '198211', '36567', '196503', '200345', '213319', '36567',
                  '196503', '208220', '312962', '36567', '104490', '196503', '314231', '36567', '104491', '196503',
                  '312961', '36567', '196503', '208220', '312962', '1944257', '36567', '104490', '196503', '314231',
                  '1944257', '36567', '104491', '196503', '312961', '1944257', '36567', '152923', '196503', '198211',
                  '1944257', '36567', '196503', '200345', '1312410', '1312417', '1312424', '36567', '593411', '621590',
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
                  '1312424', '36567', '593411', '621590', '1312416', '1312422', '1372754', '1189803', '36567', '593411',
                  '621590', '1189804', '1189818', '1372754', '1189803', '1312410', '1312417', '1312424', '36567',
                  '593411', '621590', '1189808', '1189814', '1372754', '1189803', '1312410', '1312417', '327008',
                  '644112', '791846', '352387', '757733', '757745', '6472', '7393', '327008', '582042', '791831',
                  '791835', '791838', '791839', '791843', '6472', '7393', '327008', '582043', '791831', '791835',
                  '791839', '791842', '791843', '6472', '7393', '327008', '582041', '791831', '791834', '791835',
                  '791839', '791843', '6472', '7393', '327008', '644112', '791831', '791835', '791839', '791843',
                  '791846', '6472', '7393', '327008', '582042', '791838', '352387', '757733', '757745', '6472', '7393',
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
                  '83367', '341248', '1422086', '1422087', '1422092', '1422085', '83366', '83367', '341248', '1422087',
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
                  '215436', '1191', '1897', '6574', '42463', '215436', '904483', '904481', '203333', '203144', '42463',
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
         group by patid, cohort
     )
        ,
     insulin as (
         select patid, '1' as insulin, cohort
         from pat_list a
                  left join cdm_60_etl.prescribing b on a.patid = b.patid

         where prescribing.rx_order_Date BETWEEN '2020-09-30' AND '2021-09-30'
           and rxnorm_cui in
               ('5459', '5856', '7405', '11160', '51428', '86009', '92877', '92879', '92880', '92881', '92942', '93108',
                '93332', '93398', '93555', '93557', '93558', '93560', '106888', '106889', '106891', '106892', '106893',
                '106896', '108407', '108812', '108815', '108816', '135805', '139825', '150659', '150660', '150663',
                '150664', '150667', '150831', '150973', '150974', '150975', '150977', '150978', '150979', '152599',
                '152602', '152640', '152644', '152645', '152647', '152648', '153122', '153383', '153384', '153389',
                '199040', '203209', '205314', '213441', '213442', '217573', '217704', '217705', '217707', '217708',
                '221108', '221109', '221110', '225506', '225614', '226273', '226275', '226277', '226278', '226279',
                '226280', '226281', '226282', '226283', '226290', '226291', '226292', '226293', '235275', '235278',
                '235279', '235280', '235281', '235282', '235283', '235284', '235285', '235286', '236646', '237527',
                '237528', '242120', '242916', '242917', '245265', '249134', '249220', '249296', '253181', '253182',
                '253183', '259111', '260265', '261111', '261112', '261542', '261551', '274783', '283394', '284810',
                '285018', '311016', '311019', '311020', '311021', '311025', '311026', '311027', '311028', '311030',
                '311033', '311034', '311035', '311036', '311040', '311041', '311042', '311043', '311048', '311049',
                '311050', '311051', '311052', '311053', '311054', '311055', '311056', '311057', '311058', '311059',
                '311060', '311061', '311062', '311063', '311064', '314038', '314045', '314682', '314683', '314684',
                '314685', '317235', '317598', '317800', '349673', '351297', '351857', '351858', '351859', '351860',
                '351926', '352385', '352691', '360891', '360892', '360895', '379745', '379750', '380933', '385895',
                '385902', '386086', '386088', '400008', '400560', '475968', '484322', '485210', '485277', '485280',
                '607583', '615907', '615910', '616238', '731281', '741394', '752388', '803194', '816726', '847187',
                '847189', '847191', '847195', '847197', '847199', '847201', '847203', '847205', '847207', '847209',
                '847211', '847213', '847230', '847232', '847239', '847241', '847252', '847254', '847259', '847261',
                '847263', '847265', '847278', '847279', '847417', '865098', '977837', '977840', '977842', '1007184',
                '1008501', '1309342', '1359684', '1359719', '1359720', '1359936', '1360172', '1360226', '1372685',
                '1372723', '1372741', '1372744', '1372761', '1440051', '1543202', '1543203', '1543207', '1544488',
                '1544490', '1544568', '1544569', '1544570', '1544571', '1604539', '1604540', '1604544', '1605101',
                '1652239', '1652242', '1652639', '1652640', '1652644', '1652646', '1652647', '1652648', '1653196',
                '1653198', '1653202', '1653204', '1654857', '1654858', '1654862', '1654910', '1654912', '1656705',
                '1656706', '1670007', '1670011', '1670012', '1670016', '1670021', '1670023', '1727493', '1731315',
                '1731317', '1736859', '1736863', '1798387', '1798388', '1858994', '1858995', '1858996', '1859000',
                '1860167', '1860168', '1860172', '1862101', '1862102', '1926331', '1926332', '1986350', '1986354',
                '1986356', '1992165', '1992169', '1992171', '2002419', '2002420', '2049380', '2049381', '2100028',
                '2100029', '2107520', '2107522', '2179744', '2179745', '2179749', '2205454', '2206090', '2206092',
                '2206096', '2206099', '2376838', '2377130', '2377134', '2377231', '2380231', '2380232', '2380236',
                '2380254', '2380256', '2380259', '2380260', '2563969', '2563971', '2563973', '2563976', '2563977'))
        ,
     multiple_stroke as (
         select patid, case when encounter_count > 1 then 1 else 0 end as multiple_stroke
         from (select patid,
                      count(encounterid)                                                       as encounter_count,
                      max(encounter.admit_date),
                      min(encounter.admit_date),
                      --CHECK this may be a problem... I'm trying to find the time between then first and last inpatient diagnosis
                      round((max(encounter.admit_date) - min(encounter.admit_date)) )  as gap
               from cdm_60_etl.encounter a
                        join cdm_60_etl.diagnosis Como on patid, encounterid

               where patid in (Select patid From pat_list)
                 and (
                       Como.dx like '433%' -- STROKE

                       OR Como.dx like '434%' -- STROKE

                       OR Como.dx = '997.02' -- STROKE

                       OR Como.dx like 'I63%' -- STROKE


                   )
                 and encounter.enc_Type in ('EI', 'IP')
                 -- and DRG in ('061', '062', '063', '064', '065', '066')
               group by patid
               having count(encounterid) > 1) b

         where gap
                   > 30),
     multiple_MI as (
         select patid, gap, case when encounter_count > 1 then 1 else 0 end as multiple_MI
         from (select patid,
                      count(encounterid)                                           as encounter_count,
                      max(diagnosis.admit_date),
                      min(diagnosis.admit_date),
                      round(max(diagnosis.admit_date) - min(diagnosis.admit_date)) as gap
               from cdm_60_etl.diagnosis
--join cdm_60_etl.diagnosis  Como using (patid, encounterid)

               where patid in (Select patid From pat_list)
                 and diagnosis.enc_Type in ('EI', 'IP')
                 and (((dx like '410%' -- MI

                   OR dx like 'I21%')-- MI)


                   and pdx = 'P')
                   OR dx like 'I22%') -- MI)

               group by patid
               having count(encounterid) > 1) c


         where gap
                   > 30)
        ,
     multiple_PCI as (
         select patid, PCI_gap, case when encounter_count > 1 then 1 else 0 end as multiple_PCI
         from (select patid,
                      count(encounterid)                as encounter_count,

                      -- 'PCI'                             as Comorbidity_name,
                      -- 1 as PCI--,
                      -- ,   max(admit_date),
                      min(admit_date),
                      max(admit_date) - min(admit_date) as PCI_gap
               from pat_list a
                        left join cdm_60_etl.procedures b on a.patid = b.patid
               where PX in
                     ('92920', '92921', '92924', '92925', '92928', '92929', '92933', '92934', '92937', '92938', '92941',
                      '92943', '92944', '92973', '92974', '92975', '92978', '92979', '93571', '93572', 'C9600', 'C9601',
                      'C9602', 'C9603', 'C9604', 'C9605', 'C9606', 'C9607', 'C9608')
               group by patid) d
         where PCI_gap > 30),
     CKD as (select patid, case when egfr_2021 < 60 then 1 else 0 end as CKD
             from labs_all)
        ,

     combined as (
         select distinct patid,

                         -- stroke_gap,
                         insulin,
                         PCI,
                         MI,
                         diabetes_10y,
                         stroke,
                         TIA,
                         current_smoker,
                         age_over_65,
             /*more_than_1_stroke,
             more_than_1_MI,
             more_than_1_PCI,*/
                         CAD,
                         retinopathy,
                         PAD,
                         multiple_MI,
                         multiple_stroke,
                         multiple_PCI,
                         hscrp_over_3,
                         nhdl_over_130,
                         microvascular_disease,
                         case when Statin = 1 then 'Statin' else 'No Statin' end       as Statin,
                         case when (PCI + MI + stroke) > 1 then 1 else 0 end           as more_than_1_of_PCI_MI_stroke,
                         case
                             when (PCI + MI + stroke + multiple_stroke + multiple_PCI + multiple_MI) > 1 then 1
                             else 0 end                                                as more_than_1_of_PCI_MI_stroke_allowing_multiples,
                         case when ((CAD + PAD + insulin + TIA) > 1) then 1 else 0 end as more_than_1_of_CAD_insulin_PAD_TIA,
                         case
                             when ((microvascular_disease + insulin + diabetes_10y) > 1) then 1
                             else 0 end                                                as more_than_1_diabetes_insulin_microvascular,

                         case
                             when (microvascular_disease = 1 or insulin = 1 or diabetes_10y = 1) then 1
                             else 0 end                                                as any_diabetes_10y_insulin_microvascular,

                         case
                             when ((microvascular_disease + insulin + diabetes_10y) >= 1 and age_over_65 = 1) then 1
                             else 0 end                                                as any_diabetes_10y_insulin_microvascular_age_over_65,
                         case
                             when ((microvascular_disease + insulin + diabetes_10y) >= 1 and current_smoker = 1) then 1
                             else 0 end                                                as any_diabetes_10y_insulin_microvascular_smoker,
                         case
                             when ((microvascular_disease + insulin + diabetes_10y) >= 1 and nhdl_over_130 = 1) then 1
                             else 0 end                                                as any_diabetes_10y_insulin_microvascular_nhdl_over_130,
                         case
                             when ((microvascular_disease + insulin + diabetes_10y) >= 1 and retinopathy = 1) then 1
                             else 0 end                                                as any_diabetes_10y_insulin_microvascular_retinopathy,
                         case
                             when ((microvascular_disease + insulin + diabetes_10y) >= 1 and hscrp_over_3 = 1) then 1
                             else 0 end                                                as any_diabetes_10y_insulin_microvascular_hscrp_over_3,
                         case
                             when ((microvascular_disease + insulin + diabetes_10y) >= 1 and
                                   hscrp_over_3 + retinopathy + nhdl_over_130 + current_smoker + age_over_65 >= 1)
                                 then 1
                             else 0 end                                                as any_diabetes_10y_insulin_microvascular_plus_any,

                         case
                             when (microvascular_disease + insulin + diabetes_10y + hscrp_over_3 + retinopathy +
                                   nhdl_over_130 +
                                   current_smoker + age_over_65 + PCI + MI + stroke = 0) then 1
                             else 0 end                                                as no_CV_or_risk_factors


         from (select distinct a.patid,

                               case when microvascular_disease = 1 then 1 else 0 end as microvascular_disease,
                               case when nhdl_over_130 = 1 then 1 else 0 end         as nhdl_over_130,
                               case when hscrp_over_3 = 1 then 1 else 0 end          as hscrp_over_3,

                               case when retinopathy = 1 then 1 else 0 end           as retinopathy,

                               -- stroke_gap,
                               Statin,

                               case when diabetes_10y = 1 then 1 else 0 end          as diabetes_10y,
                               case when insulin = 1 then 1 else 0 end               as insulin,
                               case when TIA = 1 then 1 else 0 end                   as TIA,
                               case when PAD = 1 then 1 else 0 end                   as PAD,
                               case when CAD = 1 then 1 else 0 end                   as CAD,
                               case when PCI = 1 then 1 else 0 end                   as PCI,
                               case when MI = 1 then 1 else 0 end                    as MI,
                               case when stroke = 1 then 1 else 0 end                as stroke,
                               case when multiple_PCI = 1 then 1 else 0 end          as multiple_PCI,
                               case when multiple_MI = 1 then 1 else 0 end           as multiple_MI,
                               case when multiple_stroke = 1 then 1 else 0 end       as multiple_stroke
                       ,
                               case when current_smoker = 1 then 1 else 0 end        as current_smoker,
                               case when age_over_65 = 1 then 1 else 0 end           as age_over_65
               from stroke a  full outer join MI b on a.patid = b.patid
                        full outer join PCI c on a.patid = c.patid
                        full outer join statins d on a.patid = d.patid
                        full outer join insulin e on a.patid = e.patid
                        full outer join CAD f on a.patid = f.patid
                        full outer join TIA g on a.patid = g.patid
                        full outer join PAD h on a.patid = h.patid
                        full outer join diabetes_10y i on a.patid = i.patid
                        full outer join retinopathy j on a.patid =j.patid
                        full outer join multiple_stroke k on a.patid = k.patid
                        full outer join multiple_MI l on a.patid = l.patid
                        full outer join multiple_PCI m on a.patid = m.patid
                        full outer join smoking n on a.patid =n.patid
                        full outer join age_65 o on a.patid = o.patid
                        full outer join labs p on a.patid = p.patid
              ) f)


select pat_list.cohort,
       sum(PCI)                                                  as N_PCI,
       sum(MI)                                                   as N_MI,
       sum(stroke)                                               as N_stroke,
       sum(more_than_1_of_PCI_MI_stroke)                         as N_more_than_1_of_PCI_MI_stroke,
       sum(multiple_stroke)                                      as N_more_than_1_stroke,
       sum(multiple_MI)                                          as N_more_than_1_MI,
       sum(multiple_PCI)                                         as N_more_than_1_PCI,
       sum(more_than_1_of_PCI_MI_stroke_allowing_multiples)      as N_more_than_1_of_PCI_MI_stroke_allowing_multiples
        ,
       Statin,
       sum(insulin)                                              as N_insulin,
       sum(CAD)                                                  as N_CAD,
       sum(TIA)                                                  as N_TIA,
       sum(PAD)                                                  as N_PAD,
       sum(diabetes_10y)                                         as N_diabetes_10y,
       sum(retinopathy)                                          as N_retinopathy,
       sum(more_than_1_of_CAD_insulin_PAD_TIA)                   as N_more_than_1_of_CAD_insulin_PAD_TIA,
       sum(current_smoker)                                       as N_current_smoker,
       sum(age_over_65)                                          as N_age_over_65,
       sum(hscrp_over_3)                                         as N_hscrp_over_3,
       sum(nhdl_over_130)                                        as N_nhdl_over_130,
       sum(microvascular_disease)                                as N_microvascular_disease,
       sum(more_than_1_of_CAD_insulin_PAD_TIA)                   as N_more_than_1_of_CAD_insulin_PAD_TIA,
       sum(more_than_1_diabetes_insulin_microvascular)           as N_more_than_1_diabetes_insulin_microvascular,
       sum(any_diabetes_10y_insulin_microvascular)               as N_any_diabetes_10y_insulin_microvascular,
       sum(any_diabetes_10y_insulin_microvascular_age_over_65)   as N_any_diabetes_10y_insulin_microvascular_age_over_65,
       sum(any_diabetes_10y_insulin_microvascular_smoker)        as N_any_diabetes_10y_insulin_microvascular_smoker,
       sum(any_diabetes_10y_insulin_microvascular_nhdl_over_130) as N_any_diabetes_10y_insulin_microvascular_nhdl_over_130,
       sum(any_diabetes_10y_insulin_microvascular_retinopathy)   as any_diabetes_10y_insulin_microvascular_retinopathy,
       sum(any_diabetes_10y_insulin_microvascular_hscrp_over_3)  as any_diabetes_10y_insulin_microvascular_hscrp_over_3,
       sum(any_diabetes_10y_insulin_microvascular_plus_any)      as N_any_diabetes_10y_insulin_microvascular_plus_any,
       sum(no_CV_or_risk_factors)                                as N_no_CV_or_risk_factors,
       count(distinct a.patid)                                     as total_count_patients

from pat_list a
         left join combined b on a.patid = b.patid
group by pat_list.cohort, Statin

order by pat_list.cohort

/*

/* T9 - risk factors, only for Q1.
/* T9 - risk factors, only for Q1.
   This is not currently saving to file but could be.
 */


with pat_list as (select patid, cohort, TG_DATE
                  from shtg_Q1_cohorts_with_ex
    -- fetch first 100 rows only
),
     labs_all as (select * from Q1_labs_all),
     labs as (select patid,
                     cohort,
                     uacr,
                     egfr_2021,
                     nhdl,
                     hscrp,
                     CASE when (egfr_2021 < 60 or uacr >= 30) THEN 1 else 0 END as mv_disease,
                     CASE when (nhdl > 130) THEN 1 else 0 END                   as nhdl_over_130,
                     CASE when (hscrp >= 3) THEN 1 else 0 END                   as hscrp_over_3

              from labs_all)
        ,
     smoking AS (select patid, case when smoking in ('01', '02', '05', '07', '08') then 1 else 0 end as current_smoker
                 from (select patid,
                              row_number() OVER (
                                  PARTITION BY patid
                                  ORDER BY vital.measure_date desc
                                  )            row_num,
                              vital.smoking as smoking,
                              cohort
                       FROM pat_list
                                left join cdm_60_prod.vital using (patid)
                       WHERE vital.smoking IS NOT NULL
                         AND not vital.smoking in ('NI', 'OT', 'UN'))
                 where row_num = 1)
        ,
     age_65 as (select patid, cohort, case when age > 65 then 1 else 0 end as age_over_65
                from shtg_Q1_cohorts_with_ex)
        ,
     retinopathy as (select distinct patid,
                                     cohort,
                                     'retinopathy' as Comorbidity_name,
                                     1             as retinopathy


                     from pat_list pats
                              INNER JOIN cdm_60_prod.diagnosis Como using (patid)
                     where  Como.admit_date<=TO_DATE('09/30/2021'
                     , 'MM/DD/YYYY') and (Como.dx IN ('H31.021',--RETINOPATHY
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
     diabetes_10y as (select distinct patid,
                                      cohort,
                                      'diabetes_10y' as Comorbidity_name,
                                      1              as diabetes_10y

                      from pat_list pats
                               INNER JOIN cdm_60_prod.diagnosis Como using (patid)
                      where (Como.dx like 'E08%' -- diabetes

                          OR Como.dx like 'E09%' -- diabetes

                          OR Como.dx like 'E10%' -- diabetes

                          OR Como.dx like 'E11%' -- diabetes

                          OR Como.dx like 'E13%' -- diabetes

                          OR Como.dx like '249%' -- diabetes

                          OR Como.dx like '250%' -- diabetes
                          )
                        and admit_date
                          <= TO_DATE('09/30/2011'
                                , 'MM/DD/YYYY')
                      group by patid, cohort, admit_date)
        ,

--TIA in last 5 years
     TIA as (select distinct patid,
                             cohort,
                             'TIA' as Comorbidity_name,
                             1     as TIA

             from pat_list pats
                      INNER JOIN cdm_60_prod.diagnosis Como using (patid)
             where (dx LIKE 'G45%' --'TIA'
                 OR dx LIKE '435%' --'TIA'
                 )
               and admit_date BETWEEN TO_DATE('09/30/2016'
                 , 'MM/DD/YYYY')
                 AND TO_DATE('09/30/2021'
                     , 'MM/DD/YYYY')
             group by patid, cohort),
     PAD as (select distinct patid,
                             cohort,
                             'PAD' as Comorbidity_name,
                             1     as PAD

             from pat_list pats
                      INNER JOIN cdm_60_prod.diagnosis Como using (patid)
             where Como.admit_date <= TO_DATE('09/30/2021', 'MM/DD/YYYY')
               and (Como.dx in
                    ('440.20', '440.21', '440.22', '440.23', '440.24', '440.29', '440.30', '440.31', '440.32', '440.4',
                     'I70.0', 'I70.1', 'I70.201', 'I70.202', 'I70.203', 'I70.208', 'I70.209', 'I70.21', 'I70.22',
                     'I70.232',
                     'I70.24', 'I70.25', 'I70.26', 'I70.261', 'I70.262', 'I70.263', 'I70.268', 'I70.269', 'I70.291',
                     'I70.292', 'I70.293', 'I70.298', 'I70.299', 'I70.3', 'I70.4', 'I70.5', 'I70.8', 'I70.90', 'I70.91',
                     'I70.92')-- PAD
                 )
                 /* and admit_date BETWEEN TO_DATE('09/30/2016'
                    , 'MM/DD/YYYY')
                    AND TO_DATE('09/30/2021'
                        , 'MM/DD/YYYY')*/
             group by patid, cohort),
     CAD as (select distinct patid,
                             cohort,
                             'CAD' as Comorbidity_name,
                             1     as CAD


             from pat_list pats
                      INNER JOIN cdm_60_prod.diagnosis Como using (patid)
             where Como.admit_date <= TO_DATE('09/30/2021', 'MM/DD/YYYY')
               and (Como.dx IN ('Z95.1', 'Z95.5', 'Z98.61')

                 -- MULTIVESSEL CAD
                 )
             group by patid, cohort),
     MI as (select distinct patid,
                            cohort,
                            'MI'                              as Comorbidity_name,
                            1                                 as MI,
                            max(admit_date),
                            min(admit_date),
                            max(admit_date) - min(admit_date) as MI_gap,
                            count(distinct admit_date)

            from pat_list pats
                     INNER JOIN cdm_60_prod.diagnosis Como using (patid)
            where Como.admit_date <= TO_DATE('09/30/2021', 'MM/DD/YYYY')
              and (Como.dx like '410%' -- MI

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
            group by patid, cohort),
     subsequent_MI as (select distinct patid,
                                       cohort,
                                       'MI'                                                 as Comorbidity_name,
                                       1                                                    as MI,
                                       max(admit_date),
                                       min(admit_date),
                                       max(admit_date) - min(admit_date)                    as MI_gap,
                                       count(distinct admit_date),
                                       max(case when Como.dx like 'I22%' then 1 else 0 end) as subsequent_MI_I22

                       from pat_list pats
                                INNER JOIN cdm_60_prod.diagnosis Como using (patid)
                       where Como.admit_date <= TO_DATE('09/30/2021', 'MM/DD/YYYY')
                         and
                           /*((Como.dx like '410%' -- MI

                           OR Como.dx like 'I21%' -- MI
                                  )
                           and not pdx = 'S')

                          OR*/ Como.dx like 'I22%' -- MI subsequent

--removed complications, old MI codes for second MI


                       group by patid, cohort)
        ,
     stroke as (select patid,
                       cohort,
                       'stroke'                          as Comorbidity_name,
                       1                                 as stroke,
                       max(admit_date),
                       min(admit_date),
                       max(admit_date) - min(admit_date) as stroke_gap

                from pat_list pats
                         INNER JOIN cdm_60_prod.diagnosis Como using (patid)
                where Como.admit_date <= TO_DATE('09/30/2021', 'MM/DD/YYYY')
                  and (
                            Como.dx like '433%' -- STROKE

                        OR Como.dx like '434%' -- STROKE

                        OR Como.dx = '997.02' -- STROKE

                        OR Como.dx like 'I63%' -- STROKE

                        OR Como.dx like 'I97.8%' -- STROKE

                    )
                group by patid, cohort),
     PCI as (select patid,
                    cohort,
                    'PCI'                             as Comorbidity_name,
                    1                                 as PCI,
                    max(admit_date),
                    min(admit_date),
                    max(admit_date) - min(admit_date) as PCI_gap
             from pat_list
                      left join cdm_60_prod.procedures using (patid)
             where procedures.admit_date <= TO_DATE('09/30/2021', 'MM/DD/YYYY')
               and PX in
                   ('92920', '92921', '92924', '92925', '92928', '92929', '92933', '92934', '92937', '92938', '92941',
                    '92943', '92944', '92973', '92974', '92975', '92978', '92979', '93571', '93572', 'C9600', 'C9601',
                    'C9602', 'C9603', 'C9604', 'C9605', 'C9606', 'C9607', 'C9608')
             group by patid, cohort),

     statins as (select distinct patid, cohort, 1 as Statin
                 from pat_list
                          left join cdm_60_prod.prescribing using (patid)

                 where prescribing.rx_order_Date BETWEEN TO_DATE('09/30/2020'
                     , 'MM/DD/YYYY')
                     AND TO_DATE('09/30/2021'
                         , 'MM/DD/YYYY')
                   and rxnorm_cui in
                       ('6472',
                        '36567',
                        '41127',
                        '42463',
                        '72875',
                        '83366',
                        '83367',
                        '103918',
                        '103919',
                        '104490',
                        '104491',
                        '151972',
                        '152923',
                        '153165',
                        '153302',
                        '153303',
                        '196503',
                        '197903',
                        '197904',
                        '197905',
                        '198211',
                        '200345',
                        '203144',
                        '203333',
                        '206257',
                        '206258',
                        '208220',
                        '209013',
                        '213319',
                        '215567',
                        '221072',
                        '224938',
                        '259255',
                        '261244',
                        '262095',
                        '284424',
                        '284764',
                        '301542',
                        '309123',
                        '309124',
                        '309125',
                        '310404',
                        '310405',
                        '312961',
                        '312962',
                        '313936',
                        '314231',
                        '320864',
                        '323828',
                        '327008',
                        '352387',
                        '352420',
                        '359731',
                        '359732',
                        '360507',
                        '404011',
                        '404013',
                        '404773',
                        '404914',
                        '433848',
                        '433849',
                        '476345',
                        '476349',
                        '476350',
                        '476351',
                        '484211',
                        '495215',
                        '541841',
                        '582041',
                        '582042',
                        '582043',
                        '596723',
                        '597967',
                        '597971',
                        '597974',
                        '597977',
                        '597980',
                        '597984',
                        '597987',
                        '597990',
                        '597993',
                        '617310',
                        '617311',
                        '617312',
                        '617314',
                        '617318',
                        '617320',
                        '644112',
                        '687048',
                        '750196',
                        '750199',
                        '750200',
                        '750203',
                        '750204',
                        '750207',
                        '750208',
                        '750211',
                        '750212',
                        '750215',
                        '750216',
                        '750219',
                        '750220',
                        '750223',
                        '750224',
                        '750227',
                        '750228',
                        '750231',
                        '750232',
                        '750235',
                        '750236',
                        '750239',
                        '757733',
                        '757736',
                        '757745',
                        '757748',
                        '761907',
                        '761909',
                        '762970',
                        '763225',
                        '763228',
                        '763229',
                        '763232',
                        '763233',
                        '763236',
                        '791831',
                        '791834',
                        '791835',
                        '791838',
                        '791839',
                        '791842',
                        '791843',
                        '791846',
                        '803516',
                        '859419',
                        '859421',
                        '859424',
                        '859426',
                        '859747',
                        '859749',
                        '859751',
                        '859753',
                        '861612',
                        '861634',
                        '861640',
                        '861643',
                        '861646',
                        '861648',
                        '861650',
                        '861652',
                        '861654',
                        '876514',
                        '884383',
                        '904458',
                        '904460',
                        '904467',
                        '904469',
                        '904475',
                        '904477',
                        '904481',
                        '904483',
                        '904660',
                        '904661',
                        '904664',
                        '904665',
                        '904668',
                        '904669',
                        '997004',
                        '997006',
                        '997007',
                        '999935',
                        '999936',
                        '999939',
                        '999942',
                        '999943',
                        '999946',
                        '1189803',
                        '1189804',
                        '1189805',
                        '1189808',
                        '1189809',
                        '1189814',
                        '1189818',
                        '1189821',
                        '1189822',
                        '1189827',
                        '1233869',
                        '1233870',
                        '1233871',
                        '1233878',
                        '1233883',
                        '1233888',
                        '1245420',
                        '1245430',
                        '1245441',
                        '1245449',
                        '1312409',
                        '1312410',
                        '1312415',
                        '1312416',
                        '1312417',
                        '1312422',
                        '1312423',
                        '1312424',
                        '1312429',
                        '1372731',
                        '1372754',
                        '1422085',
                        '1422086',
                        '1422087',
                        '1422092',
                        '1422093',
                        '1422095',
                        '1422096',
                        '1422098',
                        '1422099',
                        '1422101',
                        '1790679',
                        '1944257',
                        '1944262',
                        '1944264',
                        '1944266',
                        '1944734',
                        '2001252',
                        '2001254',
                        '2001255',
                        '2001260',
                        '2001262',
                        '2001264',
                        '2001266',
                        '2001268',
                        '2167557',
                        '2167558',
                        '2167563',
                        '2167565',
                        '2167567',
                        '2167569',
                        '2167571',
                        '2167573',
                        '2167575',
                        '2535745',
                        '2535747',
                        '2535748',
                        '2535749',
                        '2535750',
                        '2536055',
                        '2536060',
                        '2536062',
                        '2536064',
                        '2536066')
                 group by patid, cohort)
        ,
     insulin as (select patid, '1' as insulin, cohort
                 from pat_list
                          left join cdm_60_prod.prescribing using (patid)

                 where prescribing.rx_order_Date BETWEEN TO_DATE('08/01/2020'
                     , 'MM/DD/YYYY')
                     AND TO_DATE('09/30/2021'
                         , 'MM/DD/YYYY')
                   and rxnorm_cui in
                     --checked
                       ('5459', '5856', '7405', '11160', '51428', '86009', '92877', '92879', '92880', '92881', '92942',
                        '93108',
                        '93332', '93398', '93555', '93557', '93558', '93560', '106888', '106889', '106891', '106892',
                        '106893',
                        '106896', '108407', '108812', '108815', '108816', '135805', '139825', '150659', '150660',
                        '150663',
                        '150664', '150667', '150831', '150973', '150974', '150975', '150977', '150978', '150979',
                        '152599',
                        '152602', '152640', '152644', '152645', '152647', '152648', '153122', '153383', '153384',
                        '153389',
                        '199040', '203209', '205314', '213441', '213442', '217573', '217704', '217705', '217707',
                        '217708',
                        '221108', '221109', '221110', '225506', '225614', '226273', '226275', '226277', '226278',
                        '226279',
                        '226280', '226281', '226282', '226283', '226290', '226291', '226292', '226293', '235275',
                        '235278',
                        '235279', '235280', '235281', '235282', '235283', '235284', '235285', '235286', '236646',
                        '237527',
                        '237528', '242120', '242916', '242917', '245265', '249134', '249220', '249296', '253181',
                        '253182',
                        '253183', '259111', '260265', '261111', '261112', '261542', '261551', '274783', '283394',
                        '284810',
                        '285018', '311016', '311019', '311020', '311021', '311025', '311026', '311027', '311028',
                        '311030',
                        '311033', '311034', '311035', '311036', '311040', '311041', '311042', '311043', '311048',
                        '311049',
                        '311050', '311051', '311052', '311053', '311054', '311055', '311056', '311057', '311058',
                        '311059',
                        '311060', '311061', '311062', '311063', '311064', '314038', '314045', '314682', '314683',
                        '314684',
                        '314685', '317235', '317598', '317800', '349673', '351297', '351857', '351858', '351859',
                        '351860',
                        '351926', '352385', '352691', '360891', '360892', '360895', '379745', '379750', '380933',
                        '385895',
                        '385902', '386086', '386088', '400008', '400560', '475968', '484322', '485210', '485277',
                        '485280',
                        '607583', '615907', '615910', '616238', '731281', '741394', '752388', '803194', '816726',
                        '847187',
                        '847189', '847191', '847195', '847197', '847199', '847201', '847203', '847205', '847207',
                        '847209',
                        '847211', '847213', '847230', '847232', '847239', '847241', '847252', '847254', '847259',
                        '847261',
                        '847263', '847265', '847278', '847279', '847417', '865098', '977837', '977840', '977842',
                        '1007184',
                        '1008501', '1309342', '1359684', '1359719', '1359720', '1359936', '1360172', '1360226',
                        '1372685',
                        '1372723', '1372741', '1372744', '1372761', '1440051', '1543202', '1543203', '1543207',
                        '1544488',
                        '1544490', '1544568', '1544569', '1544570', '1544571', '1604539', '1604540', '1604544',
                        '1605101',
                        '1652239', '1652242', '1652639', '1652640', '1652644', '1652646', '1652647', '1652648',
                        '1653196',
                        '1653198', '1653202', '1653204', '1654857', '1654858', '1654862', '1654910', '1654912',
                        '1656705',
                        '1656706', '1670007', '1670011', '1670012', '1670016', '1670021', '1670023', '1727493',
                        '1731315',
                        '1731317', '1736859', '1736863', '1798387', '1798388', '1858994', '1858995', '1858996',
                        '1859000',
                        '1860167', '1860168', '1860172', '1862101', '1862102', '1926331', '1926332', '1986350',
                        '1986354',
                        '1986356', '1992165', '1992169', '1992171', '2002419', '2002420', '2049380', '2049381',
                        '2100028',
                        '2100029', '2107520', '2107522', '2179744', '2179745', '2179749', '2205454', '2206090',
                        '2206092',
                        '2206096', '2206099', '2376838', '2377130', '2377134', '2377231', '2380231', '2380232',
                        '2380236',
                        '2380254', '2380256', '2380259', '2380260', '2563969', '2563971', '2563973', '2563976',
                        '2563977'))
        ,
     multiple_stroke as (select patid, case when encounter_count > 1 then 1 else 0 end as multiple_stroke
                         from (select patid,
                                      count(encounterid)                                                       as encounter_count,
                                      max(encounter.admit_date),
                                      min(encounter.admit_date),
                                      trunc((max(encounter.admit_date) - min(encounter.admit_date)) / 10) * 10 as gap
                               from cdm_60_prod.encounter
                                        join cdm_60_prod.diagnosis Como using (patid, encounterid)

                               where patid in (Select patid From pat_list)
                                 and encounter.admit_date <= TO_DATE('09/30/2021', 'MM/DD/YYYY')
                                 and (
                                           Como.dx like '433%' -- STROKE

                                       OR Como.dx like '434%' -- STROKE

                                       OR Como.dx = '997.02' -- STROKE

                                       OR Como.dx like 'I63%' -- STROKE


                                   )
                                 and encounter.enc_Type in ('EI', 'IP')
                                 -- and DRG in ('061', '062', '063', '064', '065', '066')
                               group by patid
                               having count(encounterid) > 1)

                         where gap
                                   > 30),
     multiple_MI as (select patid, gap, case when encounter_count > 1 then 1 else 0 end as multiple_MI
                     from (select patid,
                                  count(encounterid)                                           as encounter_count,
                                  max(diagnosis.admit_date),
                                  min(diagnosis.admit_date),
                                  trunc(max(diagnosis.admit_date) - min(diagnosis.admit_date)) as gap
                           from cdm_60_prod.diagnosis
--join cdm_60_prod.diagnosis  Como using (patid, encounterid)

                           where patid in (Select patid From pat_list)
                             and diagnosis.enc_Type in ('EI', 'IP')
                             and diagnosis.admit_date <= TO_DATE('09/30/2021', 'MM/DD/YYYY')
                             and (((dx like '410%' -- MI

                               OR dx like 'I21%')-- MI)


                               and pdx = 'P')
                               OR dx like 'I22%') -- MI)

                           group by patid
                           having count(encounterid) > 1)


                     where gap
                               > 30)
        ,
     multiple_PCI as (select patid, PCI_gap, case when encounter_count > 1 then 1 else 0 end as multiple_PCI
                      from (select patid,
                                   count(encounterid)                as encounter_count,

                                   -- 'PCI'                             as Comorbidity_name,
                                   -- 1 as PCI--,
                                   -- ,   max(admit_date),
                                   min(admit_date),
                                   max(admit_date) - min(admit_date) as PCI_gap
                            from pat_list
                                     left join cdm_60_prod.procedures using (patid)
                            where procedures.admit_date <= TO_DATE('09/30/2021', 'MM/DD/YYYY')
                              and PX in
                                  ('92920', '92921', '92924', '92925', '92928', '92929', '92933', '92934', '92937',
                                   '92938', '92941',
                                   '92943', '92944', '92973', '92974', '92975', '92978', '92979', '93571', '93572',
                                   'C9600', 'C9601',
                                   'C9602', 'C9603', 'C9604', 'C9605', 'C9606', 'C9607', 'C9608')
                            group by patid)
                      where PCI_gap > 30),
     CKD as (select patid, case when egfr_2021 < 60 then 1 else 0 end as CKD
             from labs_all)
        ,

     combined as (select distinct patid,

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
                                  mv_disease,
                                  case when Statin = 1 then 'Statin' else 'No Statin' end       as Statin,
                                  case when (PCI + MI + stroke) > 1 then 1 else 0 end           as m_1_PCI_MI_stroke,
                                  case
                                      when (PCI + MI + stroke + multiple_stroke + multiple_PCI + multiple_MI) > 1 then 1
                                      else 0 end                                                as m_1_of_PCI_MI_stroke_w_mult,
                                  case when ((CAD + PAD + insulin + TIA) > 1) then 1 else 0 end as m_1_CAD_insulin_PAD_TIA,
                                  case
                                      when ((mv_disease + insulin + diabetes_10y) > 1) then 1
                                      else 0 end                                                as more_than_1_dm_insulin_mv,

                                  case
                                      when (mv_disease = 1 or insulin = 1 or diabetes_10y = 1) then 1
                                      else 0 end                                                as dm_insulin_mv,

                                  case
                                      when ((mv_disease + insulin + diabetes_10y) >= 1 and age_over_65 = 1) then 1
                                      else 0 end                                                as dm_insulin_mv_age_over_65,
                                  case
                                      when ((mv_disease + insulin + diabetes_10y) >= 1 and current_smoker = 1) then 1
                                      else 0 end                                                as dm_insulin_mv_smoker,
                                  case
                                      when ((mv_disease + insulin + diabetes_10y) >= 1 and nhdl_over_130 = 1) then 1
                                      else 0 end                                                as dm_insulin_mv_nhdl_over_130,
                                  case
                                      when ((mv_disease + insulin + diabetes_10y) >= 1 and retinopathy = 1) then 1
                                      else 0 end                                                as dm_insulin_mv_retinopathy,
                                  case
                                      when ((mv_disease + insulin + diabetes_10y) >= 1 and hscrp_over_3 = 1) then 1
                                      else 0 end                                                as dm_insulin_mv_hscrp_over_3,
                                  case
                                      when ((mv_disease + insulin + diabetes_10y) >= 1 and
                                            hscrp_over_3 + retinopathy + nhdl_over_130 + current_smoker + age_over_65 >=
                                            1)
                                          then 1
                                      else 0 end                                                as dm_insulin_mv_plus_any,

                                  case
                                      when (mv_disease + insulin + diabetes_10y + hscrp_over_3 + retinopathy +
                                            nhdl_over_130 +
                                            current_smoker + age_over_65 + PCI + MI + stroke = 0) then 1
                                      else 0 end                                                as no_CV_or_risk_factors


                  from (select distinct patid,

                                        case when mv_disease = 1 then 1 else 0 end      as mv_disease,
                                        case when nhdl_over_130 = 1 then 1 else 0 end   as nhdl_over_130,
                                        case when hscrp_over_3 = 1 then 1 else 0 end    as hscrp_over_3,

                                        case when retinopathy = 1 then 1 else 0 end     as retinopathy,

                                        -- stroke_gap,
                                        Statin,

                                        case when diabetes_10y = 1 then 1 else 0 end    as diabetes_10y,
                                        case when insulin = 1 then 1 else 0 end         as insulin,
                                        case when TIA = 1 then 1 else 0 end             as TIA,
                                        case when PAD = 1 then 1 else 0 end             as PAD,
                                        case when CAD = 1 then 1 else 0 end             as CAD,
                                        case when PCI = 1 then 1 else 0 end             as PCI,
                                        case when MI = 1 then 1 else 0 end              as MI,
                                        case when stroke = 1 then 1 else 0 end          as stroke,
                                        case when multiple_PCI = 1 then 1 else 0 end    as multiple_PCI,
                                        case when multiple_MI = 1 then 1 else 0 end     as multiple_MI,
                                        case when multiple_stroke = 1 then 1 else 0 end as multiple_stroke
                                ,
                                        case when current_smoker = 1 then 1 else 0 end  as current_smoker,
                                        case when age_over_65 = 1 then 1 else 0 end     as age_over_65
                        from stroke
                                 full outer join MI using (patid)
                                 full outer join PCI using (patid)
                                 full outer join statins using (patid)
                                 full outer join insulin using (patid)
                                 full outer join CAD using (patid)
                                 full outer join TIA using (patid)
                                 full outer join PAD using (patid)
                                 full outer join diabetes_10y using (patid)
                                 full outer join retinopathy using (patid)
                                 full outer join multiple_stroke using (patid)
                                 full outer join multiple_MI using (patid)
                                 full outer join multiple_PCI using (patid)
                                 full outer join smoking using (patid)
                                 full outer join age_65 using (patid)
                                 full outer join labs using (patid)))


select pat_list.cohort,
       sum(PCI)                         as N_PCI,
       sum(MI)                          as N_MI,
       sum(stroke)                      as N_stroke,
       sum(m_1_PCI_MI_stroke)           as N_m_1_PCI_MI_stroke,
       sum(multiple_stroke)             as N_more_than_1_stroke,
       sum(multiple_MI)                 as N_more_than_1_MI,
       sum(multiple_PCI)                as N_more_than_1_PCI,
       sum(m_1_of_PCI_MI_stroke_w_mult) as N_m_1_of_PCI_MI_stroke_w_mult
        ,
       Statin,
       sum(insulin)                     as N_insulin,
       sum(CAD)                         as N_CAD,
       sum(TIA)                         as N_TIA,
       sum(PAD)                         as N_PAD,
       sum(diabetes_10y)                as N_diabetes_10y,
       sum(retinopathy)                 as N_retinopathy,
       sum(m_1_CAD_insulin_PAD_TIA)     as N_m_1_of_CAD_insulin_PAD_TIA,
       sum(current_smoker)              as N_current_smoker,
       sum(age_over_65)                 as N_age_over_65,
       sum(hscrp_over_3)                as N_hscrp_over_3,
       sum(nhdl_over_130)               as N_nhdl_over_130,
       sum(mv_disease)                  as N_mv_disease,

       sum(more_than_1_dm_insulin_mv)   as N_more_than_1_dm_insulin_mv,
       sum(dm_insulin_mv)               as N_dm_insulin_mv,
       sum(dm_insulin_mv_age_over_65)   as N_dm_insulin_mv_age_over_65,
       sum(dm_insulin_mv_smoker)        as N_dm_insulin_mv_smoker,
       sum(dm_insulin_mv_nhdl_over_130) as N_dm_insulin_mv_nhdl_over_130,
       sum(dm_insulin_mv_retinopathy)   as dm_insulin_mv_retinopathy,
       sum(dm_insulin_mv_hscrp_over_3)  as dm_insulin_mv_hscrp_over_3,
       sum(dm_insulin_mv_plus_any)      as N_dm_insulin_mv_plus_any,
       sum(no_CV_or_risk_factors)       as N_no_CV_or_risk_factors,
       count(distinct patid)            as total_count_patients

from pat_list
         left join combined using (patid)
group by pat_list.cohort, Statin

order by pat_list.cohort;



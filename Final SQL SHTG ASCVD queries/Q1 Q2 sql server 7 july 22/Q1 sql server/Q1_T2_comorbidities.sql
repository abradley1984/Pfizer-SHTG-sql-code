/* This query counts comorbidity occurences.

   The output is a table that can be saved to a csv file (Q1_T2.csv) listing counts of patients with specific diagnoses

   Same for Q1 and Q2, with edits to pat_list and changing index date to LDL_date
Run time: ~ 3 mins

   Edits for sql server:
   percentile_cont
   median
   trunc changed to round

   I've left this as a CTE since it doesn't require writing to a table
 */

with pat_list as (select patid, cohort, TG_DATE as index_date
                  from foo.dbo.shtg_Q1_cohort_with_exclusions),



     comorbid_conditions AS ( --All diagnoses for each patient

         SELECT a.patid,

                dx,

                MIN(admit_date) min_date,

                MAX(admit_date) max_date,
                cohort,


                CASE

                    WHEN dx like 'E13%' THEN 'diabetes'

                    WHEN dx like 'E11%' THEN 'diabetes'

                    WHEN dx like 'E10%' THEN 'diabetes'

                   -- WHEN dx like 'E09%' THEN 'diabetes'

                    WHEN dx like 'E08%' THEN 'diabetes'

                    WHEN dx like '249%' THEN 'diabetes'

                    WHEN dx like '250%' THEN 'diabetes'


                  --  WHEN dx like 'H31%' THEN 'retinopathy'

                  --  WHEN dx like 'H35%' THEN 'retinopathy'


                 --   WHEN dx like 'I12%' THEN 'multivessel cad'

                  --  WHEN dx like 'Z95%' THEN 'multivessel cad'


                  --  WHEN dx like 'Z98.61%' THEN 'PCI'


                   -- WHEN dx like '581%' THEN 'NEPHROTIC SYN'

                   -- WHEN dx like 'N04%' THEN 'NEPHROTIC SYN'

                    --WHEN dx like 'Z87.441%' THEN 'NEPHROTIC SYN'


                --    WHEN dx IN ('O42', 'B20', 'B98.35', 'Z21') THEN 'HIV'


               /* --    WHEN dx like '433%' THEN 'STROKE'

                --    WHEN dx like '434%' THEN 'STROKE'

                    WHEN dx like '997.02%' THEN 'STROKE'

                    WHEN dx like 'I63%' THEN 'STROKE'

                    WHEN dx like 'I97.8%' THEN 'STROKE'
*/
/*
                    WHEN dx like 'E66%' THEN 'obesity'

                    WHEN dx like '278%' THEN 'obesity'


                    WHEN dx like '410%' THEN 'MI'

                    WHEN dx IN ('411.0', '411.81', '412', 'I24.0', 'I25.2') THEN 'MI'

                    WHEN dx like 'I21' THEN 'MI'

                    WHEN dx like 'I22%' THEN 'MI'

                    WHEN dx like 'I23%' THEN 'MI'


                    WHEN dx like '996%' THEN 'ORGAN TRN'

                    WHEN dx like 'Z48.2%' THEN 'ORGAN TRN'*/





                     WHEN dx IN ('I10', 'I11.0', 'I11.9', 'I12.0', 'I12.9', 'I15.0', 'I15.1', 'I15.2', 'I15.8', 'I15.9',
                                'I16.0',
                                'I16.1', 'I16.9', '401', '402', '403', '404', '405') THEN 'hypertension'

                    WHEN dx LIKE 'I13%' THEN 'hypertension'



                    WHEN dx = '272' THEN 'Disorders of lipoprotein metabolism and other'
                    WHEN dx = 'E78.01' THEN 'familial hypercholesterolemia'
                    WHEN dx = 'E78.1' THEN 'hypertriglyceridemia'
                    WHEN dx = '272.1' THEN 'hypertriglyceridemia'
                    WHEN dx = 'E78.2' THEN 'mixed hyperlipedimia'
                    WHEN dx = 'E78.3' THEN 'hyperchylomicronemia'
                    WHEN dx = 'E78.41' THEN 'elevated lipoprotien(a)'


                    WHEN dx LIKE 'G45%' THEN 'TIA'
                    WHEN dx LIKE '435%' THEN 'TIA'


                    WHEN dx LIKE 'I20%' THEN 'IHD'

                    WHEN dx LIKE 'I21%' THEN 'IHD'

                    WHEN dx LIKE 'I22%' THEN 'IHD'

                    WHEN dx LIKE 'I23%' THEN 'IHD'

                    WHEN dx LIKE 'I24%' THEN 'IHD'

                    WHEN dx LIKE 'I25%' THEN 'IHD'

WHEN dx in ('440.20',
                                '440.21',
                                '440.22',
                                '440.23',
                                '440.24',
                                '440.29',
                                '440.30',
                                '440.31',
                                '440.32',
                               -- '440.4', -- removed no icd9
                                'I70.0',
                                'I70.1',
                                'I70.201',
                                'I70.202',
                                'I70.203',
                                'I70.208',
                                'I70.209',
                              -- 'I70.21', -- removed
                               -- 'I70.22', -- removed
                                'I70.232',
                               -- 'I70.24', -- removed
                                'I70.25',
                               -- 'I70.26', -- removed
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
                               -- 'I70.3', -- removed
                              -- 'I70.4', -- removed
                                'I70.5',
                                'I70.8',
                                'I70.90',
                                'I70.91',
                                'I70.92') THEN 'PAD'



                    WHEN dx LIKE 'I50%' THEN 'HEART FAILURE'
                    WHEN dx LIKE '428%' THEN 'HEART FAILURE'

                    WHEN dx in ('K85.0', 'K85.00', 'K85.01', 'K85.02', 'K85.1', 'K85.10', 'K85.11', 'K85.12', 'K85.8',
                                'K85.80', 'K85.81', 'K85.82',
                                'K85.9', 'K85.90', 'K85.91', 'K85.92', 'K85', '577.0') THEN 'ACUTE PANCREATITIS'


                    WHEN dx in ( '577.1', 'K86.1', 'K86.2', 'K86.3', 'K86.8', 'K86.81', 'K86.89', 'K86.9')
                        THEN 'CHRONIC PANCREATITIS'


                    --WHEN dx in ('K21.9', 'K21.0') THEN 'gerd'


                    WHEN dx like 'K72%' THEN 'liver_failure'

                    WHEN dx = 'R17' THEN 'jaundice'
                    WHEN dx = '782.4' THEN 'jaundice'

                    WHEN dx = 'R18.8' THEN 'ascites'
                    WHEN dx = '789.5' THEN 'ascites'

                    WHEN dx like 'K74.6%' THEN 'CIRRHOSIS'

                    WHEN dx like 'G93.4%' THEN 'ENCEPHALOPATHY, UNSPEC'
                    WHEN dx = '348.30' THEN 'ENCEPHALOPATHY, UNSPEC'

                    WHEN dx = 'K65.2' THEN 'SPONTANEOUS BACTERIAL PERITONITIS'
                    WHEN dx = '567.23' THEN 'SPONTANEOUS BACTERIAL PERITONITIS'


                    WHEN dx IN ('I85.11', 'I85.01', '465.0', '456.20') THEN
                        'esophageal_varices_w_bleeding'

                    WHEN dx = 'K76.7' THEN 'HEPATORENAL SYND'
                    WHEN dx = '572.4' THEN 'HEPATORENAL SYND'

                    WHEN dx in ('K75.81', '571.8', 'K76.0') THEN 'NAFLD OR NASH'

                    ELSE 'other'
                    END
                    AS          Comorbidity_name





         FROM pat_list a


                  INNER JOIN cdm.dbo.diagnosis b on a.patid = b.patid


         WHERE
b.admit_date<='2021-09-30' and
             (dx IN (
                          'I10',
                         -- 'E66.9', obesity
                          --'E66.01',
                          --'E66.09',
                         -- 'K21.9',gerd
                        --  'K21.0',
                        --  'K76.6',
                        --  'F41.9',
                          'R17',
                          'R18.8',
                          'I85.01',
                          --'I85.10',
                          --'I85.00',
                          'I85.11',
                          'K76.7',
                          'K65.2'
                       --   'K65.0',
                       --   'K65.9'

                 )

-- DX FROM TABLE 9
OR dx like 'K74.6%' -- 'CIRRHOSIS'
                 OR dx like 'E08%' -- diabetes

                -- OR dx like 'E09%' -- diabetes

                 OR dx like 'E10%' -- diabetes

                 OR dx like 'E11%' -- diabetes

                 OR dx like 'E13%' -- diabetes

                 OR dx like '249%' -- diabetes

                 OR dx like '250%' -- diabetes

                 -- OVERLAP BETWEEN RETINOPATHY & DIABETES
/*
                 OR dx like 'H31%' -- RETINOPATHY

                 OR dx like 'H35%' -- RETINOPATHY

                 OR dx like 'I12%' -- MULTIVESSEL CAD

                 OR dx like 'Z95%' -- MULTIVESSEL CAD

                 OR dx = 'Z98.61' -- PCI*/
                 OR dx like 'G93.4%' -- Encephalopathy, other


                 -- NEXT WAS "GUESSING EXCLUDING" TAB, ALL ARE H35 & OVERLAPS WITH RETINOPATHY


                /* OR dx like '581%' -- NEPHROTIC SYN

                 OR dx like 'NO4%' -- NEPHROTIC SYN

                 OR dx = 'Z87.441' -- NEPHROTIC SYN

                 OR dx = '042' -- HIV

                 OR dx = 'B20' -- HIV

                 OR dx = 'B97.35' -- HIV

                 OR dx = 'Z21' -- HIV


                 OR dx like '433%' -- STROKE

                 OR dx like '434%' -- STROKE

                 OR dx = '997.02' -- STROKE

                 OR dx like 'I63%' -- STROKE

                 OR dx like 'I97.8%' -- STROKE

                 OR dx like '278%' -- OBESITY

                 OR dx like 'E66%' -- OBESITY

                 OR dx like '410%' -- MI

                 OR dx = '411.0' -- MI

                 OR dx = '411.81' -- MI

                 OR dx = '412' -- MI

                 OR dx like 'I21%' -- MI

                 OR dx like 'I22%' -- MI

                 OR dx like '123%' -- MI
*/
--
--                  -- ?? IN SPREADSHEET FOR I24 AND I25
--
--                  OR dx = 'I24.0' -- MI
--
--                  OR dx = 'I25.2' -- MI
--
--
--                  OR dx like '996%' -- ORGAN TRN
--
--                  OR dx like 'Z48.2%' -- ORGAN TRN
                  or dx like 'K72%' -- 'liver_failure'


-- DX FROM TABLE 2






                 OR dx like 'G45%' -- TIA
                 OR dx like '435%' -- TIA

                 OR dx like 'I20%' -- IHD

                 OR dx like 'I21%' -- IHD

                 OR dx like 'I22%' -- IHD

                 OR dx like 'I23%' -- IHD

                 OR dx like 'I24%' -- IHD

                 OR dx like 'I25%' -- IHD

                 OR dx like 'I50%' -- HEART FAILURE
                 OR dx like '428%' -- HEART FAILURE

                 OR dx = 'I10' -- HYPERTENSIVE

                 OR dx = 'I11.0' -- HYPERTENSIVE

                 OR dx = 'I11.9' -- HYPERTENSIVE

                 OR dx = 'I12.0' -- HYPERTENSIVE

                 OR dx = 'I12.9' -- HYPERTENSIVE

                 OR dx like 'I13%' -- HYPERTENSIVE

                 OR dx = 'I15.0' -- HYPERTENSIVE

                 OR dx = 'I15.1' -- HYPERTENSIVE

                 OR dx = 'I15.2' -- HYPERTENSIVE

                 OR dx = 'I15.8' -- HYPERTENSIVE

                 OR dx = 'I15.9' -- HYPERTENSIVE

                 OR dx = 'I16.0' -- HYPERTENSIVE

                 OR dx = 'I16.1' -- HYPERTENSIVE

                 OR dx = 'I16.9' -- HYPERTENSIVE

                 OR dx = '401' -- HYPERTENSIVE
                 OR dx = '402' -- HYPERTENSIVE
                 OR dx = '403' -- HYPERTENSIVE
                 OR dx = '404' -- HYPERTENSIVE
                 OR dx = '405' -- HYPERTENSIVE

                -- OR dx like
                 --   ('E78%') -- LIPIDEMIA, Disorders of lipoprotein metabolism and other
                 OR dx = '272' -- LIPIDEMIA, Disorders of lipoprotein metabolism and other
                 OR dx = 'E78.01' -- LIPIDEMIA, familial hypercholesterolemia
                 OR dx = 'E78.1' -- LIPIDEMIA, hypertriglyceridemia
                 OR dx = 'E78.2' -- LIPIDEMIA, mixed hyperlipedimia
                 OR dx = 'E78.3' -- LIPIDEMIA, hyperchylomicronemia
                 OR dx = 'E78.41' -- LIPIDEMIA, elevated lipoprotien(a)
                 OR dx = '272.1' -- LIPIDEMIA, hypertriglyceridemia


                 OR dx in
                    ('K85.0', 'K85.00', 'K85.01', 'K85.02', 'K85.1', 'K85.10', 'K85.11', 'K85.12', 'K85.8', 'K85.80',
                     'K85.81',
                     'K85.82', 'K85.9', 'K85.90', 'K85.91', 'K85.92', 'K85', '577.0') -- ACUTE PANCREATITIS


                 OR dx in ( '577.1', 'K86.1', 'K86.2', 'K86.3', 'K86.8', 'K86.81', 'K86.89'
                                ) -- CHRONIC PANCREATITIS


                 OR dx in ('440.20',
                                '440.21',
                                '440.22',
                                '440.23',
                                '440.24',
                                '440.29',
                                '440.30',
                                '440.31',
                                '440.32',
                               -- '440.4',
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
                                'I70.92')-- PAD

                 OR dx = 'R17' -- JAUNDICE
                 OR dx = '782.4' -- JAUNDICE

                 OR dx = 'R18.8' -- ASCITES
                 OR dx = '789.5' -- ASCITES

                 OR dx in ('I85.11', 'I85.01', '465.0', '456.20') -- ESOPHAGEAL VARICES HEMORRHAGIC

                 OR dx = 'G93.4' -- ENCEPHALOPATHY, UNSPEC
                 OR dx = '348.30' -- ENCEPHALOPATHY, UNSPEC

                 OR dx = 'K76.7' -- HEPATORENAL SYND
                 OR dx = '572.4' -- HEPATORENAL SYND

                 OR dx = 'K65.2' -- SPONTANEOUS BACTERIAL PERITONITIS
                 OR dx = '567.23' -- SPONTANEOUS BACTERIAL PERITONITIS

                 OR dx in ('K75.81', '571.8', 'K76.0') -- NAFLD OR NASH


                 )

         GROUP BY a.patid,
                  cohort,
                  dx




     ),
   Plasmapheresis as (select distinct a.patid, cohort, 'plasmapheresis history' as Comorbidity_name
                        from pat_list a
                                 left join cdm.dbo.procedures b on a.patid = b.patid
                        where   b.admit_date<='2021-09-30' and
                                PX =
                              '36514'),
     'CKD' as Comorbidity_name
             FROM pat_list a


                                    INNER JOIN cdm.dbo.diagnosis b on a.patid = b.patid


             WHERE b.admit_date <= ='2021-09-30'
               and Como.dx in
                   ('249.4',
                    '249.41',
                    '250.4',
                    '250.41',
                    '250.42',
                    '250.43',
                    '285.21',
                    '403',
                    '403.01',
                    '403.1',
                    '403.11',
                    '403.9',
                    '403.91',
                    '404',
                    '404.01',
                    '404.02',
                    '404.03',
                    '404.1',
                    '404.11',
                    '404.12',
                    '404.13',
                    '404.9',
                    '404.91',
                    '404.92',
                    '404.93',
                    '428.9',
                    '583.81',
                    '583.9',
                    '584.5',
                    '584.6',
                    '584.7',
                    '584.8',
                    '584.9',
                    '585.3',
                    '585.4',
                    '585.5',
                    '585.6',
                    '585.9',
                    '586',
                    '587',
                    '588.81',
                    '996.81',
                    'D63.1',
                    'D63.1',
                    'E08.22',
                    'E08.22',
                    'E08.22',
                    'E08.22',
                    'E08.22',
                    'E08.22',
                    'E09.22',
                    'E09.22',
                    'E09.22',
                    'E09.22',
                    'E09.22',
                    'E09.22',
                    'E10.21',
                    'E10.21',
                    'E10.21',
                    'E10.22',
                    'E10.22',
                    'E10.22',
                    'E11.21',
                    'E11.21',
                    'E11.21',
                    'E11.22',
                    'E11.22',
                    'E11.22',
                    'E13.22',
                    'E13.22',
                    'E13.22',
                    'I12.0',
                    'I12.9',
                    'I13.0',
                    'I13.0',
                    'I13.0',
                    'I13.10',
                    'I13.10',
                    'I13.11',
                    'I13.11',
                    'I13.2',
                    'I13.2',
                    'I13.2',
                    'M32.14',
                    'N17.0',
                    'N17.1',
                    'N17.2',
                    'N17.8',
                    'N17.9',
                    'N18.3',
                    'N18.3',
                    'N18.30',
                    'N18.30',
                    'N18.31',
                    'N18.31',
                    'N18.32',
                    'N18.32',
                    'N18.4',
                    'N18.4',
                    'N18.5',
                    'N18.5',
                    'N18.6',
                    'N18.6',
                    'N19',
                    'N25.81',
                    'T86.19',
                    'V42.0',
                    'V45.11',
                    'V56.0',
                    'V56.8',
                    'Z94.0',
                    'Z99.2') --'CKD'
             group by a.patid, cohort),
     comorbidity_group as (select a.patid,
                                  cohort,

                                  max( datediff(dd, admit_date, index_date)) / 365.25              as tx_since_first_lip,
                                  'Disorders of lipoprotein metabolism and other' as Comorbidity_name
                           FROM pat_list a


                                    INNER JOIN cdm.dbo.diagnosis  b on a.patid = b.patid


                           WHERE b.admit_date <= ='2021-09-30' and dx like
                                    ('E78%') -- LIPIDEMIA, Disorders of lipoprotein metabolism and other
                           group by a.patid, cohort),
     ASCVD as (select a.patid,
                      cohort,
                      max(datediff(dd, admit_date, index_date)) / 365.25 as time_since_first_ascvd_diagnosis,
                      'ASCVD'                            as Comorbidity_name
               FROM pat_list a
                        INNER JOIN cdm.dbo.diagnosis b on a.patid = b.patid
               WHERE b.admit_date <='2021-09-30' and dx in ('346.62',
                            '346.63',
                            '410.11',
                            '410.2',
                            '410.3',
                            '410.4',
                            '410.50',
                            '410.51',
                            '410.6',
                            '410.61',
                            '410.62',
                            '410.70',
                            '410.71',
                            '410.72',
                            '410.81',
                            '410.91',
                            '410.92',
                            '411.0',
                            '411.1',
                            '411.81',
                            '411.89',
                            '412',
                            '413.0',
                            '413.9',
                            '414.8',
                            '414.9',
                            '433.01',
                            '433.11',
                            '433.21',
                            '433.31',
                            '433.81',
                            '433.91',
                            '434.01',
                            '434.11',
                            '434.91',
                            '440.20',
                            '440.21',
                            '440.22',
                            '440.23',
                            '440.24',
                            '440.29',
                            '440.30',
                            '440.31',
                            '440.32',
                            '440.4',
                            'G43.601',
                            'G43.601',
                            'G43.609',
                            'G43.609',
                            'G43.611',
                            'G43.611',
                            'G43.619',
                            'G43.619',
                            'I20.0',
                            'I20.8',
                            'I20.9',
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
                            'I21.A9',
                            'I22.0',
                            'I22.1',
                            'I22.2',
                            'I22.8',
                            'I22.9',
                            'I23.0',
                            'I23.3',
                            'I23.6',
                            'I23.7',
                            'I23.8',
                            'I24.0',
                            'I24.1',
                            'I24.8',
                            'I24.9',
                            'I25.110',
                            'I25.111',
                            'I25.118',
                            'I25.119',
                            'I25.2',
                            'I25.5',
                            'I25.5',
                            'I25.6',
                            'I25.700',
                            'I25.701',
                            'I25.708',
                            'I25.709',
                            'I25.710',
                            'I25.720',
                            'I25.730',
                            'I25.738',
                            'I25.750',
                            'I25.751',
                            'I25.760',
                            'I25.790',
                            'I25.791',
                            'I25.89',
                            'I25.9',
                            'I63.00',
                            'I63.011',
                            'I63.012',
                            'I63.019',
                            'I63.02',
                            'I63.031',
                            'I63.032',
                            'I63.09',
                            'I63.10',
                            'I63.112',
                            'I63.12',
                            'I63.19',
                            'I63.311',
                            'I63.312',
                            'I63.319',
                            'I63.321',
                            'I63.323',
                            'I63.333',
                            'I63.343',
                            'I63.412',
                            'I63.413',
                            'I63.429',
                            'I63.431',
                            'I63.511',
                            'I63.519',
                            'I63.531',
                            'I63.539',
                            'I63.59',
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
                            'I70.261',
                            'I70.262',
                            'I70.262',
                            'I70.263',
                            'I70.263',
                            'I70.268',
                            'I70.268',
                            'I70.269',
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
                            'I70.92',
                            'V12.54',
                            'Z86.73')
               group by a.patid,
                        cohort
     ),

     comorbidity_count as
         (
             select '2'                   as order1,
                    count(distinct patid) as N,
                    cohort,
                    Comorbidity_name

             from comorbid_conditions

             group by Comorbidity_name, cohort
             union
             select '1',
                    count(distinct patid) as N,
                    cohort,
                    Comorbidity_name

             from comorbidity_group

             group by Comorbidity_name, cohort
             union
          select '2',
                 count(distinct patid) as N,
                 cohort,
                 Comorbidity_name

          from CKD
            /* union
             select '6',
                    count(distinct patid) as N,
                    cohort,
                    Comorbidity_name

             from PCI

             group by Comorbidity_name, cohort*/
             union
             select '7',
                    count(distinct patid) as N,
                    cohort,
                    Comorbidity_name

             from Plasmapheresis

             group by Comorbidity_name, cohort
             union
             select '8',
                    round(avg(tx_since_first_lip),2) as N,
                    cohort,
                    'Time since first lipidemia diagnosis (Mean)'
             from comorbidity_group
             group by cohort
             union
            /* select '9'                                                 as order1,

                    round(median(tx_since_first_lip),2) as N,
                    cohort,
                    'Time since first lipidemia diagnosis (Median)'
             from comorbidity_group
             group by cohort
             union*/
             select '9'                                                 as order1,

                    round(stdev(tx_since_first_lip),2) as N,
                    cohort,
                    'Time since first lipidemia diagnosis (std)'
             from comorbidity_group
             group by cohort
             union
             select '9' as                                                        order1,

                    PERCENTILE_CONT(0.25) WITHIN
                        GROUP (ORDER BY tx_since_first_lip asc) OVER (PARTITION BY cohort) "pct_25",
                    cohort,
                    'Time since first lipidemia diagnosis (25th pct)'
             from comorbidity_group

             union
             select '9' as order1,
                    PERCENTILE_CONT(0.75) WITHIN
                        GROUP (ORDER BY tx_since_first_lip asc) OVER (PARTITION BY cohort)
                           "pct_75",
                    cohort,
                    'Time since first lipidemia diagnosis (75th pct)'
             from comorbidity_group


             union
             select '9' as                                                        order1,

                    PERCENTILE_CONT(0.5) WITHIN
                        GROUP (ORDER BY tx_since_first_lip asc) OVER (PARTITION BY cohort) "Median",
                    cohort,
                    'Time since first lipidemia diagnosis (Median)'
             from comorbidity_group

             union
             select '10'                                         as order1,
                    round(avg(time_since_first_ascvd_diagnosis),2) as N,
                    cohort,
                    'Time since first ascvd diagnosis (Mean)'
             from ascvd
             group by cohort

             /*union
             select '10'                                            as order1,
                    round(median(time_since_first_ascvd_diagnosis),2) as N,
                    cohort,
                    'Time since first ascvd diagnosis (Median)'
             from ascvd
             group by cohort*/
             union
             select '10'                                            as order1,
                    round(stdev(time_since_first_ascvd_diagnosis),2) as N,
                    cohort,
                    'Time since first ascvd diagnosis (std)'
             from ascvd
             group by cohort
             union
             select '10' as order1,
                    PERCENTILE_CONT(0.25) WITHIN
                        GROUP (ORDER BY time_since_first_ascvd_diagnosis asc) OVER (PARTITION BY cohort)
                            "pct_25",
                    cohort,
                    'Time since first ascvd diagnosis (25th pct)'
             from ascvd

             union
             select '10' as order1,
                    PERCENTILE_CONT(0.5) WITHIN
                        GROUP (ORDER BY time_since_first_ascvd_diagnosis asc) OVER (PARTITION BY cohort)
                            "Median",
                    cohort,
                    'Time since first ascvd diagnosis (Median)'
             from ascvd

             union
             select '10' as order1,
                    PERCENTILE_CONT(0.75) WITHIN
                        GROUP (ORDER BY time_since_first_ascvd_diagnosis asc) OVER (PARTITION BY cohort)
                            "pct_75",
                    cohort,
                    'Time since first ascvd diagnosis (75th pct)'
             from ascvd

         ),
     table2 as (select order1, 'Comorbidity' as comorbidity, Comorbidity_name, round(N, 2) as N_mean_etc, cohort
                from comorbidity_count
              /*  order by cohort*/),
      totals as (select count(distinct patid) as N_cohort_total, cohort From pat_list group by cohort),

     percentages as (select
                              a.Cohort,
                            order1,
                             Comorbidity_name,

                     N_mean_etc,

                            N_cohort_total,
                            case
                                when (Comorbidity_name like '%75%'
                                or Comorbidity_name like '%25%'
                                    or Comorbidity_name like ('%Mean%')
                                    or Comorbidity_name like ('%Median%')
                                    or Comorbidity_name like ('%std%'))
                                    then 0
                                else
                                    round(100 * N_mean_etc/ N_cohort_total, 2)
                                end
                                as percentage1
                     from table2 a
                              left join totals b on a.cohort= b.cohort
     )


select *
from percentages
order by cohort, order1;




/* 
 This code outputs:
   1. the distribution of lab results with the lab result unit.
     I want to make sure I’m accounting for all units that come up at each site (e.g. mg/dL vs g/dL)

   2. The distribution of primary payer type categories (insurance) so I can make sure I'm aggregating appropriately.
   I realize not all sites populate this info, so let me know if that's the case for your site.

where it says "Pitt" for site_name (both queries) below, please replace with an identifier for your site.
This version runs in oracle.
 I've included what I think are the edits needed for a sql server version as comments, although I haven't checked so please let the group know if more edits are needed.

 */
select 'Pitt'          as                                           site_name,
       count(result_num),
       result_unit,
       lab_loinc,
       raw_lab_name,
       median(result_num)                                           median,
       trunc(avg(result_num), 2)                                    mean,
       trunc(STDDEV(result_num), 2)                                 std,
       PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY result_num asc) "pct_25",
       PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY result_num asc) "pct_75"
        ,
       min(result_num) as                                           min,
       max(result_num) as                                           max
from CDM_60_etl.lab_result_cm
where result_date BETWEEN TO_DATE('09/30/2020', 'MM/DD/YYYY') AND TO_DATE('09/30/2021', 'MM/DD/YYYY')
   --sql server: where result_date BETWEEN '2020-09-30' AND '2021-09-30'
  and result_num is not null
      and lab_loinc in (
                    '17856-6',
'41995-2',
'4549-2',
'4548-4',
'1751-7',
'61151-7',
'2862-1',
'61152-5',
'6768-6',
'15014-4',
'15015-1',
'15016-9',
'35707-9',
'15013-6',
'17838-4',
'1777-2',
'13874-3',
'13875-0',
'15349-4',
'1778-0',
'40793-2',
'15348-6',
'40797-3',
'16182-8',
'42718-7',
'49243-9',
'1783-0',
'1779-8',
'33421-9',
'12805-8',
'1742-6',
'1743-4',
'1744-2',
'1869-7',
'1874-7',
'55724-9',
'1884-6',
'1871-3',
'1881-2',
'1920-8',
'30239-8',
'2324-2',
'2085-9',
'30522-7',
'35648-5',
'13457-7',
'18262-6',
'2089-1',
'3046-0',
'55440-2',
'24331-1',
'43583-4',
'10835-7',
'35388-8',
'86222-7',
'43729-3',
'49748-7',
'62253-0',
'17845-9',
'770-8',
'26505-8',
'769-0',
'764-1',
'26508-2',
'35332-6',
'32200-8',
'23761-0',
'26511-6',
'26499-4',
'26524-9',
'43396-1',
'777-3',
'26515-7',
'49497-1',
'778-1',
'2571-8',
'2093-3',
'9318-7',
'13705-9',
'32294-1',
'14585-4',
'46986-6',
'13458-5',
'2091-7',
'2160-0',
'38483-4')
group by result_unit, lab_loinc, raw_lab_name;

--Insurance_counts.csv
select 'Pitt' as site_name, count(distinct patid), payer_type_primary
from CDM_60_ETL.encounter
where admit_date BETWEEN TO_DATE('9/30/2020', 'MM/DD/YYYY') AND TO_DATE('9/30/2021', 'MM/DD/YYYY')
 --sql server: where admit_date BETWEEN '2020-09-30' AND '2021-09-30'
  and raw_payer_type_primary is not null
group by payer_type_primary;




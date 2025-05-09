/*-----------------------------------------------------------
  Calculate χ² for association between KRAS & TP53 mutations
  in pancreatic adenocarcinoma (PAAD) TCGA patients
-----------------------------------------------------------*/
WITH paad_patients AS (   /* 1.  Cohort : clinical PAAD cases            */
    SELECT DISTINCT
           "bcr_patient_barcode"           AS patient_barcode
    FROM   PANCANCER_ATLAS_2.PANCANCER_ATLAS."FILTERED_CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP"
    WHERE  "acronym" = 'PAAD'
),

mutation_flags AS (       /* 2.  Mutation flags per patient (PASS only)  */
    SELECT
        p.patient_barcode,
        MAX(CASE WHEN m."Hugo_Symbol" = 'KRAS'  THEN 1 ELSE 0 END) AS kras_mut,
        MAX(CASE WHEN m."Hugo_Symbol" = 'TP53'  THEN 1 ELSE 0 END) AS tp53_mut
    FROM   paad_patients                                        p
    LEFT JOIN PANCANCER_ATLAS_2.PANCANCER_ATLAS."FILTERED_MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"  m
           ON  m."ParticipantBarcode" = p.patient_barcode
           AND m."Study"              = 'PAAD'
           AND m."FILTER"             = 'PASS'         -- high-quality calls
    GROUP BY p.patient_barcode
),

contingency AS (          /* 3.  2×2 observed counts                    */
    SELECT
        SUM(CASE WHEN kras_mut = 1 AND tp53_mut = 1 THEN 1 ELSE 0 END) AS both_mut,
        SUM(CASE WHEN kras_mut = 1 AND tp53_mut = 0 THEN 1 ELSE 0 END) AS kras_only,
        SUM(CASE WHEN kras_mut = 0 AND tp53_mut = 1 THEN 1 ELSE 0 END) AS tp53_only,
        SUM(CASE WHEN kras_mut = 0 AND tp53_mut = 0 THEN 1 ELSE 0 END) AS neither
    FROM   mutation_flags
),

totals AS (               /* 4.  Marginal totals                        */
    SELECT  *,
            (both_mut + kras_only + tp53_only + neither)                AS total,
            (both_mut + kras_only)                                      AS kras_total,
            (both_mut + tp53_only)                                      AS tp53_total
    FROM    contingency
),

expected AS (             /* 5.  Expected counts under independence     */
    SELECT
        both_mut , kras_only , tp53_only , neither , total ,
        kras_total , tp53_total ,
        (kras_total * tp53_total)::DOUBLE / total                    AS exp_both,
        (kras_total * (total - tp53_total))::DOUBLE / total          AS exp_kras_only,
        ((total - kras_total) * tp53_total)::DOUBLE / total          AS exp_tp53_only,
        ((total - kras_total) * (total - tp53_total))::DOUBLE / total AS exp_neither
    FROM totals
)

/* 6.  χ² statistic */
SELECT
       both_mut,
       kras_only,
       tp53_only,
       neither,
       ROUND(
             POWER(both_mut   - exp_both      ,2)/exp_both       +
             POWER(kras_only  - exp_kras_only ,2)/exp_kras_only  +
             POWER(tp53_only  - exp_tp53_only ,2)/exp_tp53_only  +
             POWER(neither    - exp_neither   ,2)/exp_neither
       ,4)                                                      AS chi_squared_statistic
FROM   expected;
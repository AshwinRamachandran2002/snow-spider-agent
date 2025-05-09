/*---------------------------------------------------------------
  Chi–squared test of association between KRAS and TP53 mutations
  in TCGA Pancreatic Adenocarcinoma (PAAD) cohort – division-safe
----------------------------------------------------------------*/
WITH
/* 1. All PAAD participants ------------------------------------*/
paad_patients AS (
    SELECT DISTINCT
           "bcr_patient_barcode" AS "ParticipantBarcode"
    FROM   PANCANCER_ATLAS_2.PANCANCER_ATLAS."FILTERED_CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP"
    WHERE  "acronym" = 'PAAD'
),

/* 2. High-quality aliquots ------------------------------------*/
quality_aliquots AS (
    SELECT DISTINCT
           "aliquot_barcode"
    FROM   PANCANCER_ATLAS_2.PANCANCER_ATLAS."MERGED_SAMPLE_QUALITY_ANNOTATIONS"
    WHERE  COALESCE("Do_not_use",'False') <> 'True'
),

/* 3. High-quality KRAS / TP53 mutations -----------------------*/
high_quality_mut AS (
    SELECT
           m."ParticipantBarcode",
           m."Hugo_Symbol"
    FROM   PANCANCER_ATLAS_2.PANCANCER_ATLAS."FILTERED_MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE" m
           JOIN paad_patients  p ON p."ParticipantBarcode" = m."ParticipantBarcode"
           JOIN quality_aliquots q ON q."aliquot_barcode" = m."Tumor_AliquotBarcode"
    WHERE  m."FILTER" = 'PASS'
      AND  m."Hugo_Symbol" IN ('KRAS','TP53')
),

/* 4. Per-patient mutation flags -------------------------------*/
patient_mut_status AS (
    SELECT
           "ParticipantBarcode",
           MAX(CASE WHEN "Hugo_Symbol" = 'KRAS' THEN 1 ELSE 0 END) AS kras_mutated,
           MAX(CASE WHEN "Hugo_Symbol" = 'TP53' THEN 1 ELSE 0 END) AS tp53_mutated
    FROM   high_quality_mut
    GROUP BY "ParticipantBarcode"
),

/* 5. Merge flags with full PAAD cohort ------------------------*/
all_pa_pats AS (
    SELECT
           pp."ParticipantBarcode",
           COALESCE(pms.kras_mutated ,0) AS kras_mutated,
           COALESCE(pms.tp53_mutated ,0) AS tp53_mutated
    FROM   paad_patients pp
           LEFT JOIN patient_mut_status pms USING ("ParticipantBarcode")
),

/* 6. 2×2 contingency counts -----------------------------------*/
contingency AS (
    SELECT
        SUM(CASE WHEN kras_mutated=1 AND tp53_mutated=1 THEN 1 ELSE 0 END)::INT AS both_mut,
        SUM(CASE WHEN kras_mutated=1 AND tp53_mutated=0 THEN 1 ELSE 0 END)::INT AS kras_only,
        SUM(CASE WHEN kras_mutated=0 AND tp53_mutated=1 THEN 1 ELSE 0 END)::INT AS tp53_only,
        SUM(CASE WHEN kras_mutated=0 AND tp53_mutated=0 THEN 1 ELSE 0 END)::INT AS neither_mut
    FROM   all_pa_pats
),

/* 7. Row/column totals & expected counts (division-safe) ------*/
expected AS (
    SELECT
        both_mut, kras_only, tp53_only, neither_mut,
        (both_mut + kras_only + tp53_only + neither_mut)                    AS total_n,
        (both_mut + kras_only)                                              AS kras_yes,
        (tp53_only + neither_mut)                                           AS kras_no,
        (both_mut + tp53_only)                                              AS tp53_yes,
        (kras_only + neither_mut)                                           AS tp53_no
    FROM contingency
)

/* 8. Chi-squared statistic ------------------------------------*/
SELECT
    both_mut,
    kras_only,
    tp53_only,
    neither_mut,
    total_n,
    ROUND(
          COALESCE(POWER(both_mut    - (kras_yes * tp53_yes)::FLOAT  / NULLIF(total_n,0),2)
                   / NULLIF((kras_yes * tp53_yes)::FLOAT  / NULLIF(total_n,0),0),0)
        + COALESCE(POWER(kras_only   - (kras_yes * tp53_no )::FLOAT  / NULLIF(total_n,0),2)
                   / NULLIF((kras_yes * tp53_no )::FLOAT  / NULLIF(total_n,0),0),0)
        + COALESCE(POWER(tp53_only   - (kras_no  * tp53_yes)::FLOAT  / NULLIF(total_n,0),2)
                   / NULLIF((kras_no  * tp53_yes)::FLOAT  / NULLIF(total_n,0),0),0)
        + COALESCE(POWER(neither_mut - (kras_no  * tp53_no )::FLOAT  / NULLIF(total_n,0),2)
                   / NULLIF((kras_no  * tp53_no )::FLOAT  / NULLIF(total_n,0),0),0)
    ,4) AS chi_squared_statistic
FROM expected;
/*---------------------------------------------------------------
  Chi-squared test for association between KRAS and TP53 mutation
  status in Pancreatic Adenocarcinoma (PAAD) TCGA patients.
----------------------------------------------------------------*/
WITH paad_patients AS (          -- clinical roster (ensures follow-up data present)
    SELECT DISTINCT
           "bcr_patient_barcode"            AS patient_barcode
    FROM   PANCANCER_ATLAS_2.PANCANCER_ATLAS."FILTERED_CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP"
    WHERE  "acronym" = 'PAAD'
),

kras_tp53_calls AS (             -- high-quality MC3 mutation calls, PASS only
    SELECT DISTINCT
           m."ParticipantBarcode"           AS patient_barcode,
           CASE WHEN m."Hugo_Symbol" = 'KRAS' THEN 1 ELSE 0 END  AS is_kras,
           CASE WHEN m."Hugo_Symbol" = 'TP53' THEN 1 ELSE 0 END  AS is_tp53
    FROM   PANCANCER_ATLAS_2.PANCANCER_ATLAS."FILTERED_MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE" m
           JOIN paad_patients p
             ON p.patient_barcode = m."ParticipantBarcode"
    WHERE  m."Hugo_Symbol" IN ('KRAS','TP53')
      AND  m."FILTER" = 'PASS'
),

per_patient_flags AS (           -- 1/0 flags per patient
    SELECT
           patient_barcode,
           MAX(is_kras) AS mutated_kras,
           MAX(is_tp53) AS mutated_tp53
    FROM   kras_tp53_calls
    GROUP  BY patient_barcode
),

final_flags AS (                 -- add mutation-absent patients
    SELECT
           p.patient_barcode,
           COALESCE(f.mutated_kras ,0) AS mutated_kras,
           COALESCE(f.mutated_tp53,0) AS mutated_tp53
    FROM   paad_patients  p
           LEFT JOIN per_patient_flags f
                  ON f.patient_barcode = p.patient_barcode
),

agg AS (                         -- core counts
    SELECT
        COUNT(*)                                                  AS n_total,
        SUM(mutated_kras)                                         AS n_kras,
        SUM(mutated_tp53)                                         AS n_tp53,
        SUM(CASE WHEN mutated_kras=1 AND mutated_tp53=1 THEN 1 END) AS n_both
    FROM final_flags
),

contingency AS (                 -- 2×2 observed table
    SELECT
        n_total,
        n_kras,
        n_tp53,
        n_both,
        (n_kras   - n_both)                                       AS n_kras_only,
        (n_tp53   - n_both)                                       AS n_tp53_only,
        (n_total  - n_kras - n_tp53 + n_both)                     AS n_neither
    FROM agg
),

expected AS (                    -- expected counts under independence
    SELECT
        *,
        (n_kras * n_tp53)::FLOAT / n_total                        AS e_both,
        (n_kras * (n_total - n_tp53))::FLOAT / n_total            AS e_kras_only,
        ((n_total - n_kras) * n_tp53)::FLOAT / n_total            AS e_tp53_only,
        ((n_total - n_kras) * (n_total - n_tp53))::FLOAT / n_total AS e_neither
    FROM contingency
),

chi_sq AS (                      -- chi-squared statistic
    SELECT
        n_total, n_kras, n_tp53,
        n_both, n_kras_only, n_tp53_only, n_neither,
        e_both, e_kras_only, e_tp53_only, e_neither,
        /* Χ² = Σ (O-E)² / E */
        ((n_both       - e_both      )*(n_both       - e_both      ))/e_both       +
        ((n_kras_only  - e_kras_only )*(n_kras_only  - e_kras_only ))/e_kras_only  +
        ((n_tp53_only  - e_tp53_only )*(n_tp53_only  - e_tp53_only ))/e_tp53_only  +
        ((n_neither    - e_neither   )*(n_neither    - e_neither   ))/e_neither
        AS chi_squared_statistic
    FROM expected
)

SELECT *
FROM   chi_sq;
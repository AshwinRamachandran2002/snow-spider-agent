/*-----------------------------------------------------------
  Chi-square test for association between KRAS and TP53
  mutations in pancreatic adenocarcinoma (PAAD) patients
  using TCGA Pan-Cancer Atlas data (Snowflake syntax)
-----------------------------------------------------------*/
WITH paad_patients AS (          -- PAAD clinical cohort
    SELECT DISTINCT
           "bcr_patient_barcode"  AS patient_barcode
    FROM   PANCANCER_ATLAS_2.PANCANCER_ATLAS.FILTERED_CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP
    WHERE  "acronym" = 'PAAD'
),

mut_flags AS (                   -- mutation flags per patient
    SELECT
           "ParticipantBarcode"                         AS patient_barcode,
           MAX(IFF("Hugo_Symbol" = 'KRAS' , 1, 0))      AS KRAS_mut,
           MAX(IFF("Hugo_Symbol" = 'TP53' , 1, 0))      AS TP53_mut
    FROM   PANCANCER_ATLAS_2.PANCANCER_ATLAS.FILTERED_MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE
    WHERE  "Study" = 'PAAD'
    GROUP  BY "ParticipantBarcode"
),

patient_mut AS (                 -- merge clinical & mutation data
    SELECT
           p.patient_barcode,
           COALESCE(m.KRAS_mut , 0) AS KRAS_mut,
           COALESCE(m.TP53_mut , 0) AS TP53_mut
    FROM   paad_patients p
    LEFT   JOIN mut_flags m
           ON p.patient_barcode = m.patient_barcode
),

counts AS (                      -- contingency table counts
    SELECT
        SUM(IFF(KRAS_mut = 1 AND TP53_mut = 1 , 1 , 0)) AS a_both,
        SUM(IFF(KRAS_mut = 1 AND TP53_mut = 0 , 1 , 0)) AS b_kras_only,
        SUM(IFF(KRAS_mut = 0 AND TP53_mut = 1 , 1 , 0)) AS c_tp53_only,
        SUM(IFF(KRAS_mut = 0 AND TP53_mut = 0 , 1 , 0)) AS d_neither
    FROM   patient_mut
),

stats AS (                       -- totals for expected counts
    SELECT
        a_both, b_kras_only, c_tp53_only, d_neither,
        (a_both + b_kras_only + c_tp53_only + d_neither)                 AS n_total,
        (a_both + b_kras_only)                                           AS row_kras_pos,
        (c_tp53_only + d_neither)                                        AS row_kras_neg,
        (a_both + c_tp53_only)                                           AS col_tp53_pos,
        (b_kras_only + d_neither)                                        AS col_tp53_neg
    FROM counts
),

expected AS (                    -- expected frequencies
    SELECT
        *,
        CAST(row_kras_pos * col_tp53_pos AS FLOAT) / n_total  AS exp_a,
        CAST(row_kras_pos * col_tp53_neg AS FLOAT) / n_total  AS exp_b,
        CAST(row_kras_neg * col_tp53_pos AS FLOAT) / n_total  AS exp_c,
        CAST(row_kras_neg * col_tp53_neg AS FLOAT) / n_total  AS exp_d
    FROM stats
),

chi_sq AS (                      -- χ² statistic components
    SELECT
        a_both           AS obs_a,
        b_kras_only      AS obs_b,
        c_tp53_only      AS obs_c,
        d_neither        AS obs_d,
        exp_a, exp_b, exp_c, exp_d,
        POWER(a_both      - exp_a, 2) / exp_a           AS chi_a,
        POWER(b_kras_only - exp_b, 2) / exp_b           AS chi_b,
        POWER(c_tp53_only - exp_c, 2) / exp_c           AS chi_c,
        POWER(d_neither   - exp_d, 2) / exp_d           AS chi_d
    FROM expected
)

SELECT
    ROUND(chi_a + chi_b + chi_c + chi_d, 4)  AS chi_squared_statistic,
    obs_a                                    AS observed_both_mutated,
    obs_b                                    AS observed_KRAS_only,
    obs_c                                    AS observed_TP53_only,
    obs_d                                    AS observed_neither,
    ROUND(exp_a,4)                           AS expected_both_mutated,
    ROUND(exp_b,4)                           AS expected_KRAS_only,
    ROUND(exp_c,4)                           AS expected_TP53_only,
    ROUND(exp_d,4)                           AS expected_neither,
    (obs_a + obs_b + obs_c + obs_d)          AS total_patients
FROM chi_sq;
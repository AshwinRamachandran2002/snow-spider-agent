WITH tumor_samples AS (   -- LGG tumor samples present in the mutation table
    SELECT DISTINCT
           "ParticipantBarcode",
           "Tumor_SampleBarcode" AS "SampleBarcode"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE "Study" = 'LGG'
),

tp53_mutated_patients AS (   -- LGG patients with at least one PASS TP53 mutation
    SELECT DISTINCT
           "ParticipantBarcode"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE "Study"       = 'LGG'
      AND "Hugo_Symbol" = 'TP53'
      AND "FILTER"      = 'PASS'
),

expr_per_sample AS (         -- log10‑transformed DRG2 expression
    SELECT
           e."ParticipantBarcode",
           LOG(10, e."normalized_count" + 1) AS log_expr          -- LOG(base, value) in Snowflake
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED" e
    JOIN tumor_samples s
         ON e."SampleBarcode" = s."SampleBarcode"
    WHERE e."Study"  = 'LGG'
      AND e."Symbol" = 'DRG2'
),

expr_per_patient AS (        -- average log‑expression per patient
    SELECT
           "ParticipantBarcode",
           AVG(log_expr) AS avg_log_expr
    FROM expr_per_sample
    GROUP BY "ParticipantBarcode"
),

patient_groups AS (          -- label patients by TP53 mutation status
    SELECT
           p."ParticipantBarcode",
           p.avg_log_expr,
           CASE WHEN m."ParticipantBarcode" IS NOT NULL THEN 'YES' ELSE 'NO' END AS tp53_mut
    FROM expr_per_patient p
    LEFT JOIN tp53_mutated_patients m
           ON p."ParticipantBarcode" = m."ParticipantBarcode"
),

sums AS (                    -- counts, sums, sums‑of‑squares
    SELECT
        SUM(CASE WHEN tp53_mut = 'YES' THEN 1 ELSE 0 END)                       AS Ny,
        SUM(CASE WHEN tp53_mut = 'NO'  THEN 1 ELSE 0 END)                       AS Nn,
        SUM(CASE WHEN tp53_mut = 'YES' THEN avg_log_expr           END)         AS Sy,
        SUM(CASE WHEN tp53_mut = 'NO'  THEN avg_log_expr           END)         AS Sn,
        SUM(CASE WHEN tp53_mut = 'YES' THEN avg_log_expr * avg_log_expr END)    AS Qy,
        SUM(CASE WHEN tp53_mut = 'NO'  THEN avg_log_expr * avg_log_expr END)    AS Qn
    FROM patient_groups
),

stats AS (                   -- means and variances
    SELECT
        Ny,
        Nn,
        Sy / Ny                                            AS avg_y,
        Sn / Nn                                            AS avg_n,
        (Qy - Sy * Sy / Ny) / (Ny - 1)                     AS var_y,
        (Qn - Sn * Sn / Nn) / (Nn - 1)                     AS var_n
    FROM sums
)

-- Welch’s T‑score: DRG2 expression vs TP53 mutation status in LGG
SELECT
       Ny,                        -- # TP53‑mutant patients
       Nn,                        -- # TP53‑wild‑type patients
       avg_y,                     -- mean DRG2 (mutant)
       avg_n,                     -- mean DRG2 (non‑mutant)
       (avg_y - avg_n)
       / SQRT( var_y / Ny + var_n / Nn ) AS tscore
FROM stats;
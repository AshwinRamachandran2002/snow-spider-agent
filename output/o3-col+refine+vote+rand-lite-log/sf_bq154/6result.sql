/*-----------------------------------------------------------
  Kruskal-Wallis H-score for IGF2 expression (log10(norm_cnt + 1))
  across ICD-O-3 histology groups (only groups with >1 sample).
-----------------------------------------------------------*/
WITH expr AS (  -- log10-scaled IGF2 expression per patient
    SELECT
        c."icd_o_3_histology",
        LOG(10, g."normalized_count" + 1) AS log_expr
    FROM  PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED"  c
    JOIN  PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED" g
          ON g."ParticipantBarcode" = c."bcr_patient_barcode"
    WHERE g."Symbol" = 'IGF2'
      AND g."normalized_count" IS NOT NULL
      AND NOT REGEXP_LIKE(c."icd_o_3_histology", '^\\[.*\\]$')        -- exclude bracketed codes
),
ranked AS (     -- average rank per patient (handles ties)
    SELECT
        "icd_o_3_histology",
        (
          RANK()  OVER (ORDER BY log_expr) +
          RANK()  OVER (ORDER BY log_expr) +
          COUNT(*) OVER (PARTITION BY log_expr) - 1
        ) / 2.0                     AS avg_rank
    FROM expr
),
grp AS (        -- nᵢ , Sᵢ , Qᵢ  for each histology
    SELECT
        "icd_o_3_histology",
        COUNT(*)                AS n_i,
        SUM(avg_rank)           AS S_i,
        SUM(POWER(avg_rank,2))  AS Q_i
    FROM ranked
    GROUP BY "icd_o_3_histology"
    HAVING COUNT(*) > 1
),
totals AS (     -- global aggregates for H-score
    SELECT
        SUM(n_i)                         AS N,
        SUM(S_i)                         AS S_sum,
        SUM(Q_i)                         AS Q_sum,
        SUM(POWER(S_i,2)/n_i)            AS S2_over_n_sum
    FROM grp
)
SELECT
    (SELECT COUNT(*) FROM grp)                                       AS "n_groups",
    t.N                                                              AS "n_samples",
    ROUND(
        ( (t.N - 1) * ( t.S2_over_n_sum - POWER(t.S_sum,2)/t.N ) )
        / NULLIF( t.Q_sum - POWER(t.S_sum,2)/t.N , 0 )
    , 4)                                                             AS "H_score"
FROM totals t;
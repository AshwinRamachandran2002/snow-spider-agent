/*  Kruskal-Wallis H for IGF2 expression (log10-like LOG(10,x+1)) 
    across ICD-O-3 histology groups, excluding groups with ≤1 patient */

WITH expr_values AS (                -- 1. expression + histology after filters
    SELECT
        c."icd_o_3_histology"               AS "hist",
        LOG(10, e."normalized_count" + 1)   AS "log_expr"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED"  e
    JOIN PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED"            c
          ON e."ParticipantBarcode" = c."bcr_patient_barcode"
    WHERE e."Symbol" = 'IGF2'
      AND e."normalized_count" IS NOT NULL
      AND NOT REGEXP_LIKE(c."icd_o_3_histology", '^\\[.*\\]$')
),

ranked AS (                           -- 2. rank each observation (ties handled)
    SELECT
        "hist",
        RANK()  OVER (ORDER BY "log_expr")        AS "start_rank",
        COUNT(*) OVER (PARTITION BY "log_expr")   AS "tie_cnt"
    FROM expr_values
),

ranked_with_rank AS (                 -- 3. average rank per observation
    SELECT
        "hist",
        ("start_rank" + ("tie_cnt" - 1) / 2.0)    AS "rank_val"
    FROM ranked
),

grp AS (                              -- 4. per-histology aggregates
    SELECT
        "hist",
        COUNT(*)                      AS "n_i",
        SUM("rank_val")               AS "S_i",
        SUM(POWER("rank_val", 2))     AS "Q_i"
    FROM ranked_with_rank
    GROUP BY "hist"
    HAVING COUNT(*) > 1
),

totals AS (                           -- 5. totals for H statistic
    SELECT
        SUM("n_i")                             AS "N",
        SUM("S_i")                             AS "sum_S",
        SUM(POWER("S_i", 2) / "n_i")           AS "sum_S2_over_n",
        SUM("Q_i")                             AS "sum_Q",
        COUNT(*)                               AS "g"
    FROM grp
)

-- 6. final Kruskal-Wallis H plus counts
SELECT
    "g"  AS "total_groups",
    "N"  AS "total_samples",
    (("N" - 1) * ("sum_S2_over_n" - POWER("sum_S", 2) / "N"))
      / ("sum_Q" - POWER("sum_S", 2) / "N")     AS "kruskal_wallis_H"
FROM totals
ORDER BY "kruskal_wallis_H" DESC NULLS LAST;
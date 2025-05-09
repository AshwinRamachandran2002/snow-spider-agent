WITH
-- LGG participants carrying at least one PASS TP53 mutation
tp53_mutated AS (
    SELECT DISTINCT "ParticipantBarcode"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE
    WHERE "Study" = 'LGG'
      AND "Hugo_Symbol" = 'TP53'
      AND "FILTER" = 'PASS'
),
-- per‑participant DRG2 expression: average log10(normalized_count + 1)
expr AS (
    SELECT
        "ParticipantBarcode",
        AVG( LOG(10, "normalized_count" + 1) ) AS expr_val
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED
    WHERE "Study" = 'LGG'
      AND "Symbol" = 'DRG2'
    GROUP BY "ParticipantBarcode"
),
-- tag each participant as mutated / non‑mutated
flagged AS (
    SELECT
        e."ParticipantBarcode",
        e.expr_val,
        CASE WHEN m."ParticipantBarcode" IS NOT NULL THEN 1 ELSE 0 END AS is_mut
    FROM expr e
    LEFT JOIN tp53_mutated m
           ON e."ParticipantBarcode" = m."ParticipantBarcode"
),
-- aggregate counts, sums, sums of squares for both groups
stats AS (
    SELECT
        SUM(CASE WHEN is_mut = 1 THEN 1 ELSE 0 END)                          AS n_mut,
        SUM(CASE WHEN is_mut = 0 THEN 1 ELSE 0 END)                          AS n_non,
        SUM(CASE WHEN is_mut = 1 THEN expr_val ELSE 0 END)                   AS s_mut,
        SUM(CASE WHEN is_mut = 0 THEN expr_val ELSE 0 END)                   AS s_non,
        SUM(CASE WHEN is_mut = 1 THEN expr_val*expr_val ELSE 0 END)          AS q_mut,
        SUM(CASE WHEN is_mut = 0 THEN expr_val*expr_val ELSE 0 END)          AS q_non
    FROM flagged
)
SELECT
    CASE
        WHEN n_mut >= 10
         AND n_non >= 10
         AND var_mut > 0
         AND var_non > 0
        THEN ROUND( (mean_mut - mean_non) / SQRT(var_mut / n_mut + var_non / n_non) , 2)
        ELSE NULL
    END AS t_score
FROM (
    SELECT *,
        s_mut / n_mut                                        AS mean_mut,
        s_non / n_non                                        AS mean_non,
        (q_mut - s_mut*s_mut / n_mut) / (n_mut - 1)          AS var_mut,
        (q_non - s_non*s_non / n_non) / (n_non - 1)          AS var_non
    FROM stats
);
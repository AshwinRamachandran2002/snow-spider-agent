WITH mutated AS (
    -- LGG participants with at least one PASS-filtered TP53 mutation
    SELECT DISTINCT "ParticipantBarcode"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE "Study" = 'LGG'
      AND "Hugo_Symbol" = 'TP53'
      AND "FILTER" = 'PASS'
),
expr AS (
    -- Per-participant average log10 expression of DRG2
    SELECT
        "ParticipantBarcode",
        AVG(LOG(10, "normalized_count" + 1)) AS avg_log_expr      -- log10(x+1)
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED"
    WHERE "Study" = 'LGG'
      AND "Symbol" = 'DRG2'
    GROUP BY "ParticipantBarcode"
),
stats AS (
    -- Summary stats for TP53-mutated (Y) and non-mutated (N) groups
    SELECT
        CASE WHEN m."ParticipantBarcode" IS NOT NULL THEN 'Y' ELSE 'N' END AS tp53_mut,
        COUNT(*)                              AS n,
        AVG(e.avg_log_expr)                   AS mean_expr,
        VAR_SAMP(e.avg_log_expr)              AS var_expr
    FROM expr e
    LEFT JOIN mutated m
           ON e."ParticipantBarcode" = m."ParticipantBarcode"
    GROUP BY 1
    HAVING COUNT(*) >= 10
       AND VAR_SAMP(e.avg_log_expr) > 0
)
-- Welch’s t-score (mutated − non-mutated)
SELECT
    ROUND(
        (mut.mean_expr - nomut.mean_expr)
        / SQRT( (mut.var_expr / mut.n) + (nomut.var_expr / nomut.n) ),
        2
    ) AS "Welch_t_score"
FROM stats mut
JOIN stats nomut
  ON mut.tp53_mut = 'Y'
 AND nomut.tp53_mut = 'N';
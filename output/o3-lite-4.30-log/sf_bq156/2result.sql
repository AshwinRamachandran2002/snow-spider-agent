WITH expr AS (
    SELECT
        e."ParticipantBarcode",
        AVG(LOG(10, e."normalized_count" + 1)) AS expr_avg
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED" e
    WHERE e."Study" = 'LGG'
      AND e."Symbol" = 'DRG2'
    GROUP BY e."ParticipantBarcode"
),
tp53_mut AS (
    SELECT DISTINCT "ParticipantBarcode"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE "Study" = 'LGG'
      AND "Hugo_Symbol" = 'TP53'
      AND "FILTER" = 'PASS'
),
classed AS (
    SELECT
        ex."ParticipantBarcode",
        ex.expr_avg,
        CASE WHEN tm."ParticipantBarcode" IS NULL THEN 0 ELSE 1 END AS is_mut
    FROM expr ex
    LEFT JOIN tp53_mut tm
           ON ex."ParticipantBarcode" = tm."ParticipantBarcode"
),
stats AS (
    SELECT
        is_mut,
        COUNT(*)            AS n,
        AVG(expr_avg)       AS mean_expr,
        VAR_SAMP(expr_avg)  AS var_expr
    FROM classed
    GROUP BY is_mut
    HAVING COUNT(*) >= 10
       AND VAR_SAMP(expr_avg) > 0
),
calc AS (
    SELECT
        (
            (SELECT mean_expr FROM stats WHERE is_mut = 1) -
            (SELECT mean_expr FROM stats WHERE is_mut = 0)
        ) /
        SQRT(
            (SELECT var_expr FROM stats WHERE is_mut = 1) / (SELECT n FROM stats WHERE is_mut = 1) +
            (SELECT var_expr FROM stats WHERE is_mut = 0) / (SELECT n FROM stats WHERE is_mut = 0)
        ) AS t_score
)
SELECT ROUND(t_score, 2) AS t_score
FROM calc;
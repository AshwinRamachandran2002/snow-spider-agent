WITH expr AS (  -- average log-transformed DRG2 expression per participant
    SELECT
        "ParticipantBarcode",
        AVG( LOG(10 , "normalized_count" + 1) ) AS expr_val   -- base-10 log
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED
    WHERE "Study" = 'LGG'
      AND "Symbol" = 'DRG2'
    GROUP BY "ParticipantBarcode"
),
tp53_mut AS (    -- LGG participants with a PASS TP53 mutation
    SELECT DISTINCT
        "ParticipantBarcode"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE
    WHERE "Study" = 'LGG'
      AND "Hugo_Symbol" = 'TP53'
      AND "FILTER" = 'PASS'
),
expr_flag AS (   -- label each participant as mutated (1) or non-mutated (0)
    SELECT
        e."ParticipantBarcode",
        e.expr_val,
        CASE WHEN m."ParticipantBarcode" IS NOT NULL THEN 1 ELSE 0 END AS is_mut
    FROM expr e
    LEFT JOIN tp53_mut m
           ON e."ParticipantBarcode" = m."ParticipantBarcode"
),
agg AS (         -- group-wise sums, sums of squares, and counts
    SELECT
        SUM( CASE WHEN is_mut = 1 THEN expr_val          ELSE 0 END ) AS sum_mut,
        SUM( CASE WHEN is_mut = 1 THEN expr_val*expr_val ELSE 0 END ) AS sumsq_mut,
        SUM( CASE WHEN is_mut = 1 THEN 1                 ELSE 0 END ) AS n_mut,
        SUM( CASE WHEN is_mut = 0 THEN expr_val          ELSE 0 END ) AS sum_nomut,
        SUM( CASE WHEN is_mut = 0 THEN expr_val*expr_val ELSE 0 END ) AS sumsq_nomut,
        SUM( CASE WHEN is_mut = 0 THEN 1                 ELSE 0 END ) AS n_nomut
    FROM expr_flag
)
SELECT
    ROUND(
        (mean_mut - mean_nomut) /
        SQRT( var_mut / n_mut + var_nomut / n_nomut )
    , 2) AS t_score
FROM (
    SELECT
        n_mut,
        n_nomut,
        sum_mut   / n_mut   AS mean_mut,
        sum_nomut / n_nomut AS mean_nomut,
        (sumsq_mut   - (sum_mut   * sum_mut)   / n_mut  ) / (n_mut   - 1) AS var_mut,
        (sumsq_nomut - (sum_nomut * sum_nomut) / n_nomut) / (n_nomut - 1) AS var_nomut
    FROM agg
) stats
WHERE n_mut   >= 10
  AND n_nomut >= 10
  AND var_mut   > 0
  AND var_nomut > 0;
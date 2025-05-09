WITH expr_per_participant AS (   -- average log10(normalized_count+1) for DRG2 per LGG participant
    SELECT
        "ParticipantBarcode",
        AVG( LOG(10, "normalized_count" + 1) ) AS avg_log_expr
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED"
    WHERE "Study" = 'LGG'
      AND "Symbol" = 'DRG2'
    GROUP BY "ParticipantBarcode"
),
tp53_mutated AS (                -- LGG participants with a PASS TP53 mutation
    SELECT DISTINCT "ParticipantBarcode"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE "Study" = 'LGG'
      AND "Hugo_Symbol" = 'TP53'
      AND "FILTER" = 'PASS'
),
flagged AS (                     -- attach mutation flag to expression table
    SELECT
        e."ParticipantBarcode",
        e.avg_log_expr,
        CASE WHEN m."ParticipantBarcode" IS NOT NULL THEN 1 ELSE 0 END AS tp53_mut
    FROM expr_per_participant e
    LEFT JOIN tp53_mutated m
           ON e."ParticipantBarcode" = m."ParticipantBarcode"
),
group_stats AS (                 -- sample size, mean, variance per group
    SELECT
        tp53_mut                         AS grp,
        COUNT(*)                         AS n,
        AVG(avg_log_expr)                AS mean_expr,
        VAR_SAMP(avg_log_expr)           AS var_expr
    FROM flagged
    GROUP BY tp53_mut
    HAVING COUNT(*) >= 10          -- skip groups with <10 samples
       AND VAR_SAMP(avg_log_expr) > 0   -- skip if zero variance
),
mut AS (SELECT * FROM group_stats WHERE grp = 1),
non AS (SELECT * FROM group_stats WHERE grp = 0)
SELECT
    ROUND(
        (mut.mean_expr - non.mean_expr)
        / SQRT( (mut.var_expr / mut.n) + (non.var_expr / non.n) )
    , 2) AS t_score_drg2_tp53_mut_vs_nonmut_lgg
FROM mut, non;
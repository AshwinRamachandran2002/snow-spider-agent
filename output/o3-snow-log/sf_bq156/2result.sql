/* Welch t-score for DRG2 expression (log10) between TP53-mutated vs non-mutated
   LGG participants                                                          */
WITH expr_per_participant AS (          -- avg log10(expr+1) per participant
    SELECT
        "ParticipantBarcode"                             AS participant,
        AVG( LOG(10, "normalized_count" + 1) )           AS expr
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED"
    WHERE "Study" = 'LGG'
      AND "Symbol" = 'DRG2'
    GROUP BY "ParticipantBarcode"
),
tp53_mutated AS (                       -- LGG participants with PASS TP53 mutation
    SELECT DISTINCT
        "ParticipantBarcode"            AS participant
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE "Study" = 'LGG'
      AND "Hugo_Symbol" = 'TP53'
      AND "FILTER" = 'PASS'
),
expr_with_status AS (                   -- label participants as MUT or NON
    SELECT
        e.participant,
        e.expr,
        CASE WHEN m.participant IS NOT NULL THEN 'MUT' ELSE 'NON' END AS status
    FROM expr_per_participant e
    LEFT JOIN tp53_mutated m
      ON e.participant = m.participant
),
group_stats AS (                        -- n, mean, variance per group
    SELECT
        status,
        COUNT(*)        AS n,
        AVG(expr)       AS mean,
        VAR_SAMP(expr)  AS var         -- sample variance
    FROM expr_with_status
    GROUP BY status
)
SELECT
    CASE
        WHEN mut.n  >= 10
         AND non.n  >= 10
         AND mut.var > 0
         AND non.var > 0
        THEN ROUND(
                 (mut.mean - non.mean)
                 / SQRT(mut.var / mut.n + non.var / non.n)
             , 2)
        ELSE NULL
    END AS t_score
FROM (SELECT * FROM group_stats WHERE status = 'MUT') mut
CROSS JOIN (SELECT * FROM group_stats WHERE status = 'NON') non;
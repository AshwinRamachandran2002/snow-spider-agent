WITH expr_per_participant AS (  -- average log10(normalized_count+1) for DRG2 per LGG participant
    SELECT
        "ParticipantBarcode"                                   AS participant,
        AVG( LOG(10, "normalized_count" + 1) )                 AS expr
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED
    WHERE "Study" = 'LGG'
      AND "Symbol" = 'DRG2'
    GROUP BY "ParticipantBarcode"
),
tp53_mutated_participants AS (  -- LGG participants with at least one PASS‑filtered TP53 mutation
    SELECT DISTINCT
        "ParticipantBarcode" AS participant
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE
    WHERE "Study" = 'LGG'
      AND "Hugo_Symbol" = 'TP53'
      AND "FILTER" = 'PASS'
),
grouped_expr AS (              -- label each participant as MUT or WT
    SELECT
        e.participant,
        e.expr,
        CASE WHEN m.participant IS NOT NULL THEN 'MUT' ELSE 'WT' END AS grp
    FROM expr_per_participant e
    LEFT JOIN tp53_mutated_participants m
           ON e.participant = m.participant
),
grp_stats AS (                 -- sample size, mean, variance per group
    SELECT
        grp,
        COUNT(*)              AS n,
        AVG(expr)             AS mean_expr,
        VAR_SAMP(expr)        AS var_expr
    FROM grouped_expr
    GROUP BY grp
),
combined AS (                  -- keep groups meeting size & variance criteria
    SELECT
        mut.n        AS n_mut,
        mut.mean_expr AS mean_mut,
        mut.var_expr  AS var_mut,
        wt.n         AS n_wt,
        wt.mean_expr  AS mean_wt,
        wt.var_expr   AS var_wt
    FROM grp_stats mut
    JOIN grp_stats wt
      ON mut.grp = 'MUT' AND wt.grp = 'WT'
    WHERE mut.n >= 10 AND wt.n >= 10
      AND mut.var_expr > 0 AND wt.var_expr > 0
)
SELECT  -- Welch’s t‑score rounded to 2 decimals
    ROUND(
        (mean_mut - mean_wt) /
        SQRT( var_mut / n_mut + var_wt / n_wt )
    , 2
    ) AS t_score
FROM combined;
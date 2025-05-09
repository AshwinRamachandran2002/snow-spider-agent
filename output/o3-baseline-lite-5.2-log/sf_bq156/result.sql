WITH expr AS (  -- average log10(normalized_count+1) expression of DRG2 per participant
    SELECT
        "ParticipantBarcode"                          AS participant,
        AVG( LOG("normalized_count" + 1, 10) )        AS expr   -- log base 10
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED
    WHERE "Study"  = 'LGG'
      AND "Symbol" = 'DRG2'
    GROUP BY "ParticipantBarcode"
),
mutated AS (      -- LGG participants with TP53 mutation (FILTER = 'PASS')
    SELECT DISTINCT
        "ParticipantBarcode" AS participant
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE
    WHERE "Study"       = 'LGG'
      AND "Hugo_Symbol" = 'TP53'
      AND "FILTER"      = 'PASS'
),
grp_expr AS (     -- tag each participant as mutated / non‑mutated
    SELECT
        CASE WHEN m.participant IS NULL THEN 'non_mutated' ELSE 'mutated' END AS grp,
        e.expr
    FROM expr e
    LEFT JOIN mutated m
           ON e.participant = m.participant
),
stats AS (        -- size, mean and variance of each group
    SELECT
        grp,
        COUNT(*)       AS n,
        AVG(expr)      AS mean,
        VAR_SAMP(expr) AS var
    FROM grp_expr
    GROUP BY grp
),
valid AS (        -- keep only groups with ≥10 samples and non‑zero variance
    SELECT *
    FROM stats
    WHERE n >= 10
      AND var > 0
),
comb AS (         -- pivot mutated vs. non‑mutated statistics
    SELECT
        (SELECT mean FROM valid WHERE grp = 'mutated')      AS mean_mut,
        (SELECT var  FROM valid WHERE grp = 'mutated')      AS var_mut,
        (SELECT n    FROM valid WHERE grp = 'mutated')      AS n_mut,
        (SELECT mean FROM valid WHERE grp = 'non_mutated')  AS mean_non,
        (SELECT var  FROM valid WHERE grp = 'non_mutated')  AS var_non,
        (SELECT n    FROM valid WHERE grp = 'non_mutated')  AS n_non
)
SELECT
    ROUND( (mean_mut - mean_non) /
           SQRT( var_mut / n_mut + var_non / n_non )
         , 2) AS "t_score"
FROM comb;
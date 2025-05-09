WITH tp53_mutated AS (  -- LGG participants carrying at least one passing TP53 mutation
    SELECT DISTINCT "ParticipantBarcode"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE "Study" = 'LGG'
      AND "Hugo_Symbol" = 'TP53'
      AND "FILTER" = 'PASS'
), 
expr_per_patient AS (  -- mean log10-transformed DRG2 expression per participant
    SELECT
        "ParticipantBarcode",
        AVG( LOG(10, "normalized_count" + 1) ) AS expr_val
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED"
    WHERE "Study" = 'LGG'
      AND "Symbol" = 'DRG2'
    GROUP BY "ParticipantBarcode"
), 
labeled AS (           -- tag each participant as Mutated / NonMutated
    SELECT
        e."ParticipantBarcode",
        e.expr_val,
        CASE 
            WHEN m."ParticipantBarcode" IS NOT NULL THEN 'Mutated'
            ELSE 'NonMutated'
        END AS grp
    FROM expr_per_patient e
    LEFT JOIN tp53_mutated m
           ON e."ParticipantBarcode" = m."ParticipantBarcode"
), 
stats AS (             -- group stats required for Welch’s t-test
    SELECT
        grp,
        COUNT(*)            AS n,
        AVG(expr_val)       AS mean_val,
        VAR_SAMP(expr_val)  AS var_val
    FROM labeled
    GROUP BY grp
    HAVING COUNT(*) >= 10      -- ignore small groups
       AND VAR_SAMP(expr_val) > 0   -- ignore zero variance
), 
pivot AS (             -- put stats into single row for formula
    SELECT
        MAX(CASE WHEN grp='Mutated'    THEN mean_val END) AS mean_mut,
        MAX(CASE WHEN grp='Mutated'    THEN var_val  END) AS var_mut,
        MAX(CASE WHEN grp='Mutated'    THEN n        END) AS n_mut,
        MAX(CASE WHEN grp='NonMutated' THEN mean_val END) AS mean_non,
        MAX(CASE WHEN grp='NonMutated' THEN var_val  END) AS var_non,
        MAX(CASE WHEN grp='NonMutated' THEN n        END) AS n_non
    FROM stats
)
SELECT
    ROUND(
        (mean_mut - mean_non)
        / SQRT( (var_mut / n_mut) + (var_non / n_non) ),
        2
    ) AS "t_score"
FROM pivot;
WITH expr AS (  -- average log10(normalized_count+1) of DRG2 per participant
    SELECT 
        "ParticipantBarcode"                         AS patient,
        AVG(LOG("normalized_count" + 1, 10))         AS expr_avg     -- LOG base‑10
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED
    WHERE "Study" = 'LGG'
      AND "Symbol" = 'DRG2'
    GROUP BY "ParticipantBarcode"
), 
tp53_mut AS (    -- LGG participants with a PASS TP53 mutation
    SELECT DISTINCT 
        "ParticipantBarcode" AS patient
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE
    WHERE "Study" = 'LGG'
      AND "Hugo_Symbol" = 'TP53'
      AND "FILTER" = 'PASS'
), 
expr_group AS (  -- label each participant as mutated (MUT) or non‑mutated (WT)
    SELECT 
        e.patient,
        e.expr_avg,
        CASE WHEN m.patient IS NOT NULL THEN 'MUT' ELSE 'WT' END AS grp
    FROM expr e
    LEFT JOIN tp53_mut m
           ON e.patient = m.patient
), 
grp_stats AS (   -- size, mean and variance (sample) for each group
    SELECT
        grp,
        COUNT(*)                AS n,
        AVG(expr_avg)           AS mean,
        VAR_SAMP(expr_avg)      AS var
    FROM expr_group
    GROUP BY grp
), 
nums AS (        -- pivot the two groups' statistics
    SELECT
        (SELECT n    FROM grp_stats WHERE grp = 'MUT') AS n_mut,
        (SELECT mean FROM grp_stats WHERE grp = 'MUT') AS mean_mut,
        (SELECT var  FROM grp_stats WHERE grp = 'MUT') AS var_mut,
        (SELECT n    FROM grp_stats WHERE grp = 'WT')  AS n_wt,
        (SELECT mean FROM grp_stats WHERE grp = 'WT')  AS mean_wt,
        (SELECT var  FROM grp_stats WHERE grp = 'WT')  AS var_wt
), 
t_calc AS (      -- Welch’s t‑score
    SELECT
        CASE
            WHEN n_mut >= 10 AND n_wt >= 10 AND var_mut > 0 AND var_wt > 0
            THEN (mean_mut - mean_wt) / SQRT( var_mut / n_mut + var_wt / n_wt )
            ELSE NULL
        END AS t_score
    FROM nums
)
SELECT ROUND(t_score, 2) AS t_score
FROM t_calc;
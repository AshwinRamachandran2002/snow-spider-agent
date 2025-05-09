WITH expr AS (   -- per-participant mean log10 expression of DRG2
    SELECT 
        "ParticipantBarcode",
        AVG(LOG(10, "normalized_count" + 1)) AS avg_expr
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED"
    WHERE "Study" = 'LGG'
      AND "Symbol" = 'DRG2'
      AND "SampleTypeLetterCode" = 'TP'
    GROUP BY "ParticipantBarcode"
), mut AS (      -- LGG participants with PASS-filtered TP53 mutation
    SELECT DISTINCT "ParticipantBarcode"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE "Study" = 'LGG'
      AND "Hugo_Symbol" = 'TP53'
      AND "FILTER" = 'PASS'
), tagged AS (    -- label each participant as MUT or NONMUT
    SELECT 
        e.avg_expr,
        CASE WHEN m."ParticipantBarcode" IS NOT NULL THEN 'MUT' ELSE 'NONMUT' END AS grp
    FROM expr e
    LEFT JOIN mut m
           ON e."ParticipantBarcode" = m."ParticipantBarcode"
), stats AS (     -- group statistics (require ≥10 samples & non-zero variance)
    SELECT 
        grp,
        COUNT(*)                  AS N,
        AVG(avg_expr)             AS mean_expr,
        VAR_SAMP(avg_expr)        AS var_expr
    FROM tagged
    GROUP BY grp
    HAVING COUNT(*) >= 10
       AND VAR_SAMP(avg_expr) > 0
)
SELECT 
    ROUND( 
        ( s_mut.mean_expr - s_non.mean_expr )
        /
        SQRT( (s_mut.var_expr / s_mut.N) + (s_non.var_expr / s_non.N) )
    , 2) AS t_score
FROM  stats s_mut
JOIN  stats s_non
      ON s_mut.grp = 'MUT'
     AND s_non.grp = 'NONMUT';
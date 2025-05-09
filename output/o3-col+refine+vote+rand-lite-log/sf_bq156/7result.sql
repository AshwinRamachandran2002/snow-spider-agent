WITH expr AS (   -- per-participant DRG2 expression (log10-avg)
  SELECT
    "ParticipantBarcode",
    AVG( LOG(10, "normalized_count" + 1) ) AS mean_log10_expr
  FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED"
  WHERE "Study" = 'LGG'
    AND "Symbol" = 'DRG2'
  GROUP BY "ParticipantBarcode"
),
mut AS (          -- LGG participants with a PASS TP53 mutation
  SELECT DISTINCT
    "ParticipantBarcode"
  FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
  WHERE "Study" = 'LGG'
    AND "Hugo_Symbol" = 'TP53'
    AND "FILTER" = 'PASS'
),
grp AS (          -- tag each participant as mutated or wild-type
  SELECT
    CASE WHEN mut."ParticipantBarcode" IS NOT NULL THEN 'TP53_mut'
         ELSE 'TP53_wt' END                AS grp,
    expr.mean_log10_expr
  FROM expr
  LEFT JOIN mut
    ON expr."ParticipantBarcode" = mut."ParticipantBarcode"
),
stats AS (        -- summary stats per group (require N≥10 & Var>0)
  SELECT
    grp,
    COUNT(*)                       AS n,
    AVG(mean_log10_expr)           AS mean,
    VAR_SAMP(mean_log10_expr)      AS var
  FROM grp
  GROUP BY grp
  HAVING COUNT(*) >= 10
     AND VAR_SAMP(mean_log10_expr) > 0
),
mut_stats AS ( SELECT * FROM stats WHERE grp = 'TP53_mut' ),
wt_stats  AS ( SELECT * FROM stats WHERE grp = 'TP53_wt' )
SELECT
  ROUND(
    (mut_stats.mean - wt_stats.mean) /
    SQRT( mut_stats.var / mut_stats.n + wt_stats.var / wt_stats.n ),
    2
  ) AS t_score
FROM mut_stats, wt_stats;
WITH expr AS (  -- DRG2 expression per participant
  SELECT
    "ParticipantBarcode"                            AS participant,
    AVG( LOG(10, "normalized_count" + 1) )          AS drg2_expr
  FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED
  WHERE "Study" = 'LGG'
    AND "Symbol" = 'DRG2'
  GROUP BY "ParticipantBarcode"
),
mut AS (         -- participants with at least one PASS TP53 mutation
  SELECT DISTINCT
    "ParticipantBarcode"                            AS participant
  FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE
  WHERE "Study" = 'LGG'
    AND "Hugo_Symbol" = 'TP53'
    AND "FILTER" = 'PASS'
),
merge AS (       -- merge expression with mutation status
  SELECT
    e.participant,
    e.drg2_expr,
    CASE WHEN m.participant IS NOT NULL THEN 'MUT' ELSE 'WT' END AS grp
  FROM expr e
  LEFT JOIN mut m
    ON e.participant = m.participant
),
stats AS (       -- n, mean, variance per group
  SELECT
    grp,
    COUNT(*)                                             AS n,
    AVG(drg2_expr)                                       AS mean,
    (SUM(POWER(drg2_expr, 2)) - POWER(SUM(drg2_expr),2)/COUNT(*))
      / (COUNT(*)-1)                                     AS var
  FROM merge
  GROUP BY grp
),
s_mut AS (SELECT * FROM stats WHERE grp = 'MUT'),
s_wt  AS (SELECT * FROM stats WHERE grp = 'WT')
SELECT
  ROUND(
    (s_mut.mean - s_wt.mean)
    / SQRT( s_mut.var / s_mut.n + s_wt.var / s_wt.n )
  , 2)                                                   AS t_score
FROM s_mut, s_wt
WHERE s_mut.n  >= 10
  AND s_wt.n  >= 10
  AND s_mut.var > 0
  AND s_wt.var > 0;
WITH expr AS (  -- average log-transformed DRG2 expression per participant
  SELECT
    "ParticipantBarcode",
    AVG( LOG(10, "normalized_count" + 1) ) AS avg_log_expr
  FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED"
  WHERE "Study" = 'LGG'
    AND "Symbol" = 'DRG2'
  GROUP BY "ParticipantBarcode"
),
mut AS (        -- LGG participants carrying a PASS TP53 mutation
  SELECT DISTINCT "ParticipantBarcode"
  FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
  WHERE "Study" = 'LGG'
    AND "Hugo_Symbol" = 'TP53'
    AND "FILTER" = 'PASS'
),
grp AS (        -- label each participant as MUT or WT
  SELECT
    e.avg_log_expr,
    CASE WHEN m."ParticipantBarcode" IS NOT NULL THEN 'MUT' ELSE 'WT' END AS grp
  FROM expr e
  LEFT JOIN mut m
    ON e."ParticipantBarcode" = m."ParticipantBarcode"
),
stats AS (      -- group counts, means, variances (require ≥10 samples & non-zero variance)
  SELECT
    grp,
    COUNT(*)                        AS n,
    AVG(avg_log_expr)               AS mean,
    VAR_SAMP(avg_log_expr)          AS var
  FROM grp
  GROUP BY grp
  HAVING COUNT(*) >= 10
     AND VAR_SAMP(avg_log_expr) > 0
)
SELECT
  ROUND(
      ( (SELECT mean FROM stats WHERE grp = 'MUT')
      - (SELECT mean FROM stats WHERE grp = 'WT') )
    /
      SQRT(
        (SELECT var FROM stats WHERE grp = 'MUT') / (SELECT n FROM stats WHERE grp = 'MUT')
        +
        (SELECT var FROM stats WHERE grp = 'WT') / (SELECT n FROM stats WHERE grp = 'WT')
      )
  , 2)  AS "t_score";
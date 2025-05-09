WITH mutations AS (  -- LGG participants with a PASS TP53 mutation
    SELECT DISTINCT "ParticipantBarcode"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE
    WHERE "Study" = 'LGG'
      AND "Hugo_Symbol" = 'TP53'
      AND "FILTER" = 'PASS'
),
expr AS (           -- DRG2 expression (log10(norm_count+1)) averaged per participant
    SELECT
        "ParticipantBarcode",
        AVG(LOG(10, "normalized_count" + 1)) AS avg_log_expr
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED
    WHERE "Study" = 'LGG'
      AND "Symbol" = 'DRG2'
    GROUP BY "ParticipantBarcode"
),
expr_flag AS (      -- mark participants as mutated/non‑mutated
    SELECT
        e."ParticipantBarcode",
        e.avg_log_expr,
        CASE WHEN m."ParticipantBarcode" IS NOT NULL THEN 1 ELSE 0 END AS mutated
    FROM expr e
    LEFT JOIN mutations m
           ON e."ParticipantBarcode" = m."ParticipantBarcode"
),
stats AS (          -- group statistics
    SELECT
        mutated,
        COUNT(*)                       AS n,
        AVG(avg_log_expr)              AS mean,
        VAR_SAMP(avg_log_expr)         AS var
    FROM expr_flag
    GROUP BY mutated
)
SELECT
    ROUND(
        (mut.mean - nomut.mean) /
        SQRT((mut.var / mut.n) + (nomut.var / nomut.n))
    , 2) AS t_score
FROM (SELECT * FROM stats WHERE mutated = 1)  mut
JOIN (SELECT * FROM stats WHERE mutated = 0)  nomut
  ON 1=1
WHERE mut.n  >= 10
  AND nomut.n >= 10
  AND mut.var  > 0
  AND nomut.var > 0;
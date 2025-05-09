WITH expr AS (  -- average log10(NC+1) expression per participant
    SELECT
        "ParticipantBarcode",
        AVG(LOG("normalized_count" + 1, 10)) AS expr
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED
    WHERE "Study" = 'LGG'
      AND "Symbol" = 'DRG2'
    GROUP BY "ParticipantBarcode"
),
mut AS (         -- TP53-mutated participants (FILTER = 'PASS')
    SELECT DISTINCT
        "ParticipantBarcode"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE
    WHERE "Study" = 'LGG'
      AND "Hugo_Symbol" = 'TP53'
      AND "FILTER" = 'PASS'
),
tagged AS (      -- label each participant as MUT or WT
    SELECT
        e.expr,
        CASE WHEN m."ParticipantBarcode" IS NOT NULL THEN 'MUT' ELSE 'WT' END AS grp
    FROM expr e
    LEFT JOIN mut m
      ON e."ParticipantBarcode" = m."ParticipantBarcode"
),
stats AS (       -- group statistics needed for Welch’s t-test
    SELECT
        grp,
        COUNT(*)                      AS n,
        SUM(expr)                     AS S,
        SUM(POWER(expr, 2))           AS Q
    FROM tagged
    GROUP BY grp
),
calc AS (        -- reshape stats into single row
    SELECT
        MIN(CASE WHEN grp = 'MUT' THEN n END) AS n_y,
        MIN(CASE WHEN grp = 'MUT' THEN S END) AS S_y,
        MIN(CASE WHEN grp = 'MUT' THEN Q END) AS Q_y,
        MIN(CASE WHEN grp = 'WT'  THEN n END) AS n_n,
        MIN(CASE WHEN grp = 'WT'  THEN S END) AS S_n,
        MIN(CASE WHEN grp = 'WT'  THEN Q END) AS Q_n
    FROM stats
)
-- Welch’s t-score, rounded to 2 decimals
SELECT
    ROUND(
        ( (S_y / n_y) - (S_n / n_n) )
        /
        SQRT(
              ( (Q_y - POWER(S_y, 2) / n_y) / (n_y - 1) ) / n_y
            + ( (Q_n - POWER(S_n, 2) / n_n) / (n_n - 1) ) / n_n
        )
    , 2) AS "t_score"
FROM calc
WHERE n_y >= 10
  AND n_n >= 10
  AND (Q_y - POWER(S_y, 2) / n_y) > 0
  AND (Q_n - POWER(S_n, 2) / n_n) > 0;
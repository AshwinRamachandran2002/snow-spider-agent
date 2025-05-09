WITH expr AS (  -- per‑participant mean log10(normalized_count + 1) for DRG2
    SELECT
        "ParticipantBarcode",
        AVG(LOG(10, "normalized_count" + 1)) AS g
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED
    WHERE "Study" = 'LGG'
      AND "Symbol" = 'DRG2'
    GROUP BY "ParticipantBarcode"
),
mutated AS (     -- participants carrying at least one PASS TP53 mutation
    SELECT DISTINCT "ParticipantBarcode"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE
    WHERE "Study" = 'LGG'
      AND "Hugo_Symbol" = 'TP53'
      AND "FILTER" = 'PASS'
),
stats AS (       -- compute counts, sums and sums of squares for each group
    SELECT
        COUNT(CASE WHEN m."ParticipantBarcode" IS NOT NULL THEN 1 END)                    AS N_y,
        COUNT(CASE WHEN m."ParticipantBarcode" IS NULL  THEN 1 END)                      AS N_n,
        SUM  (CASE WHEN m."ParticipantBarcode" IS NOT NULL THEN e.g END)                 AS S_y,
        SUM  (CASE WHEN m."ParticipantBarcode" IS NULL  THEN e.g END)                    AS S_n,
        SUM  (CASE WHEN m."ParticipantBarcode" IS NOT NULL THEN POWER(e.g, 2) END)       AS Q_y,
        SUM  (CASE WHEN m."ParticipantBarcode" IS NULL  THEN POWER(e.g, 2) END)          AS Q_n
    FROM expr e
    LEFT JOIN mutated m
           ON e."ParticipantBarcode" = m."ParticipantBarcode"
)
SELECT
    ROUND(
        ( (S_y / N_y) - (S_n / N_n) ) /
        SQRT(
              ( (Q_y - (S_y * S_y) / N_y) / GREATEST(N_y - 1, 1) ) / N_y
            + ( (Q_n - (S_n * S_n) / N_n) / GREATEST(N_n - 1, 1) ) / N_n
        )
    , 2) AS t_score
FROM stats
WHERE N_y >= 10
  AND N_n >= 10
  AND (Q_y - (S_y * S_y) / N_y) > 0
  AND (Q_n - (S_n * S_n) / N_n) > 0;
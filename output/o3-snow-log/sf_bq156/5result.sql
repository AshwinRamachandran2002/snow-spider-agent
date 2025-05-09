WITH tp53_mut AS (   -- LGG participants whose TP53 mutation passed all filters
    SELECT DISTINCT "ParticipantBarcode"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE "Study" = 'LGG'
      AND "Hugo_Symbol" = 'TP53'
      AND "FILTER" = 'PASS'
),
expr AS (            -- per-participant DRG2 expression: mean[ log10(normalized_count + 1) ]
    SELECT
        "ParticipantBarcode",
        AVG( LOG(10, "normalized_count" + 1) ) AS expr_value
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED"
    WHERE "Study" = 'LGG'
      AND "Symbol" = 'DRG2'
    GROUP BY "ParticipantBarcode"
),
stats AS (           -- accumulate counts and sums for mutated (y) and non-mutated (n) groups
    SELECT
        SUM(CASE WHEN m."ParticipantBarcode" IS NOT NULL THEN 1 ELSE 0 END)                         AS N_y,
        SUM(CASE WHEN m."ParticipantBarcode" IS NOT NULL THEN e.expr_value ELSE 0 END)              AS S_y,
        SUM(CASE WHEN m."ParticipantBarcode" IS NOT NULL THEN POWER(e.expr_value, 2) ELSE 0 END)    AS Q_y,
        SUM(CASE WHEN m."ParticipantBarcode" IS NULL THEN 1 ELSE 0 END)                             AS N_n,
        SUM(CASE WHEN m."ParticipantBarcode" IS NULL THEN e.expr_value ELSE 0 END)                  AS S_n,
        SUM(CASE WHEN m."ParticipantBarcode" IS NULL THEN POWER(e.expr_value, 2) ELSE 0 END)        AS Q_n
    FROM expr e
    LEFT JOIN tp53_mut m
           ON e."ParticipantBarcode" = m."ParticipantBarcode"
)
SELECT
    CASE
        WHEN N_y >= 10
         AND N_n >= 10
         AND var_y > 0
         AND var_n > 0
        THEN ROUND( (mean_y - mean_n)
                    / SQRT( var_y / N_y + var_n / N_n ), 2 )
    END AS "t_score"
FROM (
    SELECT
        N_y, N_n,
        S_y, S_n,
        Q_y, Q_n,
        S_y / N_y                                                       AS mean_y,
        S_n / N_n                                                       AS mean_n,
        (Q_y - (S_y * S_y) / N_y) / NULLIF(N_y - 1, 0)                  AS var_y,
        (Q_n - (S_n * S_n) / N_n) / NULLIF(N_n - 1, 0)                  AS var_n
    FROM stats
) sub;
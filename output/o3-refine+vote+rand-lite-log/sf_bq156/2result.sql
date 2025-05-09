WITH expr AS (   -- per‑participant DRG2 expression
    SELECT
        "ParticipantBarcode",
        AVG(LOG(10, "normalized_count" + 1)) AS expr      -- log10
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED
    WHERE "Study" = 'LGG'
      AND "Symbol" = 'DRG2'
    GROUP BY "ParticipantBarcode"
),
mut AS (          -- LGG participants with at least one PASS TP53 mutation
    SELECT DISTINCT "ParticipantBarcode"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE
    WHERE "Study" = 'LGG'
      AND "Hugo_Symbol" = 'TP53'
      AND "FILTER" = 'PASS'
),
expr_grouped AS ( -- label participants as mutated / non‑mutated
    SELECT
        e."ParticipantBarcode",
        e.expr,
        CASE WHEN m."ParticipantBarcode" IS NOT NULL THEN 1 ELSE 0 END AS is_mut
    FROM expr e
    LEFT JOIN mut m
      ON e."ParticipantBarcode" = m."ParticipantBarcode"
),
stats AS (        -- accumulate sums needed for Welch’s t‑test
    SELECT
        SUM(CASE WHEN is_mut = 1 THEN expr        ELSE 0 END) AS S_y,
        SUM(CASE WHEN is_mut = 1 THEN expr*expr   ELSE 0 END) AS Q_y,
        SUM(CASE WHEN is_mut = 1 THEN 1           ELSE 0 END) AS N_y,
        SUM(CASE WHEN is_mut = 0 THEN expr        ELSE 0 END) AS S_n,
        SUM(CASE WHEN is_mut = 0 THEN expr*expr   ELSE 0 END) AS Q_n,
        SUM(CASE WHEN is_mut = 0 THEN 1           ELSE 0 END) AS N_n
    FROM expr_grouped
),
calc AS (         -- means and variances for the two groups
    SELECT
        N_y, N_n, S_y, S_n, Q_y, Q_n,
        S_y / N_y                                         AS g_y,
        S_n / N_n                                         AS g_n,
        (Q_y - (S_y*S_y)/N_y) / NULLIF(N_y - 1, 0)        AS s2_y,
        (Q_n - (S_n*S_n)/N_n) / NULLIF(N_n - 1, 0)        AS s2_n
    FROM stats
),
t_score_cte AS (  -- Welch’s t‑score, rounded to 2 decimals
    SELECT
        ROUND( (g_y - g_n) /
               SQRT( s2_y / N_y + s2_n / N_n )
             , 2) AS t_score
    FROM calc
    WHERE N_y >= 10
      AND N_n >= 10
      AND s2_y > 0
      AND s2_n > 0
)
SELECT t_score
FROM t_score_cte;
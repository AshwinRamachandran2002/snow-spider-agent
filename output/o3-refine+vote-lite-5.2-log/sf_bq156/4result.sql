WITH expr AS (
    -- average log10(normalized_count + 1) expression of DRG2 per participant
    SELECT
        "ParticipantBarcode",
        AVG( LOG(10, "normalized_count" + 1) ) AS expr_val
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED
    WHERE "Study" = 'LGG'
      AND "Symbol" = 'DRG2'
    GROUP BY "ParticipantBarcode"
),
mut AS (
    -- LGG participants carrying a PASS‑filtered TP53 mutation
    SELECT DISTINCT
        "ParticipantBarcode"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE
    WHERE "Study" = 'LGG'
      AND "Hugo_Symbol" = 'TP53'
      AND "FILTER" = 'PASS'
),
expr_with_grp AS (
    -- tag each participant as mutated or non‑mutated
    SELECT
        e.expr_val,
        CASE WHEN m."ParticipantBarcode" IS NOT NULL THEN 'Mut' ELSE 'Non' END AS grp
    FROM expr e
    LEFT JOIN mut m
      ON e."ParticipantBarcode" = m."ParticipantBarcode"
),
stats AS (
    -- compute count, mean and variance for each group
    SELECT
        grp,
        COUNT(*)                            AS n,
        AVG(expr_val)                       AS mean,
        VAR_SAMP(expr_val)                  AS var
    FROM expr_with_grp
    GROUP BY grp
),
calc AS (
    -- keep only groups with ≥10 samples and non‑zero variance
    SELECT
        m.mean  AS mean_mut,
        n.mean  AS mean_non,
        m.var   AS var_mut,
        n.var   AS var_non,
        m.n     AS n_mut,
        n.n     AS n_non
    FROM stats m
    JOIN stats n
      ON m.grp = 'Mut' AND n.grp = 'Non'
    WHERE m.n >= 10
      AND n.n >= 10
      AND m.var > 0
      AND n.var > 0
),
t_score_calc AS (
    -- Welch’s t‑score
    SELECT
        (mean_mut - mean_non)
        /
        SQRT( var_mut / n_mut + var_non / n_non ) AS t_score
    FROM calc
)
SELECT ROUND(t_score, 2) AS t_score
FROM t_score_calc;
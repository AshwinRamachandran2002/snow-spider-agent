WITH expr AS (
    /* 1. Per–participant expression of DRG2: log10(normalized_count+1) */
    SELECT
        "ParticipantBarcode",
        AVG(LOG(10, "normalized_count" + 1)) AS expr_avg
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED
    WHERE "Study" = 'LGG'
      AND "Symbol" = 'DRG2'
    GROUP BY "ParticipantBarcode"
),
mut AS (
    /* 2. LGG participants with TP53 mutations that passed all filters */
    SELECT DISTINCT
        "ParticipantBarcode"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE
    WHERE "Study"       = 'LGG'
      AND "Hugo_Symbol" = 'TP53'
      AND "FILTER"      = 'PASS'
),
expr_flag AS (
    /* 3. Merge expression with mutation status */
    SELECT
        e."ParticipantBarcode",
        e.expr_avg,
        CASE WHEN m."ParticipantBarcode" IS NOT NULL THEN 1 ELSE 0 END AS is_mut
    FROM expr e
    LEFT JOIN mut m
           ON e."ParticipantBarcode" = m."ParticipantBarcode"
),
stats AS (
    /* 4. Sums needed for Welch’s t‑test */
    SELECT
        is_mut,
        COUNT(*)                 AS n,
        SUM(expr_avg)            AS S,
        SUM(expr_avg * expr_avg) AS Q
    FROM expr_flag
    GROUP BY is_mut
),
pivot AS (
    /* 5. Put the two groups onto one row */
    SELECT
        MAX(CASE WHEN is_mut = 1 THEN n END) AS n_mut,
        MAX(CASE WHEN is_mut = 1 THEN S END) AS S_mut,
        MAX(CASE WHEN is_mut = 1 THEN Q END) AS Q_mut,
        MAX(CASE WHEN is_mut = 0 THEN n END) AS n_non,
        MAX(CASE WHEN is_mut = 0 THEN S END) AS S_non,
        MAX(CASE WHEN is_mut = 0 THEN Q END) AS Q_non
    FROM stats
),
vars AS (
    /* 6. Means and variances; keep only if each group ≥10 and variances >0 */
    SELECT
        n_mut, n_non,
        S_mut / n_mut                                                AS mean_mut,
        S_non / n_non                                                AS mean_non,
        (Q_mut - (S_mut*S_mut)/n_mut) / (n_mut - 1)                  AS var_mut,
        (Q_non - (S_non*S_non)/n_non) / (n_non - 1)                  AS var_non
    FROM pivot
    WHERE n_mut >= 10
      AND n_non >= 10
      AND (Q_mut - (S_mut*S_mut)/n_mut) > 0
      AND (Q_non - (S_non*S_non)/n_non) > 0
),
t_calc AS (
    /* 7. Welch’s t‑score */
    SELECT
        (mean_mut - mean_non) /
        SQRT(var_mut / n_mut + var_non / n_non) AS t_raw
    FROM vars
)
SELECT ROUND(t_raw, 2) AS t_score
FROM t_calc;
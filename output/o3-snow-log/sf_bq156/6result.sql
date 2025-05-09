WITH drg2_expr AS (
    SELECT
        "ParticipantBarcode",
        AVG(LOG(10, "normalized_count" + 1)) AS expr          -- log10(normalized_count + 1)
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED
    WHERE "Study" = 'LGG'
      AND "Symbol" = 'DRG2'
    GROUP BY "ParticipantBarcode"
),
tp53_mutated AS (
    SELECT DISTINCT
        "ParticipantBarcode"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE
    WHERE "Study" = 'LGG'
      AND "Hugo_Symbol" = 'TP53'
      AND "FILTER" = 'PASS'
),
expr_grouped AS (
    SELECT
        e."ParticipantBarcode",
        e.expr,
        CASE WHEN m."ParticipantBarcode" IS NOT NULL THEN 'MUT' ELSE 'NON' END AS grp
    FROM drg2_expr e
    LEFT JOIN tp53_mutated m
           ON e."ParticipantBarcode" = m."ParticipantBarcode"
),
agg AS (
    SELECT
        SUM(CASE WHEN grp = 'MUT' THEN 1 ELSE 0 END)                       AS n_mut,
        SUM(CASE WHEN grp = 'NON' THEN 1 ELSE 0 END)                       AS n_non,
        SUM(CASE WHEN grp = 'MUT' THEN expr ELSE 0 END)                    AS S_mut,
        SUM(CASE WHEN grp = 'NON' THEN expr ELSE 0 END)                    AS S_non,
        SUM(CASE WHEN grp = 'MUT' THEN expr * expr ELSE 0 END)             AS Q_mut,
        SUM(CASE WHEN grp = 'NON' THEN expr * expr ELSE 0 END)             AS Q_non
    FROM expr_grouped
),
calc AS (
    SELECT
        n_mut,
        n_non,
        S_mut,
        S_non,
        Q_mut,
        Q_non,
        S_mut / NULLIF(n_mut, 0)                                           AS mean_mut,
        S_non / NULLIF(n_non, 0)                                           AS mean_non,
        CASE WHEN n_mut > 1 THEN (Q_mut - (S_mut * S_mut) / n_mut) / (n_mut - 1) END AS var_mut,
        CASE WHEN n_non > 1 THEN (Q_non - (S_non * S_non) / n_non) / (n_non - 1) END AS var_non
    FROM agg
),
t_calc AS (
    SELECT
        CASE
            WHEN n_mut >= 10
             AND n_non >= 10
             AND var_mut > 0
             AND var_non > 0
            THEN (mean_mut - mean_non) / SQRT(var_mut / n_mut + var_non / n_non)
        END AS t_value
    FROM calc
)
SELECT ROUND(t_value, 2) AS t_score
FROM t_calc;
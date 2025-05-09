WITH expr AS (   -- IGF2 expression values for LGG samples
    SELECT
        "ParticipantBarcode"                                                      AS participant,
        LOG(10, "normalized_count" + 1)                                           AS expr_value   -- base‑10 log
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED
    WHERE "Study" = 'LGG'
      AND "Symbol" = 'IGF2'
      AND "normalized_count" IS NOT NULL
),

patient_avg AS (   -- average (log‑scaled) expression per patient
    SELECT
        participant,
        AVG(expr_value)                                                           AS avg_expr
    FROM expr
    GROUP BY participant
),

clinical_filtered AS (   -- keep valid ICD‑O‑3 histology codes
    SELECT
        "bcr_patient_barcode"                                                     AS participant,
        "icd_o_3_histology"                                                       AS hist
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED
    WHERE "icd_o_3_histology" IS NOT NULL
      AND NOT REGEXP_LIKE("icd_o_3_histology", '^\[.*\]$')  -- exclude bracketed codes
),

joined AS (        -- expression + histology
    SELECT
        p.participant,
        p.avg_expr,
        c.hist
    FROM patient_avg        p
    JOIN clinical_filtered  c
      ON p.participant = c.participant
),

eligible AS (      -- retain groups with >1 patient
    SELECT *
    FROM joined
    QUALIFY COUNT(*) OVER (PARTITION BY hist) > 1
),

ranked AS (        -- obtain min‑rank and tie counts
    SELECT
        participant,
        hist,
        avg_expr,
        RANK()  OVER (ORDER BY avg_expr)                             AS r_min,
        COUNT(*) OVER (PARTITION BY avg_expr)                        AS tie_ct
    FROM eligible
),

ranked2 AS (       -- average rank for ties
    SELECT
        participant,
        hist,
        (r_min + (tie_ct - 1) / 2.0)                                 AS rank_avg
    FROM ranked
),

group_stats AS (   -- S_i, Q_i, n_i per histology
    SELECT
        hist,
        COUNT(*)                                                     AS n_i,
        SUM(rank_avg)                                                AS S_i,
        SUM(rank_avg * rank_avg)                                     AS Q_i
    FROM ranked2
    GROUP BY hist
),

aggregated AS (    -- components for Kruskal‑Wallis H
    SELECT
        COUNT(*)                                                     AS num_groups,
        SUM(n_i)                                                     AS num_samples,
        SUM(S_i * S_i / n_i)                                         AS sum_Ssq_div_n,
        SUM(Q_i)                                                     AS sum_Q,
        SUM(S_i)                                                     AS sum_S
    FROM group_stats
)

SELECT
    num_groups,
    num_samples,
    (
        (num_samples - 1) *
        (sum_Ssq_div_n - POWER(sum_S, 2) / num_samples)
    ) /
    NULLIF(
        (sum_Q - POWER(sum_S, 2) / num_samples),
        0
    )                                                                AS kruskal_wallis_H
FROM aggregated
ORDER BY kruskal_wallis_H DESC NULLS LAST;
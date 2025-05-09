/* Kruskal‑Wallis H‑test for IGF2 expression across ICD‑O‑3 histology groups in LGG */
WITH expr_per_patient AS (          -- 1) mean log10‑transformed expression per participant
    SELECT
        "ParticipantBarcode",
        AVG( LOG(10, "normalized_count" + 1) ) AS "avg_log10_expr"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED
    WHERE "Study" = 'LGG'
      AND "Symbol" = 'IGF2'
      AND "normalized_count" IS NOT NULL
    GROUP BY "ParticipantBarcode"
),
patient_histology AS (              -- 2) LGG participants with usable ICD‑O‑3 histology
    SELECT
        "bcr_patient_barcode"  AS "ParticipantBarcode",
        "icd_o_3_histology"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED
    WHERE "acronym" = 'LGG'
      AND "icd_o_3_histology" IS NOT NULL
      AND NOT REGEXP_LIKE("icd_o_3_histology", '^\\[.*\\]$')
),
joined AS (                         -- 3) expression + histology (one row per participant)
    SELECT
        e."ParticipantBarcode",
        h."icd_o_3_histology",
        e."avg_log10_expr"
    FROM expr_per_patient e
    JOIN patient_histology h
      ON e."ParticipantBarcode" = h."ParticipantBarcode"
),
ranked AS (                         -- 4) tie‑aware ranks
    SELECT
        j.*,
        RANK()  OVER (ORDER BY j."avg_log10_expr")                  AS "first_rank",
        COUNT(*) OVER (PARTITION BY j."avg_log10_expr")             AS "tie_cnt"
    FROM joined j
),
ranks_with_avg AS (                 -- 5) average rank when ties exist
    SELECT
        "ParticipantBarcode",
        "icd_o_3_histology",
        "avg_log10_expr",
        ("first_rank" + (("tie_cnt" - 1) / 2.0))::FLOAT            AS "expr_rank"
    FROM ranked
),
group_stats AS (                    -- 6) Sᵢ and Qᵢ per histology (≥2 patients only)
    SELECT
        "icd_o_3_histology"                    AS "histology",
        COUNT(*)                               AS n_i,
        SUM("expr_rank")                       AS S_i,
        SUM("expr_rank" * "expr_rank")         AS Q_i
    FROM ranks_with_avg
    GROUP BY "icd_o_3_histology"
    HAVING COUNT(*) > 1
),
totals AS (                         -- 7) totals for H statistic
    SELECT
        COUNT(*)                            AS g_groups,
        SUM(n_i)                            AS N_total,
        SUM(S_i)                            AS S_tot,
        SUM(Q_i)                            AS Q_tot,
        SUM(S_i * S_i / n_i)                AS sum_Ssq_over_n
    FROM group_stats
),
kw AS (                              -- 8) Kruskal‑Wallis H
    SELECT
        g_groups,
        N_total,
        (N_total - 1) *
        (sum_Ssq_over_n - (S_tot * S_tot) / N_total) /
        (Q_tot - (S_tot * S_tot) / N_total)          AS H_score
    FROM totals
)
SELECT
    g_groups      AS "total_groups",
    N_total       AS "total_samples",
    H_score       AS "kruskal_wallis_H"
FROM kw
ORDER BY H_score DESC NULLS LAST;
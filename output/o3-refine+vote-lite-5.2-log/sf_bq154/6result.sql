WITH patient_expr AS (   /* 1. Mean log10‑transformed IGF2 expression per LGG participant */
    SELECT
        "ParticipantBarcode"                                   AS participant,
        AVG(LOG(10, "normalized_count" + 1))                   AS expr          -- LOG(base, value)
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED"
    WHERE "Study" = 'LGG'
      AND "Symbol" = 'IGF2'
      AND "normalized_count" IS NOT NULL
    GROUP BY "ParticipantBarcode"
),
clinical AS (            /* 2. ICD‑O‑3 histology per participant */
    SELECT
        "bcr_patient_barcode"  AS participant,
        "icd_o_3_histology"    AS histology
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED"
),
expr_with_hist AS (      /* 3. Merge and filter valid histology codes */
    SELECT
        p.participant,
        c.histology,
        p.expr
    FROM patient_expr p
    JOIN clinical c ON p.participant = c.participant
    WHERE c.histology IS NOT NULL
      AND NOT REGEXP_LIKE(c.histology, '^\\[.*\\]$')
),
ranks AS (               /* 4. Rank expressions across all patients */
    SELECT
        participant,
        histology,
        expr,
        RANK() OVER (ORDER BY expr) AS rnk
    FROM expr_with_hist
),
stats_by_hist AS (       /* 5. Compute nᵢ, Sᵢ, Qᵢ for each histology (nᵢ > 1) */
    SELECT
        histology,
        COUNT(*)                       AS n_i,
        SUM(rnk)                       AS S_i,
        SUM(rnk * rnk)                 AS Q_i
    FROM ranks
    GROUP BY histology
    HAVING COUNT(*) > 1
),
overall AS (             /* 6. Totals needed for Kruskal‑Wallis H */
    SELECT
        SUM(n_i)                              AS N,
        COUNT(*)                              AS num_groups,
        SUM(S_i)                              AS sum_S,
        SUM(Q_i)                              AS sum_Q,
        SUM((S_i * S_i) / n_i)                AS sum_S2_over_n
    FROM stats_by_hist
)
SELECT                    /* 7. Output */
    num_groups            AS number_of_groups,
    N                     AS total_number_of_samples,
    ROUND(
        (N - 1) * (sum_S2_over_n - (sum_S * sum_S) / N)
        / NULLIF(sum_Q - (sum_S * sum_S) / N, 0)
    , 4)                  AS kruskal_wallis_H
FROM overall
ORDER BY kruskal_wallis_H DESC NULLS LAST;
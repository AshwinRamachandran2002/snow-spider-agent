WITH expr AS (   -- IGF2 expression (log10(count+1)) for LGG samples
    SELECT
        "ParticipantBarcode"            AS participant_barcode,
        LOG(10, "normalized_count" + 1) AS expr_val               -- log10
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED
    WHERE "Study" = 'LGG'
      AND "Symbol" = 'IGF2'
      AND "normalized_count" IS NOT NULL
),                                                     
expr_avg AS (        -- one mean value per participant
    SELECT
        participant_barcode,
        AVG(expr_val) AS avg_expr
    FROM expr
    GROUP BY participant_barcode
),
clin AS (            -- LGG clinical data with usable histology code
    SELECT
        "bcr_patient_barcode" AS participant_barcode,
        "icd_o_3_histology"   AS histology
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED
    WHERE "acronym" = 'LGG'
      AND "icd_o_3_histology" IS NOT NULL
      AND NOT REGEXP_LIKE("icd_o_3_histology" , '^\\[.*\\]$')
),
merged AS (          -- participants with both expression and histology
    SELECT
        e.participant_barcode,
        c.histology,
        e.avg_expr
    FROM expr_avg e
    JOIN clin   c
      ON e.participant_barcode = c.participant_barcode
),
ranked AS (          -- assign row numbers by ascending expression
    SELECT
        merged.*,
        ROW_NUMBER() OVER (ORDER BY avg_expr) AS rn
    FROM merged
),
ranks AS (           -- average rank for ties: (min+max)/2
    SELECT
        participant_barcode,
        histology,
        (MIN(rn) OVER (PARTITION BY avg_expr)
         + MAX(rn) OVER (PARTITION BY avg_expr)) / 2.0 AS rnk
    FROM ranked
),
stats AS (           -- Sᵢ , Qᵢ  per histology (keep groups with n>1)
    SELECT
        histology,
        COUNT(*)          AS n_i,
        SUM(rnk)          AS S_i,
        SUM(rnk * rnk)    AS Q_i
    FROM ranks
    GROUP BY histology
    HAVING COUNT(*) > 1
),
tot AS (             -- aggregated totals used in H formula
    SELECT
        SUM(n_i)                       AS N,
        SUM(S_i)                       AS sum_S,
        SUM(Q_i)                       AS sum_Q,
        SUM(S_i * S_i / n_i)           AS sum_S2_over_n
    FROM stats
)
SELECT
    (SELECT COUNT(*) FROM stats)                             AS total_groups,
    tot.N                                                    AS total_samples,
    /* Kruskal‑Wallis H */
    ((tot.N - 1) *
      (tot.sum_S2_over_n - (tot.sum_S * tot.sum_S) / tot.N))
      / (tot.sum_Q - (tot.sum_S * tot.sum_S) / tot.N)        AS H_score
FROM tot
ORDER BY H_score DESC NULLS LAST;
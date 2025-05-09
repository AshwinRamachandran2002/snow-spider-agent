/* Kruskal-Wallis H-test for IGF2 expression (LGG) grouped by ICD-O-3 histology */

WITH expr_per_patient AS (            /* 1. Mean log10(normalized_count+1) per patient */
    SELECT
        clin."icd_o_3_histology"                AS icd,
        expr."ParticipantBarcode"               AS patient_id,
        AVG( LOG(10, expr."normalized_count" + 1) )  AS expr_value
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED  expr
    JOIN PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED            clin
          ON expr."ParticipantBarcode" = clin."bcr_patient_barcode"
    WHERE expr."Study"  = 'LGG'
      AND expr."Symbol" = 'IGF2'
      AND expr."normalized_count" IS NOT NULL
      AND NOT REGEXP_LIKE(clin."icd_o_3_histology", '^\\[.*\\]$')
    GROUP BY
        clin."icd_o_3_histology",
        expr."ParticipantBarcode"
),
ranked AS (                            /* 2. Minimum rank and tie count */
    SELECT
        icd,
        patient_id,
        expr_value,
        RANK()  OVER (ORDER BY expr_value)      AS min_rank,
        COUNT(*) OVER (PARTITION BY expr_value) AS tie_cnt
    FROM expr_per_patient
),
ranks AS (                              /* 3. Average rank for ties */
    SELECT
        icd,
        patient_id,
        min_rank + (tie_cnt - 1) / 2.0  AS avg_rank
    FROM ranked
),
group_stats AS (                        /* 4. Sᵢ , Qᵢ , nᵢ for every histology (keep groups > 1) */
    SELECT
        icd,
        COUNT(*)                AS n_i,
        SUM(avg_rank)           AS S_i,
        SUM(POWER(avg_rank,2))  AS Q_i
    FROM ranks
    GROUP BY icd
    HAVING COUNT(*) > 1
),
totals AS (                             /* 5. Pre-compute totals used in H */
    SELECT
        COUNT(*)                        AS g,             -- number of groups
        SUM(n_i)                        AS N,             -- total samples
        SUM(S_i)                        AS S,
        SUM(S_i * S_i / n_i)            AS sum_S2_over_n,
        SUM(Q_i)                        AS sum_Q
    FROM group_stats
)

SELECT
    g                                                AS "num_groups",
    N                                                AS "total_samples",
    ROUND(                                           -- Kruskal-Wallis H statistic
          ( (N - 1) * (sum_S2_over_n - (S * S) / N) )
          /
          ( sum_Q - (S * S) / N )
    , 4)                                             AS "kruskal_wallis_h_score"
FROM totals
ORDER BY "kruskal_wallis_h_score" DESC NULLS LAST;
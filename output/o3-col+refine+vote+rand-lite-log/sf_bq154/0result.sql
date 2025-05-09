/* Kruskal-Wallis H-test for IGF2 log-expression across ICD-O-3 histology groups */

WITH expr AS (   /* mean log10(normalized_count+1) for each participant */
    SELECT
        "ParticipantBarcode"                                AS "patient",
        AVG( LOG("normalized_count" + 1, 10) )              AS "avg_log_expr"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED
    WHERE "Symbol" = 'IGF2'
      AND "normalized_count" IS NOT NULL
    GROUP BY "ParticipantBarcode"
),
joined AS (      /* attach histology, drop codes like “[Not Available]” */
    SELECT
        e."patient",
        c."icd_o_3_histology"                              AS "histology",
        e."avg_log_expr"
    FROM expr e
    JOIN PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED c
      ON e."patient" = c."bcr_patient_barcode"
    WHERE NOT REGEXP_LIKE(c."icd_o_3_histology", '^\\[.*\\]$')
),
ranked AS (      /* average rank (mid-ranks) */
    SELECT
        "histology",
        "patient",
        (
            RANK() OVER (ORDER BY "avg_log_expr")
          + RANK() OVER (ORDER BY "avg_log_expr" DESC) - 1
        ) / 2.0                                           AS "rank_avg"
    FROM joined
),
grp AS (         /* n_i, Σr_i, Σr_i²; keep groups with >1 participant */
    SELECT
        "histology",
        COUNT(*)                       AS n_i,
        SUM("rank_avg")                AS S_i,
        SUM(POWER("rank_avg", 2))      AS Q_i
    FROM ranked
    GROUP BY "histology"
    HAVING COUNT(*) > 1
),
agg AS (         /* aggregates needed for H */
    SELECT
        COUNT(*)                    AS num_groups,
        SUM(n_i)                    AS N_total,
        SUM(S_i)                    AS sum_s,
        SUM(Q_i)                    AS sum_q,
        SUM(S_i * S_i / n_i)        AS sum_s2_over_ni
    FROM grp
),
stats AS (
    SELECT
        num_groups,
        N_total                      AS total_samples,
        CASE
            WHEN num_groups > 1
             AND (sum_q - POWER(sum_s, 2) / N_total) <> 0
            THEN
                (N_total - 1)
                * ( sum_s2_over_ni - POWER(sum_s, 2) / N_total )
                / ( sum_q - POWER(sum_s, 2) / N_total )
            ELSE NULL
        END                         AS H_score
    FROM agg
)

SELECT
    num_groups,
    total_samples,
    H_score
FROM stats
ORDER BY H_score DESC NULLS LAST;
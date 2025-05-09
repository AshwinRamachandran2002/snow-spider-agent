WITH expr_per_sample AS (   -- 1) IGF2 expression for LGG samples
    SELECT
        "ParticipantBarcode"                           AS patient_id,
        LOG(10, "normalized_count" + 1)                AS log_expr      -- base‑10 log
    FROM  PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED"
    WHERE "Study" = 'LGG'
      AND "Symbol" = 'IGF2'
      AND "normalized_count" IS NOT NULL
),
expr_per_patient AS (       -- 2) mean expression per patient
    SELECT
        patient_id,
        AVG(log_expr)       AS expr_avg
    FROM expr_per_sample
    GROUP BY patient_id
),
clinical_lgg AS (           -- 3) LGG patients with usable ICD‑O‑3 histology
    SELECT
        "bcr_patient_barcode"  AS patient_id,
        "icd_o_3_histology"    AS hist_code
    FROM  PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED"
    WHERE "acronym" = 'LGG'
      AND "icd_o_3_histology" IS NOT NULL
      AND NOT REGEXP_LIKE("icd_o_3_histology",'^\[.*\]$')   -- exclude codes like [Not‑available]
),
patient_set AS (            -- 4) patients with both expression & histology
    SELECT
        e.patient_id,
        e.expr_avg,
        c.hist_code
    FROM expr_per_patient e
    JOIN clinical_lgg     c USING (patient_id)
),
ranked AS (                 -- 5) obtain minimum rank and tie count
    SELECT
        patient_id,
        hist_code,
        expr_avg,
        RANK()  OVER (ORDER BY expr_avg)                  AS rank_min,
        COUNT(*) OVER (PARTITION BY expr_avg)             AS tie_cnt
    FROM patient_set
),
rank_for_test AS (          -- 6) average rank for ties
    SELECT
        patient_id,
        hist_code,
        expr_avg,
        rank_min + (tie_cnt - 1) / 2.0 AS avg_rank
    FROM ranked
),
group_stats AS (            -- 7) Sᵢ , Qᵢ , nᵢ for each histology (need >1 sample)
    SELECT
        hist_code,
        COUNT(*)                       AS n_i,
        SUM(avg_rank)                  AS S_i,
        SUM(POWER(avg_rank, 2))        AS Q_i
    FROM rank_for_test
    GROUP BY hist_code
    HAVING COUNT(*) > 1
),
totals AS (                  -- 8) overall aggregates for H
    SELECT
        COUNT(*)                           AS num_groups,
        SUM(n_i)                           AS N,
        SUM(S_i)                           AS sum_S,
        SUM(Q_i)                           AS sum_Q,
        SUM( S_i * S_i / n_i )             AS sum_S_sq_over_n
    FROM group_stats
)
SELECT
    num_groups                         AS total_groups,
    N                                  AS total_samples,
    (N - 1) *
    ( sum_S_sq_over_n - POWER(sum_S, 2) / N ) /
    NULLIF( sum_Q - POWER(sum_S, 2) / N , 0)  AS kruskal_wallis_H
FROM totals
ORDER BY kruskal_wallis_H DESC NULLS LAST;
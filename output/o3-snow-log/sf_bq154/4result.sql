WITH patient_expr AS (   -- 1. LGG IGF2 expression per aliquot
    SELECT
        "ParticipantBarcode"                                    AS patient_barcode,
        LOG(10, "normalized_count" + 1)                         AS expr_log          -- log10
    FROM   PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED"
    WHERE  "Study" = 'LGG'
      AND  "Symbol" = 'IGF2'
      AND  "normalized_count" IS NOT NULL
),
patient_mean AS (         -- 2. mean log-expression per patient
    SELECT
        patient_barcode,
        AVG(expr_log) AS expr_log_avg
    FROM patient_expr
    GROUP BY patient_barcode
),
clinical AS (             -- 3. histology code per patient
    SELECT
        "bcr_patient_barcode" AS patient_barcode,
        "icd_o_3_histology"   AS hist_code
    FROM   PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED"
),
merged AS (               -- 4. join expression with clinical, exclude bracketed codes
    SELECT
        p.patient_barcode,
        c.hist_code,
        p.expr_log_avg
    FROM   patient_mean p
    JOIN   clinical     c ON p.patient_barcode = c.patient_barcode
    WHERE  c.hist_code IS NOT NULL
      AND  NOT REGEXP_LIKE(c.hist_code, '^\\[.*\\]$')
),
eligible_hist AS (        -- 5. retain histology groups having >1 patient
    SELECT hist_code
    FROM   merged
    GROUP BY hist_code
    HAVING COUNT(*) > 1
),
filtered AS (
    SELECT m.*
    FROM   merged m
    JOIN   eligible_hist e ON m.hist_code = e.hist_code
),
value_counts AS (         -- 6. counts of distinct expression values
    SELECT
        expr_log_avg,
        COUNT(*) AS n_value
    FROM   filtered
    GROUP BY expr_log_avg
),
value_ranks AS (          -- 7. cumulative counts for rank calculation
    SELECT
        expr_log_avg,
        n_value,
        COALESCE(
            SUM(n_value) OVER (ORDER BY expr_log_avg
                               ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING),0
        ) AS cum_before
    FROM value_counts
),
value_rank_avg AS (       -- 8. average rank per distinct value
    SELECT
        expr_log_avg,
        cum_before + (n_value + 1)/2.0 AS avg_rank
    FROM value_ranks
),
patient_ranks AS (        -- 9. assign rank to each patient
    SELECT
        f.patient_barcode,
        f.hist_code,
        v.avg_rank AS rank_val
    FROM   filtered f
    JOIN   value_rank_avg v ON f.expr_log_avg = v.expr_log_avg
),
group_stats AS (          --10. S_i, Q_i, n_i per histology group
    SELECT
        hist_code,
        COUNT(*)                 AS n_i,
        SUM(rank_val)            AS S_i,
        SUM(rank_val * rank_val) AS Q_i
    FROM   patient_ranks
    GROUP BY hist_code
),
totals AS (               --11. aggregated components for H statistic
    SELECT
        COUNT(*)                          AS total_groups,
        SUM(n_i)                          AS N,
        SUM(S_i)                          AS sum_S,
        SUM(Q_i)                          AS sum_Q,
        SUM( (S_i * S_i) / n_i )          AS sum_S_sq_over_n
    FROM group_stats
),
h_calc AS (               --12. Kruskal-Wallis H value
    SELECT
        total_groups,
        N                AS total_samples,
        ( (N - 1) * ( sum_S_sq_over_n - (sum_S * sum_S) / N ) )
        /
        ( sum_Q - (sum_S * sum_S) / N )   AS H_score
    FROM totals
)
SELECT
    total_groups,
    total_samples,
    ROUND(H_score, 4) AS "H_SCORE"
FROM h_calc
ORDER BY H_score DESC NULLS LAST;
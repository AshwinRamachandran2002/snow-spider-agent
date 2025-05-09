WITH expr_avg AS (
    /* 1.  LGG RNA‑seq: average log10(normalized_count+1) for IGF2 per participant */
    SELECT
        "ParticipantBarcode"                             AS patient_id,
        AVG( LOG("normalized_count" + 1 , 10) )          AS avg_expr     -- log10
    FROM
        PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED
    WHERE
        "Study"  = 'LGG'
        AND "Symbol" = 'IGF2'
        AND "normalized_count" IS NOT NULL
    GROUP BY
        "ParticipantBarcode"
),
clin AS (
    /* 2.  Clinical table: ICD‑O‑3 histology per participant */
    SELECT
        "bcr_patient_barcode"   AS patient_id,
        "icd_o_3_histology"     AS histology
    FROM
        PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED
),
patients AS (
    /* 3.  Join and keep valid histology codes (not enclosed in square brackets) */
    SELECT
        e.patient_id,
        c.histology,
        e.avg_expr
    FROM
        expr_avg e
        INNER JOIN clin c
            ON e.patient_id = c.patient_id
    WHERE
        c.histology IS NOT NULL
        AND NOT REGEXP_LIKE(c.histology , '^\\[.*\\]$')
),
ranked AS (
    /* 4.  Assign average ranks to expression values (ties get average rank) */
    SELECT
        patient_id,
        histology,
        avg_expr,
        RANK()  OVER (ORDER BY avg_expr)                  AS rnk_min,
        COUNT(*) OVER (PARTITION BY avg_expr)             AS tie_cnt
    FROM
        patients
),
ranks AS (
    SELECT
        patient_id,
        histology,
        /* average rank for ties = min_rank + (cnt‑1)/2 */
        ( rnk_min + (tie_cnt - 1) / 2.0 )                 AS avg_rank
    FROM
        ranked
),
group_stats AS (
    /* 5.  S_i, Q_i, n_i per histology; keep groups with >1 patient */
    SELECT
        histology,
        COUNT(*)                        AS n_i,
        SUM(avg_rank)                   AS S_i,
        SUM( POWER(avg_rank, 2) )       AS Q_i
    FROM
        ranks
    GROUP BY
        histology
    HAVING
        COUNT(*) > 1
),
overall AS (
    /* 6.  Pre‑compute global totals needed for H statistic */
    SELECT
        SUM(n_i)                                AS N,
        SUM(S_i)                                AS total_S,
        SUM(Q_i)                                AS total_Q,
        SUM( POWER(S_i, 2) / n_i )              AS sum_S_sq_over_n
    FROM
        group_stats
),
kw AS (
    /* 7.  Kruskal‑Wallis H calculation */
    SELECT
        (N - 1)
        * ( sum_S_sq_over_n - POWER(total_S, 2) / N )
        / ( total_Q           - POWER(total_S, 2) / N )   AS H_score,
        (SELECT COUNT(*) FROM group_stats)                AS num_groups,
        N                                                 AS total_samples
    FROM
        overall
)
SELECT
    num_groups,
    total_samples,
    H_score
FROM
    kw
ORDER BY
    H_score DESC NULLS LAST;
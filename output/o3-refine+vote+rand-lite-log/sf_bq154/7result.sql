WITH
-- 1) Average log‑transformed IGF2 expression per LGG participant
expr_per_patient AS (
    SELECT
        "ParticipantBarcode",
        AVG( LOG(10, "normalized_count" + 1) )                        AS expr
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED
    WHERE
        "Study"               = 'LGG'
        AND "Symbol"          = 'IGF2'
        AND "normalized_count" IS NOT NULL
    GROUP BY
        "ParticipantBarcode"
),
-- 2) Keep valid ICD‑O‑3 histology values (not null and not enclosed in brackets)
clinical_filtered AS (
    SELECT
        "bcr_patient_barcode"  AS participant_barcode,
        "icd_o_3_histology"    AS histology
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED
    WHERE
        "icd_o_3_histology" IS NOT NULL
        AND "icd_o_3_histology" NOT LIKE '[%'     -- discard bracket codes
),
-- 3) Merge expression with histology
patient_data AS (
    SELECT
        e."ParticipantBarcode" AS participant_barcode,
        e.expr,
        c.histology
    FROM expr_per_patient e
    JOIN clinical_filtered c
      ON c.participant_barcode = e."ParticipantBarcode"
),
-- 4) Assign average ranks (ties get average rank)
ranked AS (
    SELECT
        participant_barcode,
        histology,
        expr,
        RANK()  OVER (ORDER BY expr)                AS r_min,
        COUNT(*) OVER (PARTITION BY expr)           AS tie_cnt
    FROM patient_data
),
ranks_with_avg AS (
    SELECT
        participant_barcode,
        histology,
        expr,
        r_min + (tie_cnt - 1) / 2.0                 AS r_avg
    FROM ranked
),
-- 5) Per‑histology aggregates; keep groups with >1 patient
group_stats AS (
    SELECT
        histology,
        COUNT(*)              AS n_i,
        SUM(r_avg)            AS S_i,
        SUM(POWER(r_avg, 2))  AS Q_i
    FROM ranks_with_avg
    GROUP BY histology
    HAVING COUNT(*) > 1
),
-- 6) Global sums for Kruskal‑Wallis calculation
global_sums AS (
    SELECT
        SUM(n_i)                              AS N,
        COUNT(*)                              AS g,
        SUM(POWER(S_i, 2) / n_i)              AS sum_S_sq_div_n,
        SUM(S_i)                              AS sum_S,
        SUM(Q_i)                              AS sum_Q
    FROM group_stats
)
-- 7) Final Kruskal‑Wallis H statistic
SELECT
    g  AS total_number_groups,
    N  AS total_number_samples,
    (N - 1) *
    ( sum_S_sq_div_n - POWER(sum_S, 2) / N ) /
    NULLIF( sum_Q - POWER(sum_S, 2) / N , 0 ) AS h_score
FROM global_sums
ORDER BY h_score DESC NULLS LAST;
WITH data AS (
    SELECT 
        t1."ParticipantBarcode",
        t2."icd_o_3_histology",
        LOG(t1."normalized_count", 10) AS "log_expression"
    FROM 
        PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED t1
    JOIN 
        PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED t2
            ON t1."ParticipantBarcode" = t2."bcr_patient_barcode"
    WHERE 
        t1."Symbol" = 'IGF2'
        AND t2."acronym" = 'LGG'
        AND t1."normalized_count" > 0
),
ranks AS (
    SELECT 
        d.*,
        RANK() OVER (ORDER BY d."log_expression" ASC NULLS LAST) AS rank_start
    FROM data d
),
average_ranks AS (
    SELECT 
        r."ParticipantBarcode",
        r."icd_o_3_histology",
        r."log_expression",
        AVG(r.rank_start) OVER (PARTITION BY r."log_expression") AS avg_rank
    FROM ranks r
),
group_stats AS (
    SELECT 
        "icd_o_3_histology",
        COUNT(*) AS n_i,
        SUM(avg_rank) AS sum_ranks,
        AVG(avg_rank) AS R_i
    FROM average_ranks
    GROUP BY "icd_o_3_histology"
),
total_stats AS (
    SELECT 
        COUNT(*) AS N,
        AVG(avg_rank) AS mean_rank
    FROM average_ranks
),
sum_term AS (
    SELECT 
        SUM(gstats.n_i * POWER(gstats.R_i - tstats.mean_rank, 2)) AS sum_value,
        tstats.N,
        tstats.mean_rank
    FROM group_stats gstats
    CROSS JOIN total_stats tstats
    GROUP BY tstats.N, tstats.mean_rank
)
SELECT 
    ROUND(
        (12.0 / (sum_term.N * (sum_term.N + 1))) * sum_term.sum_value, 4
    ) AS "H-score"
FROM sum_term;
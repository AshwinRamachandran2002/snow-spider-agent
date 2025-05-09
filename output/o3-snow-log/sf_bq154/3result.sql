WITH expr_per_patient AS (         -- 1) IGF2 log10 expression averaged per patient
    SELECT
        e."ParticipantBarcode"                       AS patient_barcode ,
        AVG( LOG( e."normalized_count" + 1 , 10 ) )  AS log_expr          -- Snowflake: LOG(value , base)
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED e
    WHERE e."Study"  = 'LGG'
      AND e."Symbol" = 'IGF2'
      AND e."normalized_count" IS NOT NULL
    GROUP BY e."ParticipantBarcode"
),                                                   -- 2) clinical data, exclude codes in brackets
clinical_filtered AS (
    SELECT
        c."bcr_patient_barcode"  AS patient_barcode ,
        c."icd_o_3_histology"    AS histology
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED c
    WHERE c."icd_o_3_histology" IS NOT NULL
      AND NOT REGEXP_LIKE( c."icd_o_3_histology" , '^\\[.*\\]$' )
),
joined AS (                        -- join expression with histology
    SELECT
        e.patient_barcode ,
        e.log_expr ,
        cf.histology
    FROM expr_per_patient  e
    JOIN clinical_filtered cf
      ON cf.patient_barcode = e.patient_barcode
),
ranked AS (                        -- 3) ranks and tie counts
    SELECT
        patient_barcode ,
        histology ,
        log_expr ,
        RANK()  OVER (ORDER BY log_expr)                       AS r_min ,
        COUNT(*) OVER (PARTITION BY log_expr)                  AS tie_cnt
    FROM joined
),
ranked_with_avg AS (               -- average rank for ties
    SELECT
        patient_barcode ,
        histology ,
        ( r_min + r_min + tie_cnt - 1 ) / 2.0                  AS avg_rank
    FROM ranked
),
group_stats AS (                   -- 4) per-histology aggregates (keep groups >1)
    SELECT
        histology ,
        COUNT(*)                     AS n_i ,
        SUM( avg_rank )              AS S_i ,
        SUM( POWER( avg_rank , 2 ) ) AS Q_i
    FROM ranked_with_avg
    GROUP BY histology
    HAVING COUNT(*) > 1
),
aggregates AS (                    -- accumulate totals needed for H
    SELECT
        COUNT(*)                                       AS groups_count ,
        SUM( n_i )                                     AS N ,
        SUM( POWER( S_i , 2 ) / n_i )                  AS sum_S_sq_div_n ,
        SUM( S_i )                                     AS sum_S ,
        SUM( Q_i )                                     AS sum_Q
    FROM group_stats
),
final_calc AS (                    -- 5) Kruskal-Wallis H
    SELECT
        groups_count ,
        N                             AS total_samples ,
        ( N - 1 ) *
        ( sum_S_sq_div_n - POWER( sum_S , 2 ) / N ) /
        ( sum_Q         - POWER( sum_S , 2 ) / N )    AS H_score
    FROM aggregates
)
SELECT
    groups_count ,
    total_samples ,
    H_score
FROM final_calc
ORDER BY H_score DESC NULLS LAST;
/*---------------------------------------------------------------
  Kruskal-Wallis H for IGF2 log10 expression across ICD-O-3
  histology groups within LGG patients (Snowflake dialect)
----------------------------------------------------------------*/
WITH lgg_patients AS (      -- LGG clinical records
    SELECT
        "bcr_patient_barcode"  AS patient_id,
        "icd_o_3_histology"    AS histology
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED
    WHERE
        "acronym" = 'LGG'
        AND "icd_o_3_histology" IS NOT NULL
        AND "icd_o_3_histology" NOT LIKE '[%]'      -- exclude indeterminate values
),
igf2_expr AS (              -- IGF2 expression rows (log10)
    SELECT
        "ParticipantBarcode"           AS patient_id,
        LOG(10, "normalized_count" + 1) AS log_expr
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED
    WHERE
        "Symbol" = 'IGF2'
        AND "normalized_count" IS NOT NULL
),
patient_avg AS (            -- average per patient
    SELECT
        p.histology,
        e.patient_id,
        AVG(e.log_expr) AS avg_log_expr
    FROM lgg_patients p
    JOIN igf2_expr  e ON e.patient_id = p.patient_id
    GROUP BY p.histology, e.patient_id
),
ordered AS (                -- give each row a unique order for ranking
    SELECT
        *,
        ROW_NUMBER() OVER (ORDER BY avg_log_expr) AS rn
    FROM patient_avg
),
ranked AS (                 -- compute mid-rank for ties
    SELECT
        histology,
        patient_id,
        avg_log_expr,
        (MIN(rn) OVER (PARTITION BY avg_log_expr)
       + MAX(rn) OVER (PARTITION BY avg_log_expr)) / 2.0 AS rank_val
    FROM ordered
),
group_stats AS (            -- nᵢ , Sᵢ , Qᵢ per histology (keep nᵢ>1)
    SELECT
        histology,
        COUNT(*)                                AS n_i,
        SUM(rank_val)                           AS s_i,
        SUM(POWER(rank_val,2))                  AS q_i,
        SUM(rank_val) * SUM(rank_val) / COUNT(*) AS s_sq_over_n
    FROM ranked
    GROUP BY histology
    HAVING COUNT(*) > 1
),
totals AS (                 -- overall totals
    SELECT
        SUM(n_i)          AS N,
        SUM(s_i)          AS S,
        SUM(q_i)          AS Q,
        SUM(s_sq_over_n)  AS sum_s_sq_over_n,
        COUNT(*)          AS g
    FROM group_stats
)
SELECT
    g AS "num_groups",
    N AS "total_samples",
    /* H = (N-1) * ( Σ Sᵢ²/nᵢ  –  S²/N )  /  ( Σ Qᵢ  –  S²/N ) */
    (N - 1) * (sum_s_sq_over_n - (S * S) / N) 
           / (Q - (S * S) / N)             AS "H_score"
FROM totals
ORDER BY "H_score" DESC NULLS LAST;
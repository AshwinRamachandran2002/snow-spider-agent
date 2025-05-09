WITH gene_expr AS (
    SELECT
        "ParticipantBarcode",
        AVG(LOG(2, "normalized_count" + 1)) AS "log_norm_expr"
    FROM
        PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED
    WHERE
        "Symbol" = 'DRG2' AND "Study" = 'LGG'
    GROUP BY
        "ParticipantBarcode"
),
tp53_mutations AS (
    SELECT DISTINCT
        "ParticipantBarcode",
        'YES' AS "mutation_status"
    FROM
        PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE
    WHERE
        "Hugo_Symbol" = 'TP53' AND "FILTER" = 'PASS' AND "Study" = 'LGG'
),
expr_with_status AS (
    SELECT
        g."ParticipantBarcode",
        g."log_norm_expr",
        COALESCE(m."mutation_status", 'NO') AS "mutation_status"
    FROM
        gene_expr g
        LEFT JOIN tp53_mutations m ON g."ParticipantBarcode" = m."ParticipantBarcode"
)
SELECT
    COUNT(CASE WHEN "mutation_status" = 'YES' THEN 1 END) AS "Ny",
    COUNT(CASE WHEN "mutation_status" = 'NO' THEN 1 END) AS "Nn",
    ROUND(AVG(CASE WHEN "mutation_status" = 'YES' THEN "log_norm_expr" END), 4) AS "avg_y",
    ROUND(AVG(CASE WHEN "mutation_status" = 'NO' THEN "log_norm_expr" END), 4) AS "avg_n",
    ROUND(
        (
            AVG(CASE WHEN "mutation_status" = 'YES' THEN "log_norm_expr" END) -
            AVG(CASE WHEN "mutation_status" = 'NO' THEN "log_norm_expr" END)
        ) /
        SQRT(
            (VAR_SAMP(CASE WHEN "mutation_status" = 'YES' THEN "log_norm_expr" END) /
                NULLIF(COUNT(CASE WHEN "mutation_status" = 'YES' THEN 1 END), 0)) +
            (VAR_SAMP(CASE WHEN "mutation_status" = 'NO' THEN "log_norm_expr" END) /
                NULLIF(COUNT(CASE WHEN "mutation_status" = 'NO' THEN 1 END), 0))
        ), 4
    ) AS "tscore"
FROM
    expr_with_status;
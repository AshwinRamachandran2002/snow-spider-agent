WITH
mutated_group AS (
    SELECT expr."normalized_count"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED expr
    INNER JOIN (
        SELECT DISTINCT "ParticipantBarcode"
        FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE
        WHERE "Study" = 'LGG' AND "Hugo_Symbol" = 'TP53'
    ) mutated ON expr."ParticipantBarcode" = mutated."ParticipantBarcode"
    WHERE expr."Study" = 'LGG' AND expr."Symbol" = 'DRG2'
),
mutated_stats AS (
    SELECT
        COUNT(*) AS N_y,
        AVG("normalized_count") AS g_y,
        VAR_SAMP("normalized_count") AS s2_y
    FROM mutated_group
),
non_mutated_group AS (
    SELECT expr."normalized_count"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED expr
    LEFT JOIN (
        SELECT DISTINCT "ParticipantBarcode"
        FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE
        WHERE "Study" = 'LGG' AND "Hugo_Symbol" = 'TP53'
    ) mutated ON expr."ParticipantBarcode" = mutated."ParticipantBarcode"
    WHERE expr."Study" = 'LGG' AND expr."Symbol" = 'DRG2' AND mutated."ParticipantBarcode" IS NULL
),
non_mutated_stats AS (
    SELECT
        COUNT(*) AS N_n,
        AVG("normalized_count") AS g_n,
        VAR_SAMP("normalized_count") AS s2_n
    FROM non_mutated_group
)
SELECT
    ROUND( (g_y - g_n) / SQRT( (s2_y / N_y) + (s2_n / N_n) ), 4) AS "t-score"
FROM mutated_stats CROSS JOIN non_mutated_stats
WHERE mutated_stats.N_y >= 10 AND non_mutated_stats.N_n >= 10 AND mutated_stats.s2_y > 0 AND non_mutated_stats.s2_n > 0;
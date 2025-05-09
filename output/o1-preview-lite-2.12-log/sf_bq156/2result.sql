WITH expression_data AS (
    SELECT e."ParticipantBarcode", e."normalized_count",
           CASE WHEN m."ParticipantBarcode" IS NULL THEN 'Non-Mutated' ELSE 'Mutated' END AS "MutationStatus"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED" e
    LEFT JOIN PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE" m
      ON e."ParticipantBarcode" = m."ParticipantBarcode" AND m."Hugo_Symbol" = 'TP53' AND m."Study" = 'LGG'
    WHERE e."Symbol" = 'DRG2' AND e."Study" = 'LGG'
),
group_stats AS (
    SELECT
        "MutationStatus",
        COUNT(*) AS N,
        AVG("normalized_count") AS mean_expression,
        VAR_SAMP("normalized_count") AS variance_expression
    FROM expression_data
    GROUP BY "MutationStatus"
    HAVING COUNT(*) >= 10 AND VAR_SAMP("normalized_count") > 0
),
mutated AS (
    SELECT * FROM group_stats WHERE "MutationStatus" = 'Mutated'
),
non_mutated AS (
    SELECT * FROM group_stats WHERE "MutationStatus" = 'Non-Mutated'
)
SELECT ROUND(
    (mutated.mean_expression - non_mutated.mean_expression) /
    SQRT( (mutated.variance_expression / mutated.N) + (non_mutated.variance_expression / non_mutated.N) ),
    4
) AS "t-score"
FROM mutated, non_mutated;
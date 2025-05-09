WITH lgg_samples AS (          -- LGG tumour samples present in the MAF table
    SELECT DISTINCT
           "ParticipantBarcode",
           "Tumor_SampleBarcode" AS "SampleBarcode"
    FROM   PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE
    WHERE  "Study" = 'LGG'
),
tp53_mutated AS (              -- LGG participants with a PASS‑filtered TP53 mutation
    SELECT DISTINCT
           "ParticipantBarcode"
    FROM   PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE
    WHERE  "Study"       = 'LGG'
      AND  "Hugo_Symbol" = 'TP53'
      AND  "FILTER"      = 'PASS'
),
expr_per_participant AS (      -- mean log10(normalized_count+1) of DRG2 per participant
    SELECT
        s."ParticipantBarcode",
        AVG( LOG(10, e."normalized_count" + 1) ) AS "avg_expr"
    FROM   PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED e
    JOIN   lgg_samples s
           ON e."SampleBarcode" = s."SampleBarcode"
    WHERE  e."Study"  = 'LGG'
      AND  e."Symbol" = 'DRG2'
    GROUP  BY s."ParticipantBarcode"
),
expr_with_status AS (          -- label participants as TP53‑mutated (YES/NO)
    SELECT
        e."ParticipantBarcode",
        e."avg_expr",
        CASE WHEN t."ParticipantBarcode" IS NOT NULL THEN 'YES' ELSE 'NO' END AS "tp53_status"
    FROM   expr_per_participant e
    LEFT  JOIN tp53_mutated t
           ON e."ParticipantBarcode" = t."ParticipantBarcode"
),
group_sums AS (                -- N, Σg, Σg² for each group
    SELECT
        "tp53_status",
        COUNT(*)                  AS "N",
        SUM("avg_expr")           AS "S",
        SUM(POWER("avg_expr", 2)) AS "Q"
    FROM   expr_with_status
    GROUP  BY "tp53_status"
),
stats AS (                      -- compute means and variances
    SELECT
        (SELECT "N" FROM group_sums WHERE "tp53_status" = 'YES')                           AS "Ny",
        (SELECT "N" FROM group_sums WHERE "tp53_status" = 'NO')                            AS "Nn",
        (SELECT "S" FROM group_sums WHERE "tp53_status" = 'YES') /
        NULLIF((SELECT "N" FROM group_sums WHERE "tp53_status" = 'YES'), 0)                AS "avg_y",
        (SELECT "S" FROM group_sums WHERE "tp53_status" = 'NO')  /
        NULLIF((SELECT "N" FROM group_sums WHERE "tp53_status" = 'NO'), 0)                 AS "avg_n",
        ((SELECT "Q" FROM group_sums WHERE "tp53_status" = 'YES') -
         POWER((SELECT "S" FROM group_sums WHERE "tp53_status" = 'YES'), 2) /
         NULLIF((SELECT "N" FROM group_sums WHERE "tp53_status" = 'YES'), 0))
         /
        NULLIF((SELECT "N" FROM group_sums WHERE "tp53_status" = 'YES') - 1, 0)            AS "var_y",
        ((SELECT "Q" FROM group_sums WHERE "tp53_status" = 'NO') -
         POWER((SELECT "S" FROM group_sums WHERE "tp53_status" = 'NO'), 2) /
         NULLIF((SELECT "N" FROM group_sums WHERE "tp53_status" = 'NO'), 0))
         /
        NULLIF((SELECT "N" FROM group_sums WHERE "tp53_status" = 'NO') - 1, 0)             AS "var_n"
)
SELECT
    "Ny"                                                   AS "n_with_tp53_mut",
    "Nn"                                                   AS "n_without_tp53_mut",
    "avg_y"                                                AS "mean_expr_mut",
    "avg_n"                                                AS "mean_expr_nonmut",
    ("avg_y" - "avg_n") /
    SQRT( "var_y"/"Ny" + "var_n"/"Nn" )                   AS "t_score"
FROM stats;
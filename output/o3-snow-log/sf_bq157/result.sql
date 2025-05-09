/*--------------------------------------------------------------------
Welch’s T-score for log10-transformed DRG2 expression in LGG patients
WITH vs. WITHOUT a ‘PASS’ TP53 mutation (Snowflake SQL)
--------------------------------------------------------------------*/
WITH
/* 1. LGG cases appearing in mutation table ------------------------*/
lgg_cases AS (
    SELECT DISTINCT "ParticipantBarcode"
    FROM   PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE  "Study" = 'LGG'           -- LGG cohort
),

/* 2. LGG cases carrying a PASS TP53 mutation ----------------------*/
tp53_mutated AS (
    SELECT DISTINCT "ParticipantBarcode"
    FROM   PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE  "Study"       = 'LGG'
      AND  "Hugo_Symbol" = 'TP53'
      AND  "FILTER"      = 'PASS'
),

/* 3. Per-patient mean log10(normalized_count + 1) for DRG2 --------*/
expr_per_case AS (
    SELECT
        e."ParticipantBarcode",
        AVG( LOG(10, e."normalized_count" + 1) ) AS "avg_log_expr"
    FROM   PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED" e
           JOIN lgg_cases c
             ON c."ParticipantBarcode" = e."ParticipantBarcode"
    WHERE  e."Symbol" = 'DRG2'
    GROUP  BY e."ParticipantBarcode"
),

/* 4. Aggregate counts, sums, and squared sums for the two groups --*/
aggregates AS (
    SELECT
        /* counts */
        SUM(CASE WHEN m."ParticipantBarcode" IS NOT NULL THEN 1 ELSE 0 END)::FLOAT AS "Ny",
        SUM(CASE WHEN m."ParticipantBarcode" IS     NULL THEN 1 ELSE 0 END)::FLOAT AS "Nn",

        /* sums */
        SUM(CASE WHEN m."ParticipantBarcode" IS NOT NULL THEN e."avg_log_expr" ELSE 0 END) AS "Sy",
        SUM(CASE WHEN m."ParticipantBarcode" IS     NULL THEN e."avg_log_expr" ELSE 0 END) AS "Sn",

        /* sums of squares */
        SUM(CASE WHEN m."ParticipantBarcode" IS NOT NULL THEN POWER(e."avg_log_expr",2) ELSE 0 END) AS "Qy",
        SUM(CASE WHEN m."ParticipantBarcode" IS     NULL THEN POWER(e."avg_log_expr",2) ELSE 0 END) AS "Qn"
    FROM   expr_per_case e
           LEFT JOIN tp53_mutated m
                  ON m."ParticipantBarcode" = e."ParticipantBarcode"
)

/* 5. Compute means, variances, and Welch’s T-score ----------------*/
SELECT
    "Ny",
    "Nn",
    /* means */
    "Sy" / "Ny"                                             AS "avg_y",
    "Sn" / "Nn"                                             AS "avg_n",

    /* Welch’s T-score */
    ("Sy"/"Ny" - "Sn"/"Nn")
    /
    SQRT(
          ( ( "Qy" - "Sy"* "Sy"/"Ny" ) / NULLIF("Ny" - 1, 0) ) / "Ny"
        + ( ( "Qn" - "Sn"* "Sn"/"Nn" ) / NULLIF("Nn" - 1, 0) ) / "Nn"
    )                                                       AS "T_score"
FROM aggregates;
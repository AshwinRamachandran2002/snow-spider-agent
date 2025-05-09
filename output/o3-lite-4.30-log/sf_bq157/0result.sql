WITH mc3_samples AS (   -- LGG tumor samples found in the mutation table
    SELECT DISTINCT
           "ParticipantBarcode",
           "Tumor_SampleBarcode"
    FROM "PANCANCER_ATLAS_1"."PANCANCER_ATLAS_FILTERED"."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE "Study" = 'LGG'
),
expr_per_sample AS (    -- log10 DRG2 expression for those samples
    SELECT
        ms."ParticipantBarcode",
        LOG(e."normalized_count" + 1, 10) AS "log_expr"
    FROM mc3_samples ms
    JOIN "PANCANCER_ATLAS_1"."PANCANCER_ATLAS_FILTERED"."EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED" e
      ON e."SampleBarcode" = ms."Tumor_SampleBarcode"
    WHERE e."Study"  = 'LGG'
      AND e."Symbol" = 'DRG2'
),
expr_per_patient AS (   -- average expression per patient
    SELECT
        "ParticipantBarcode",
        AVG("log_expr") AS "avg_log_expr"
    FROM expr_per_sample
    GROUP BY "ParticipantBarcode"
),
tp53_patients AS (      -- patients with PASS TP53 mutation
    SELECT DISTINCT
           "ParticipantBarcode"
    FROM "PANCANCER_ATLAS_1"."PANCANCER_ATLAS_FILTERED"."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE "Study"       = 'LGG'
      AND "Hugo_Symbol" = 'TP53'
      AND "FILTER"      = 'PASS'
),
joined AS (             -- label patients YES / NO for TP53 mutation
    SELECT
        e."avg_log_expr",
        CASE WHEN t."ParticipantBarcode" IS NOT NULL THEN 'YES' ELSE 'NO' END AS "TP53_mut"
    FROM expr_per_patient e
    LEFT JOIN tp53_patients t
           ON e."ParticipantBarcode" = t."ParticipantBarcode"
),
stats AS (              -- aggregate sums for Welch’s T‑test
    SELECT
        "TP53_mut",
        COUNT(*)                      AS "N",
        SUM("avg_log_expr")           AS "S",
        SUM(POWER("avg_log_expr",2))  AS "Q"
    FROM joined
    GROUP BY "TP53_mut"
),
calc AS (               -- split YES and NO aggregates
    SELECT
        MAX(CASE WHEN "TP53_mut" = 'YES' THEN "N" END) AS "Ny",
        MAX(CASE WHEN "TP53_mut" = 'YES' THEN "S" END) AS "Sy",
        MAX(CASE WHEN "TP53_mut" = 'YES' THEN "Q" END) AS "Qy",
        MAX(CASE WHEN "TP53_mut" = 'NO'  THEN "N" END) AS "Nn",
        MAX(CASE WHEN "TP53_mut" = 'NO'  THEN "S" END) AS "Sn",
        MAX(CASE WHEN "TP53_mut" = 'NO'  THEN "Q" END) AS "Qn"
    FROM stats
)
SELECT
    ROUND(
        ( ("Sy"/"Ny") - ("Sn"/"Nn") ) /
        SQRT(
              ( ( "Qy" - POWER("Sy",2)/"Ny") / ("Ny" - 1) ) / "Ny"
            + ( ( "Qn" - POWER("Sn",2)/"Nn") / ("Nn" - 1) ) / "Nn"
        ),
        4
    ) AS "t_score"
FROM calc;
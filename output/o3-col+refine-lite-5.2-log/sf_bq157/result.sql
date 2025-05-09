/* Welch T‑score for log10‑transformed DRG2 expression
   comparing LGG patients WITH vs WITHOUT PASS‑filtered TP53 mutation */
WITH mc3_lgg AS (   -- LGG tumour samples present in MC3 table
    SELECT DISTINCT
           "ParticipantBarcode",
           "Tumor_SampleBarcode"              AS "Tumor_SampleBarcode"
    FROM   PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE  "Study" = 'LGG'
),

tp53_mut AS (       -- LGG patients carrying a PASS TP53 mutation
    SELECT DISTINCT
           "ParticipantBarcode"
    FROM   PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE  "Study"        = 'LGG'
      AND  "Hugo_Symbol"  = 'TP53'
      AND  "FILTER"       = 'PASS'
),

expr_raw AS (       -- log10(normalized_count + 1) for DRG2,
                    -- restricted to samples that are in the MC3 table
    SELECT
        e."ParticipantBarcode",
        LOG(e."normalized_count" + 1, 10) AS "log_expr"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED" e
    JOIN mc3_lgg s
      ON e."SampleBarcode" = s."Tumor_SampleBarcode"
    WHERE e."Study"  = 'LGG'
      AND e."Symbol" = 'DRG2'
),

expr_avg AS (       -- average log‑expression per patient
    SELECT
        "ParticipantBarcode",
        AVG("log_expr") AS "avg_log_expr"
    FROM expr_raw
    GROUP BY "ParticipantBarcode"
),

cohorts AS (        -- tag patients as TP53‑mutant (YES) or not (NO)
    SELECT
        a."ParticipantBarcode",
        CASE WHEN m."ParticipantBarcode" IS NOT NULL THEN 'YES' ELSE 'NO' END AS "TP53_mut",
        a."avg_log_expr"
    FROM expr_avg a
    LEFT JOIN tp53_mut m
           ON a."ParticipantBarcode" = m."ParticipantBarcode"
),

stats AS (          -- cohort counts, sums and squared‑sums
    SELECT
        "TP53_mut",
        COUNT(*)                       AS "N",
        SUM("avg_log_expr")            AS "S",
        SUM(POWER("avg_log_expr", 2))  AS "Q"
    FROM cohorts
    GROUP BY "TP53_mut"
),

pivot AS (          -- put the two cohorts on one row
    SELECT
        MAX(CASE WHEN "TP53_mut"='YES' THEN "N" END) AS "Ny",
        MAX(CASE WHEN "TP53_mut"='NO'  THEN "N" END) AS "Nn",
        MAX(CASE WHEN "TP53_mut"='YES' THEN "S" END) AS "Sy",
        MAX(CASE WHEN "TP53_mut"='NO'  THEN "S" END) AS "Sn",
        MAX(CASE WHEN "TP53_mut"='YES' THEN "Q" END) AS "Qy",
        MAX(CASE WHEN "TP53_mut"='NO'  THEN "Q" END) AS "Qn"
    FROM stats
)

SELECT
    /* Welch’s T‑score */
    ( ("Sy" / "Ny") - ("Sn" / "Nn") )  /
    SQRT(
        ( ("Qy" - POWER("Sy", 2) / "Ny") / ( ("Ny" - 1) * "Ny") ) +
        ( ("Qn" - POWER("Sn", 2) / "Nn") / ( ("Nn" - 1) * "Nn") )
    ) AS "Welch_T_score"
FROM pivot;
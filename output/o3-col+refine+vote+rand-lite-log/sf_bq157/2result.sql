/* Welch’s t-test for DRG2 expression vs. TP53-mutation status in LGG */

WITH mc3_lgg AS (          -- all LGG tumour samples present in MC3
    SELECT DISTINCT
           "ParticipantBarcode",
           "Tumor_SampleBarcode"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE
    WHERE "Study" = 'LGG'
),
expr AS (                  -- per-patient mean log10-transformed DRG2 expression
    SELECT
        e."ParticipantBarcode",
        AVG(LOG(10, e."normalized_count" + 1)) AS "avg_log_expr"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED e
    JOIN mc3_lgg m
      ON e."SampleBarcode" = m."Tumor_SampleBarcode"
    WHERE e."Study" = 'LGG'
      AND e."Symbol" = 'DRG2'
    GROUP BY e."ParticipantBarcode"
),
tp53_mut AS (              -- LGG patients with a PASS TP53 mutation
    SELECT DISTINCT "ParticipantBarcode"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE
    WHERE "Study" = 'LGG'
      AND "Hugo_Symbol" = 'TP53'
      AND "FILTER"       = 'PASS'
),
stats AS (                 -- accumulate sums, squared-sums, and counts
    SELECT
        SUM(CASE WHEN t."ParticipantBarcode" IS NOT NULL THEN e."avg_log_expr"        END) AS "S_y",
        SUM(CASE WHEN t."ParticipantBarcode" IS NOT NULL THEN POWER(e."avg_log_expr",2)END) AS "Q_y",
        COUNT(CASE WHEN t."ParticipantBarcode" IS NOT NULL THEN 1                     END) AS "N_y",
        SUM(CASE WHEN t."ParticipantBarcode" IS NULL      THEN e."avg_log_expr"        END) AS "S_n",
        SUM(CASE WHEN t."ParticipantBarcode" IS NULL      THEN POWER(e."avg_log_expr",2)END) AS "Q_n",
        COUNT(CASE WHEN t."ParticipantBarcode" IS NULL      THEN 1                     END) AS "N_n"
    FROM expr e
    LEFT JOIN tp53_mut t
           ON e."ParticipantBarcode" = t."ParticipantBarcode"
)
SELECT
    "N_y"                                                         AS "Ny_with_TP53",
    "N_n"                                                         AS "Nn_without_TP53",
    "S_y"/NULLIF("N_y",0)                                         AS "avg_y",
    "S_n"/NULLIF("N_n",0)                                         AS "avg_n",
    ("Q_y" - POWER("S_y",2)/NULLIF("N_y",0)) / NULLIF("N_y"-1,0)  AS "var_y",
    ("Q_n" - POWER("S_n",2)/NULLIF("N_n",0)) / NULLIF("N_n"-1,0)  AS "var_n",
    ( ("S_y"/NULLIF("N_y",0)) - ("S_n"/NULLIF("N_n",0)) ) /
    SQRT(
        ( ("Q_y" - POWER("S_y",2)/NULLIF("N_y",0)) / NULLIF("N_y"-1,0) ) / NULLIF("N_y",0) +
        ( ("Q_n" - POWER("S_n",2)/NULLIF("N_n",0)) / NULLIF("N_n"-1,0) ) / NULLIF("N_n",0)
    )                                                             AS "T_score"
FROM stats;
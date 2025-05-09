WITH expr_raw AS (   -- IGF2 expression for LGG samples
    SELECT
        "ParticipantBarcode"                               AS "PATIENT",
        LOG(10, "normalized_count" + 1)                    AS "LOG_EXPR"   -- base‑10 logarithm
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED"
    WHERE "Study" = 'LGG'
      AND "Symbol" = 'IGF2'
      AND "normalized_count" IS NOT NULL
), patient_expr AS (      -- average IGF2 expression per patient
    SELECT
        "PATIENT",
        AVG("LOG_EXPR")                                   AS "EXPR_AVG"
    FROM expr_raw
    GROUP BY "PATIENT"
), clinical AS (          -- ICD‑O‑3 histology codes (cleaned)
    SELECT
        "bcr_patient_barcode"                             AS "PATIENT",
        "icd_o_3_histology"                               AS "ICD"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED"
    WHERE "icd_o_3_histology" IS NOT NULL
      AND NOT REGEXP_LIKE("icd_o_3_histology", '^\\[.*\\]$')
), data AS (              -- patients with both expression and ICD
    SELECT
        p."PATIENT",
        p."EXPR_AVG",
        c."ICD"
    FROM patient_expr p
    JOIN clinical     c  ON c."PATIENT" = p."PATIENT"
), ranked AS (            -- assign ranks (average ranks for ties)
    SELECT
        "PATIENT",
        "ICD",
        "EXPR_AVG",
        RANK()          OVER (ORDER BY "EXPR_AVG")                         AS "RANK_POS",
        COUNT(*)        OVER ()                                            AS "N_TOTAL"
    FROM data
), avg_rank AS (          -- compute average rank for tied values
    SELECT
        "PATIENT",
        "ICD",
        AVG("RANK_POS") OVER (PARTITION BY "EXPR_AVG")                     AS "RANK"
    FROM ranked
), group_stats AS (       -- Si , Qi , ni  per histology (keep groups >1)
    SELECT
        "ICD",
        COUNT(*)                            AS "n_i",
        SUM("RANK")                         AS "S_i",
        SUM("RANK" * "RANK")                AS "Q_i"
    FROM avg_rank
    GROUP BY "ICD"
    HAVING COUNT(*) > 1
), agg AS (               -- aggregates for Kruskal‑Wallis
    SELECT
        SUM("n_i")                                           AS "N",
        COUNT(*)                                             AS "G",
        SUM("S_i" * "S_i" / "n_i")                           AS "SUM_SSQ_OVER_N",
        SUM("S_i")                                           AS "SUM_S",
        SUM("Q_i")                                           AS "SUM_Q"
    FROM group_stats
)
SELECT
    "G"  AS "NUM_GROUPS",
    "N"  AS "NUM_SAMPLES",
    /* Kruskal–Wallis H statistic */
    ( ("N" - 1)
      * ( "SUM_SSQ_OVER_N" - ("SUM_S" * "SUM_S") / "N" )
      / NULLIF( ("SUM_Q" - ("SUM_S" * "SUM_S") / "N"), 0)
    )    AS "KRUSKAL_WALLIS_H_SCORE"
FROM agg
ORDER BY "KRUSKAL_WALLIS_H_SCORE" DESC NULLS LAST;
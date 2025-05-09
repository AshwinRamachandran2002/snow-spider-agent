WITH per_patient AS (   -- average log10(IGF2) expression per participant
    SELECT
        g."ParticipantBarcode",
        c."icd_o_3_histology",
        AVG(LOG(g."normalized_count" + 1, 10)) AS "avg_log10_expr"
    FROM "PANCANCER_ATLAS_1"."PANCANCER_ATLAS_FILTERED"."EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED" g
    JOIN "PANCANCER_ATLAS_1"."PANCANCER_ATLAS_FILTERED"."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED" c
          ON g."ParticipantBarcode" = c."bcr_patient_barcode"
    WHERE g."Study"             = 'LGG'
      AND g."Symbol"            = 'IGF2'
      AND g."normalized_count"  IS NOT NULL
      AND c."acronym"           = 'LGG'
      AND c."icd_o_3_histology" IS NOT NULL
      AND NOT REGEXP_LIKE(c."icd_o_3_histology", '^\\[.*\\]$')
    GROUP BY g."ParticipantBarcode", c."icd_o_3_histology"
),
ranked_raw AS (   -- raw ranks
    SELECT
        p.*,
        RANK() OVER (ORDER BY p."avg_log10_expr") AS "raw_rank"
    FROM per_patient p
),
ranked AS (       -- average‑rank for ties
    SELECT
        rr."ParticipantBarcode",
        rr."icd_o_3_histology",
        AVG(rr."raw_rank") OVER (PARTITION BY rr."avg_log10_expr") AS "rank_final"
    FROM ranked_raw rr
),
grp AS (          -- group aggregates (keep groups with >1 participant)
    SELECT
        "icd_o_3_histology",
        COUNT(*)                    AS "n_i",
        SUM("rank_final")           AS "S_i",
        SUM(POWER("rank_final",2))  AS "Q_i"
    FROM ranked
    GROUP BY "icd_o_3_histology"
    HAVING COUNT(*) > 1
),
tot AS (          -- overall totals
    SELECT
        SUM("n_i")  AS "N",
        SUM("S_i")  AS "sum_S",
        SUM("Q_i")  AS "sum_Q"
    FROM grp
)
SELECT
    (SELECT COUNT(*) FROM grp)              AS "total_groups",
    tot."N"                                 AS "total_samples",
    /* Kruskal‑Wallis H statistic */
    ( (tot."N" - 1) *
      ( (SELECT SUM("S_i" * "S_i" / "n_i") FROM grp) - POWER(tot."sum_S",2) / tot."N" )
      /
      ( tot."sum_Q" - POWER(tot."sum_S",2) / tot."N" )
    )                                       AS "kruskal_wallis_h_score"
FROM tot
ORDER BY "kruskal_wallis_h_score" DESC;
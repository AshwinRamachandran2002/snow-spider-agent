/* Kruskal–Wallis H statistic for IGF2 (log10(normalized_count+1))
   across ICD-O-3 histology groups                                           */

WITH expr AS (                 -- 1. participants, log-transformed counts
  SELECT
      c."bcr_patient_barcode"                   AS "barcode",
      c."icd_o_3_histology"                     AS "histology",
      LOG(10, e."normalized_count" + 1)         AS "log_expr"   -- use LOG(base, x)
  FROM  PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED e
  JOIN  PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED           c
        ON e."ParticipantBarcode" = c."bcr_patient_barcode"
  WHERE e."Symbol" = 'IGF2'
    AND e."normalized_count" IS NOT NULL
    AND NOT REGEXP_LIKE(c."icd_o_3_histology", '^\[.*\]$')        -- exclude placeholders
),

ranked AS (                    -- 2. average (mid-rank) for each patient
  SELECT
      "histology",
      ( RANK()  OVER (ORDER BY "log_expr")
      + DENSE_RANK() OVER (ORDER BY "log_expr") - 1 ) / 2.0       AS "avg_rank"
  FROM expr
),

grp AS (                       -- 3. per-histology summaries (≥2 samples)
  SELECT
      "histology",
      COUNT(*)                       AS "n_i",
      SUM("avg_rank")                AS "S_i",
      SUM(POWER("avg_rank", 2))      AS "Q_i"
  FROM ranked
  GROUP BY "histology"
  HAVING COUNT(*) > 1
),

agg AS (                       -- 4. totals for Kruskal-Wallis
  SELECT
      SUM("n_i")                                   AS "N",
      SUM("S_i")                                   AS "Sum_S",
      SUM("Q_i")                                   AS "Sum_Q",
      SUM( ("S_i" * "S_i") / "n_i" )               AS "Sum_S_sq_over_n"
  FROM grp
),

kw AS (                        -- 5. H statistic
  SELECT
      ( ("N" - 1)
        * ( "Sum_S_sq_over_n" - POWER("Sum_S", 2) / "N" )
      )  / ( "Sum_Q" - POWER("Sum_S", 2) / "N" )   AS "H_score",
      "N"                                          AS "total_samples",
      ( SELECT COUNT(*) FROM grp )                 AS "num_groups"
  FROM agg
)

SELECT
    "num_groups",
    "total_samples",
    "H_score"
FROM kw
ORDER BY "H_score" DESC NULLS LAST;
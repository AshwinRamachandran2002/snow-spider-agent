WITH gene_expr AS (
  SELECT "ParticipantBarcode", AVG(LOG("normalized_count" + 1, 10)) AS "log_expression"
  FROM "PANCANCER_ATLAS_1"."PANCANCER_ATLAS_FILTERED"."EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED"
  WHERE "Symbol" = 'IGF2' AND "Study" = 'LGG' AND "normalized_count" IS NOT NULL
  GROUP BY "ParticipantBarcode"
),
clinical_data AS (
  SELECT "bcr_patient_barcode", "icd_o_3_histology"
  FROM "PANCANCER_ATLAS_1"."PANCANCER_ATLAS_FILTERED"."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED"
  WHERE "icd_o_3_histology" IS NOT NULL AND NOT REGEXP_LIKE("icd_o_3_histology", '^\\[.*\\]$')
),
expr_with_histology AS (
  SELECT e."ParticipantBarcode", e."log_expression", c."icd_o_3_histology"
  FROM gene_expr e
  JOIN clinical_data c ON e."ParticipantBarcode" = c."bcr_patient_barcode"
),
groups_with_counts AS (
  SELECT "icd_o_3_histology", COUNT(*) AS n_i,
         DENSE_RANK() OVER (ORDER BY COUNT(*) DESC) AS rank_n_i
  FROM expr_with_histology
  GROUP BY "icd_o_3_histology"
  HAVING COUNT(*) >1
),
top_groups AS (
  SELECT "icd_o_3_histology" FROM groups_with_counts
  WHERE rank_n_i <= 3
),
filtered_data AS (
  SELECT ewh.*
  FROM expr_with_histology ewh
  JOIN top_groups tg ON ewh."icd_o_3_histology" = tg."icd_o_3_histology"
),
ordered_data AS (
  SELECT
    fd.*,
    ROW_NUMBER() OVER (ORDER BY "log_expression") AS "rn"
  FROM filtered_data fd
),
avg_ranked_data AS (
  SELECT
    "ParticipantBarcode",
    "icd_o_3_histology",
    "log_expression",
    AVG("rn") OVER (PARTITION BY "log_expression") AS "avg_rank"
  FROM ordered_data
),
total_stats AS (
  SELECT
    COUNT(*) AS "N",
    SUM("avg_rank") AS "sum_ranks_total",
    SUM("avg_rank" * "avg_rank") AS "sum_rank_sq_total"
  FROM avg_ranked_data
),
group_stats AS (
  SELECT
    "icd_o_3_histology",
    COUNT(*) AS "n_i",
    SUM("avg_rank") AS "S_i",
    SUM("avg_rank" * "avg_rank") AS "Q_i"
  FROM avg_ranked_data
  GROUP BY "icd_o_3_histology"
)
SELECT
  (SELECT COUNT(*) FROM group_stats) AS "Total_Groups",
  total_stats."N" AS "Total_Samples",
  ROUND((
    (total_stats."N" - 1) * (
      (SELECT SUM( ("S_i" * "S_i") / "n_i" ) FROM group_stats)
      - ( total_stats."sum_ranks_total" * total_stats."sum_ranks_total" / total_stats."N" )
    )
  ) / (
    total_stats."sum_rank_sq_total" - ( total_stats."sum_ranks_total" * total_stats."sum_ranks_total" / total_stats."N" )
  ), 4) AS "Kruskal_Wallis_H_score"
FROM total_stats;
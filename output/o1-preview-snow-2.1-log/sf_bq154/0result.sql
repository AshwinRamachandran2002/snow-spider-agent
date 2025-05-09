WITH per_patient_expression AS (
  SELECT
    expr."ParticipantBarcode",
    AVG(LOG(10, expr."normalized_count")) AS "avg_log_expression"
  FROM
    PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED" AS expr
  WHERE
    expr."Symbol" = 'IGF2'
    AND expr."Study" = 'LGG'
  GROUP BY
    expr."ParticipantBarcode"
),
clinical_data AS (
  SELECT
    "bcr_patient_barcode",
    "icd_o_3_histology"
  FROM
    PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED"
  WHERE
    "icd_o_3_histology" IS NOT NULL
),
joined_data AS (
  SELECT
    ppe."ParticipantBarcode",
    ppe."avg_log_expression",
    cd."icd_o_3_histology"
  FROM
    per_patient_expression ppe
  JOIN
    clinical_data cd ON ppe."ParticipantBarcode" = cd."bcr_patient_barcode"
),
value_counts AS (
  SELECT
    jd."avg_log_expression",
    COUNT(*) AS "count"
  FROM joined_data jd
  GROUP BY jd."avg_log_expression"
),
value_ranks AS (
  SELECT
    vc."avg_log_expression",
    vc."count",
    SUM(vc."count") OVER (ORDER BY vc."avg_log_expression" ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) + 1 AS "start_rank",
    SUM(vc."count") OVER (ORDER BY vc."avg_log_expression") AS "end_rank"
  FROM value_counts vc
),
value_avg_ranks AS (
  SELECT
    vr."avg_log_expression",
    (vr."start_rank" + vr."end_rank") / 2.0 AS "avg_rank"
  FROM value_ranks vr
),
data_with_ranks AS (
  SELECT
    jd."ParticipantBarcode",
    jd."avg_log_expression",
    jd."icd_o_3_histology",
    var."avg_rank"
  FROM joined_data jd
  JOIN value_avg_ranks var
    ON jd."avg_log_expression" = var."avg_log_expression"
),
group_stats AS (
  SELECT
    "icd_o_3_histology",
    COUNT(*) AS n_i,
    SUM("avg_rank") AS S_i,
    SUM(POWER("avg_rank", 2)) AS Q_i
  FROM data_with_ranks
  GROUP BY "icd_o_3_histology"
),
aggregates AS (
  SELECT
    SUM(n_i) AS N,
    SUM(S_i) AS Sum_S_i,
    SUM(Q_i) AS Sum_Q_i,
    SUM(POWER(S_i, 2) / n_i) AS Sum_S_i2_over_n_i
  FROM group_stats
)
SELECT
  ROUND(
    (aggregates.N - 1) *
    (aggregates.Sum_S_i2_over_n_i - POWER(aggregates.Sum_S_i, 2) / aggregates.N) /
    (aggregates.Sum_Q_i - POWER(aggregates.Sum_S_i, 2) / aggregates.N),
    4
  ) AS "H-score"
FROM aggregates;
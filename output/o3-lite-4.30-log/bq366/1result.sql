WITH big_labels AS (
  SELECT
    la.description AS label
  FROM `bigquery-public-data.the_met.vision_api_data` v
  CROSS JOIN UNNEST(v.labelAnnotations) la
  GROUP BY label
  HAVING COUNT(DISTINCT v.object_id) >= 500
),
period_label_counts AS (
  SELECT
    o.period,
    la.description AS label,
    COUNT(DISTINCT o.object_id) AS cnt
  FROM `bigquery-public-data.the_met.objects`        o
  JOIN `bigquery-public-data.the_met.vision_api_data` v
    ON o.object_id = v.object_id
  CROSS JOIN UNNEST(v.labelAnnotations) la
  JOIN big_labels bl
    ON la.description = bl.label
  WHERE o.period IS NOT NULL
  GROUP BY o.period, label
),
ranked AS (
  SELECT
    period,
    label,
    cnt,
    ROW_NUMBER() OVER (PARTITION BY period ORDER BY cnt DESC, label) AS rn
  FROM period_label_counts
)
SELECT
  period,
  label,
  cnt AS label_count
FROM ranked
WHERE rn <= 3
ORDER BY period, label_count DESC, label;
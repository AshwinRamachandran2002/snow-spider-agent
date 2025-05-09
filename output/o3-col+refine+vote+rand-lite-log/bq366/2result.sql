-- Top-3 most frequent “big” labels (≥500 artworks overall) for every historical period
WITH big_labels AS (
  SELECT label.description AS label_desc
  FROM `bigquery-public-data.the_met.vision_api_data`,
       UNNEST(labelAnnotations) AS label
  GROUP BY label_desc
  HAVING COUNT(DISTINCT object_id) >= 500
),
period_label_counts AS (
  SELECT
    o.period,
    label.description AS label,
    COUNT(DISTINCT o.object_id) AS cnt
  FROM `bigquery-public-data.the_met.objects`         AS o
  JOIN `bigquery-public-data.the_met.vision_api_data` AS v
    ON o.object_id = v.object_id
  CROSS JOIN UNNEST(v.labelAnnotations) AS label
  WHERE o.period IS NOT NULL
    AND label.description IN (SELECT label_desc FROM big_labels)
  GROUP BY o.period, label
),
ranked AS (
  SELECT
    plc.*,
    ROW_NUMBER() OVER (PARTITION BY plc.period ORDER BY plc.cnt DESC) AS rn
  FROM period_label_counts plc
)
SELECT
  period,
  label,
  cnt AS associated_count
FROM ranked
WHERE rn <= 3
ORDER BY period, associated_count DESC;
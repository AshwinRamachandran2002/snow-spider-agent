WITH big_labels AS (
  -- labels that appear on at least 500 distinct artworks
  SELECT l.description AS label
  FROM `bigquery-public-data.the_met.vision_api_data` v
  CROSS JOIN UNNEST(v.labelAnnotations) AS l
  GROUP BY label
  HAVING COUNT(DISTINCT v.object_id) >= 500
),
period_label_counts AS (
  -- count how many artworks in each period carry the big labels
  SELECT
    o.period,
    l.description AS label,
    COUNT(DISTINCT o.object_id) AS label_count
  FROM `bigquery-public-data.the_met.objects` o
  JOIN `bigquery-public-data.the_met.vision_api_data` v USING (object_id)
  CROSS JOIN UNNEST(v.labelAnnotations) AS l
  JOIN big_labels b ON l.description = b.label
  WHERE o.period IS NOT NULL
  GROUP BY o.period, label
),
ranked AS (
  -- rank labels within each period by frequency
  SELECT
    period,
    label,
    label_count,
    ROW_NUMBER() OVER (PARTITION BY period ORDER BY label_count DESC) AS rnk
  FROM period_label_counts
)
-- top three labels per period
SELECT
  period,
  label,
  label_count
FROM ranked
WHERE rnk <= 3
ORDER BY period, label_count DESC;
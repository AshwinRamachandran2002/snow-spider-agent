-- top 3 most frequent Vision‑API labels per historical period,
-- considering only labels that appear on 500 + distinct artworks
WITH all_labels AS (
  SELECT
    v.object_id,
    l.description AS label
  FROM `bigquery-public-data.the_met.vision_api_data` v
  CROSS JOIN UNNEST(v.labelAnnotations) AS l
),
labels_500_plus AS (
  SELECT label
  FROM all_labels
  GROUP BY label
  HAVING COUNT(DISTINCT object_id) >= 500
),
period_label_counts AS (
  SELECT
    o.period,
    l.label,
    COUNT(DISTINCT l.object_id) AS artworks_with_label
  FROM all_labels AS l
  JOIN labels_500_plus  USING (label)
  JOIN `bigquery-public-data.the_met.objects` o
    ON o.object_id = l.object_id
  WHERE o.period IS NOT NULL
  GROUP BY o.period, l.label
),
ranked AS (
  SELECT
    period,
    label,
    artworks_with_label,
    ROW_NUMBER() OVER (PARTITION BY period
                       ORDER BY artworks_with_label DESC, label) AS rn
  FROM period_label_counts
)
SELECT
  period,
  label,
  artworks_with_label AS count
FROM ranked
WHERE rn <= 3
ORDER BY period, rn;
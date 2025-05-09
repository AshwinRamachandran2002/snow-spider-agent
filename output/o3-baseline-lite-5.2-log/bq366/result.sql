-- Top 3 most frequent Vision‑API labels per historical period,
-- restricted to labels that appear on at least 500 different artworks
WITH all_labels AS (
  -- explode the Vision API label annotations
  SELECT
    v.object_id,
    l.description AS label
  FROM `bigquery-public-data.the_met.vision_api_data` AS v
  CROSS JOIN UNNEST(v.labelAnnotations) AS l
),
-- labels that are common enough (≥500 artworks in the whole collection)
popular_labels AS (
  SELECT
    label,
    COUNT(DISTINCT object_id) AS total_artworks
  FROM all_labels
  GROUP BY label
  HAVING total_artworks >= 500
),
-- label counts within each historical period
period_label_counts AS (
  SELECT
    o.period,
    al.label,
    COUNT(*) AS label_count          -- each row = one (object, label) pair
  FROM all_labels AS al
  JOIN `bigquery-public-data.the_met.objects` AS o
    ON o.object_id = al.object_id
  JOIN popular_labels AS pl
    ON pl.label = al.label           -- keep only labels meeting 500‑artwork threshold
  WHERE o.period IS NOT NULL
        AND o.period != ''
  GROUP BY o.period, al.label
),
-- rank labels inside each period
ranked AS (
  SELECT
    period,
    label,
    label_count,
    ROW_NUMBER() OVER (
      PARTITION BY period
      ORDER BY label_count DESC, label ASC
    ) AS rn
  FROM period_label_counts
)
-- final top‑3 list
SELECT
  period,
  label,
  label_count
FROM ranked
WHERE rn <= 3
ORDER BY period, rn;
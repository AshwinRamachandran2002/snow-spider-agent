/* Top‑3 most frequent Vision API labels per historical period,
   considering only labels that occur with at least 500 different artworks */
WITH label_threshold AS (
  -- Labels linked to ≥ 500 distinct artworks in the whole collection
  SELECT
    l.description AS label,
    COUNT(DISTINCT v.object_id) AS artwork_cnt
  FROM `bigquery-public-data.the_met.vision_api_data` AS v
  CROSS JOIN UNNEST(v.labelAnnotations) AS l
  GROUP BY label
  HAVING artwork_cnt >= 500
),
period_label_counts AS (
  -- For every (period , label) pair, count how many artworks have that label
  SELECT
    o.period,
    l.description AS label,
    COUNT(DISTINCT o.object_id) AS label_count
  FROM `bigquery-public-data.the_met.objects`         AS o
  JOIN `bigquery-public-data.the_met.vision_api_data` AS v
    ON o.object_id = v.object_id
  CROSS JOIN UNNEST(v.labelAnnotations) AS l
  WHERE l.description IN (SELECT label FROM label_threshold)   -- keep only frequent labels
    AND o.period IS NOT NULL
    AND o.period <> ''
  GROUP BY o.period, l.description
),
ranked AS (
  -- Rank labels within each period by descending count
  SELECT
    period,
    label,
    label_count,
    ROW_NUMBER() OVER (PARTITION BY period
                       ORDER BY label_count DESC, label) AS rn
  FROM period_label_counts
)
SELECT
  period,
  label,
  label_count
FROM ranked
WHERE rn <= 3                     -- top‑3 labels per period
ORDER BY period, label_count DESC, label;
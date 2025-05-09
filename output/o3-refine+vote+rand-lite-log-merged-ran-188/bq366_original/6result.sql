WITH label_per_object AS (
  /* one row per (object, label) */
  SELECT DISTINCT
    LOWER(l.description) AS label,
    v.object_id
  FROM `bigquery-public-data.the_met.vision_api_data` AS v
  CROSS JOIN UNNEST(v.labelAnnotations) AS l
  WHERE l.description IS NOT NULL
),
/* keep only labels that appear on at least 500 different artworks */
popular_labels AS (
  SELECT label
  FROM label_per_object
  GROUP BY label
  HAVING COUNT(DISTINCT object_id) >= 500
),
/* count, for every period‑label pair, how many artworks carry that label */
period_label_counts AS (
  SELECT
    o.period,
    l.label,
    COUNT(DISTINCT l.object_id) AS label_count
  FROM label_per_object AS l
  JOIN popular_labels AS p
    ON p.label = l.label
  JOIN `bigquery-public-data.the_met.objects` AS o
    ON o.object_id = l.object_id
  WHERE o.period IS NOT NULL
  GROUP BY o.period, l.label
),
/* rank labels inside each period */
ranked AS (
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
WHERE rn <= 3          -- top three labels per period
ORDER BY period, rn;
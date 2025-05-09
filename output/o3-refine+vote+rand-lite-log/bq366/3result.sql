WITH exploded AS (
  -- Break out every (period, object_id, label) pair
  SELECT
    o.period,
    o.object_id,
    l.description AS label
  FROM `bigquery-public-data.the_met.objects` AS o
  JOIN `bigquery-public-data.the_met.vision_api_data` AS v
    ON o.object_id = v.object_id
  CROSS JOIN UNNEST(v.labelAnnotations) AS l
  WHERE l.description IS NOT NULL
),
frequent_labels AS (
  -- Keep only labels that appear on 500 + distinct artworks
  SELECT
    label,
    COUNT(DISTINCT object_id) AS total_objects
  FROM exploded
  GROUP BY label
  HAVING total_objects >= 500
),
period_label_counts AS (
  -- Count how many artworks in each period have each frequent label
  SELECT
    e.period,
    e.label,
    COUNT(DISTINCT e.object_id) AS cnt
  FROM exploded AS e
  JOIN frequent_labels AS f
    ON e.label = f.label
  GROUP BY e.period, e.label
),
ranked AS (
  -- Rank labels within each period by count
  SELECT
    period,
    label,
    cnt,
    ROW_NUMBER() OVER (PARTITION BY period ORDER BY cnt DESC, label ASC) AS rn
  FROM period_label_counts
)
-- Return the top three labels per period
SELECT
  period,
  label,
  cnt
FROM ranked
WHERE rn <= 3
ORDER BY period, rn;
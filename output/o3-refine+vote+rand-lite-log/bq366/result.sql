WITH labels AS (
  -- Every (object, label) pair from Vision API data
  SELECT
    object_id,
    LOWER(l.description) AS label
  FROM `bigquery-public-data.the_met.vision_api_data`,
  UNNEST(labelAnnotations) AS l
), 

label_totals AS (
  -- Keep only labels that appear on 500+ distinct artworks
  SELECT
    label,
    COUNT(DISTINCT object_id) AS total_objects
  FROM labels
  GROUP BY label
  HAVING total_objects >= 500
), 

period_label_counts AS (
  -- Count how many artworks of each period carry each frequent label
  SELECT
    o.period,
    l.label,
    COUNT(DISTINCT o.object_id) AS cnt
  FROM `bigquery-public-data.the_met.objects` AS o
  JOIN labels                AS l ON o.object_id = l.object_id
  JOIN label_totals          AS t ON l.label     = t.label
  WHERE o.period IS NOT NULL
  GROUP BY o.period, l.label
), 

ranked AS (
  -- Rank labels within each period by frequency
  SELECT
    period,
    label,
    cnt,
    ROW_NUMBER() OVER (PARTITION BY period ORDER BY cnt DESC, label) AS rn
  FROM period_label_counts
)

-- Return the top three labels per period
SELECT
  period,
  label,
  cnt AS label_count
FROM ranked
WHERE rn <= 3
ORDER BY period, rn;
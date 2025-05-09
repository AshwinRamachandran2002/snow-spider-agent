-- Top three most frequent labels (appearing on ≥ 500 artworks overall)
-- for every historical period recorded in The Met objects table.
WITH exploded_labels AS (
  -- Break out every Vision‑API label attached to an artwork
  SELECT
    v.object_id,
    l.description AS label
  FROM `bigquery-public-data.the_met.vision_api_data` AS v
  CROSS JOIN UNNEST(v.labelAnnotations) AS l
),
-- Identify labels that are widespread enough (≥ 500 artworks)
popular_labels AS (
  SELECT
    label,
    COUNT(DISTINCT object_id) AS total_artworks
  FROM exploded_labels
  GROUP BY label
  HAVING total_artworks >= 500
),
-- Count, for each period, how many artworks carry each popular label
period_label_counts AS (
  SELECT
    o.period,
    el.label,
    COUNT(DISTINCT el.object_id) AS label_count
  FROM exploded_labels AS el
  JOIN popular_labels  AS pl ON el.label = pl.label
  JOIN `bigquery-public-data.the_met.objects` AS o
    ON el.object_id = o.object_id
  GROUP BY o.period, el.label
),
-- Rank labels within each period by frequency
ranked_labels AS (
  SELECT
    period,
    label,
    label_count,
    ROW_NUMBER() OVER (PARTITION BY period
                       ORDER BY label_count DESC, label) AS rank_within_period
  FROM period_label_counts
)
-- Return the top three labels per period
SELECT
  period,
  label,
  label_count AS associated_count
FROM ranked_labels
WHERE rank_within_period <= 3
ORDER BY period, rank_within_period;
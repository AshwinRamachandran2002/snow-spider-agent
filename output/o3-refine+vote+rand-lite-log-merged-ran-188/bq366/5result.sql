-- Top-3 most frequent Vision-API labels per historical period
-- (restricted to labels that appear on 500+ distinct artworks)

WITH big_labels AS (
  -- 1) Identify labels linked to at least 500 different artworks
  SELECT
    la.description AS label
  FROM `bigquery-public-data.the_met.vision_api_data` v,
       UNNEST(v.labelAnnotations) AS la
  GROUP BY label
  HAVING COUNT(DISTINCT v.object_id) >= 500
),

period_label_counts AS (
  -- 2) Count, for each period-label pair, how many artworks carry that label
  SELECT
    o.period,
    la.description AS label,
    COUNT(DISTINCT o.object_id) AS cnt
  FROM `bigquery-public-data.the_met.objects`        AS o
  JOIN `bigquery-public-data.the_met.vision_api_data` AS v
        ON o.object_id = v.object_id
  JOIN UNNEST(v.labelAnnotations) AS la
        ON TRUE
  JOIN big_labels bl
        ON la.description = bl.label              -- keep only big labels
  WHERE o.period IS NOT NULL                      -- ignore rows without period
  GROUP BY o.period, la.description
),

ranked AS (
  -- 3) Rank labels within each period by frequency
  SELECT
    period,
    label,
    cnt,
    ROW_NUMBER() OVER (PARTITION BY period ORDER BY cnt DESC) AS rn
  FROM period_label_counts
)

-- 4) Return the top three labels for every historical period
SELECT
  period,
  label,
  cnt
FROM ranked
WHERE rn <= 3
ORDER BY period, cnt DESC;
WITH frequent_labels AS (
  -- 1) Keep only those Vision-API labels that appear on ≥500 distinct artworks
  SELECT
    la.description AS label
  FROM `bigquery-public-data.the_met.vision_api_data` v
  CROSS JOIN UNNEST(v.labelAnnotations) AS la
  GROUP BY label
  HAVING COUNT(DISTINCT v.object_id) >= 500
),
period_label_counts AS (
  -- 2) Count, for every historical period, how many artworks carry each of the frequent labels
  SELECT
    o.period,
    la.description                         AS label,
    COUNT(DISTINCT o.object_id)            AS label_count
  FROM `bigquery-public-data.the_met.objects`        o
  JOIN `bigquery-public-data.the_met.vision_api_data` v
    USING (object_id)
  CROSS JOIN UNNEST(v.labelAnnotations) AS la
  JOIN frequent_labels f
    ON la.description = f.label            -- only frequent labels
  WHERE o.period IS NOT NULL
  GROUP BY o.period, la.description
),
ranked AS (
  -- 3) Rank labels within each period by frequency
  SELECT
    period,
    label,
    label_count,
    ROW_NUMBER() OVER (PARTITION BY period
                       ORDER BY label_count DESC, label) AS rn
  FROM period_label_counts
)
-- 4) Return the top three labels for every historical period
SELECT
  period,
  label,
  label_count
FROM ranked
WHERE rn <= 3
ORDER BY period, label_count DESC, label;
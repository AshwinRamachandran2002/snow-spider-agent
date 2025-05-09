WITH labels_per_object AS (
  -- every (object_id , label) pair coming from Vision-API
  SELECT
    v.object_id,
    la.description AS label
  FROM `bigquery-public-data.the_met.vision_api_data` AS v
  CROSS JOIN UNNEST(v.labelAnnotations) AS la
),
popular_labels AS (
  -- keep only labels that appear on ≥ 500 different artworks
  SELECT
    label
  FROM labels_per_object
  GROUP BY label
  HAVING COUNT(DISTINCT object_id) >= 500
),
period_label_counts AS (
  -- how many artworks of each period carry each popular label
  SELECT
    o.period,
    lpo.label,
    COUNT(DISTINCT o.object_id) AS associated_count
  FROM labels_per_object AS lpo
  JOIN popular_labels        AS pl ON lpo.label = pl.label
  JOIN `bigquery-public-data.the_met.objects` AS o USING (object_id)
  WHERE o.period IS NOT NULL
  GROUP BY o.period, lpo.label
),
ranked AS (
  -- rank labels inside every period by their frequency
  SELECT
    period,
    label,
    associated_count,
    ROW_NUMBER() OVER (PARTITION BY period
                       ORDER BY associated_count DESC, label) AS rn
  FROM period_label_counts
)
SELECT
  period,
  label,
  associated_count
FROM ranked
WHERE rn <= 3          -- top-3 per period
ORDER BY period, associated_count DESC;
-- Top-3 Vision-API labels per historical period,
-- considering only labels that appear on ≥500 artworks overall
WITH popular_labels AS (
  -- 1. Labels that are globally frequent (≥500 artworks)
  SELECT la.description AS label
  FROM `bigquery-public-data.the_met.vision_api_data` AS v,
       UNNEST(v.labelAnnotations) AS la
  GROUP BY label
  HAVING COUNT(DISTINCT v.object_id) >= 500
),
period_label_totals AS (
  -- 2. Count how many artworks from each period carry every popular label
  SELECT
    o.period,
    la.description AS label,
    COUNT(DISTINCT o.object_id) AS artworks_labeled
  FROM `bigquery-public-data.the_met.objects` AS o
  JOIN `bigquery-public-data.the_met.vision_api_data` AS v
    ON o.object_id = v.object_id
  CROSS JOIN UNNEST(v.labelAnnotations) AS la
  JOIN popular_labels pl
    ON la.description = pl.label                -- keep only popular labels
  WHERE o.period IS NOT NULL
  GROUP BY o.period, la.description
),
ranked AS (
  -- 3. Rank labels inside each period by frequency
  SELECT
    period,
    label,
    artworks_labeled,
    ROW_NUMBER() OVER (PARTITION BY period ORDER BY artworks_labeled DESC) AS rn
  FROM period_label_totals
)
-- 4. Return the top-3 labels per period
SELECT
  period,
  label,
  artworks_labeled AS label_count
FROM ranked
WHERE rn <= 3
ORDER BY period, label_count DESC;
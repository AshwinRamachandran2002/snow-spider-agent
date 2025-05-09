WITH label_counts AS (
  SELECT
    o.`period`,
    l.`description`                       AS label,
    COUNT(DISTINCT v.`object_id`)         AS artwork_cnt
  FROM `bigquery-public-data.the_met.vision_api_data` v
  JOIN `bigquery-public-data.the_met.objects` o
    ON v.`object_id` = o.`object_id`
  CROSS JOIN UNNEST(v.`labelAnnotations`) AS l
  WHERE o.`period` IS NOT NULL
  GROUP BY o.`period`, l.`description`
  HAVING COUNT(DISTINCT v.`object_id`) >= 500          -- keep labels linked to ≥500 artworks
),
ranked AS (
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY `period` ORDER BY artwork_cnt DESC) AS rnk
  FROM label_counts
)
SELECT
  `period`,
  label,
  artwork_cnt
FROM ranked
WHERE rnk <= 3                                           -- top 3 labels per period
ORDER BY `period`, artwork_cnt DESC;
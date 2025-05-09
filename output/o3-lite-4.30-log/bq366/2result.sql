WITH period_label_counts AS (
  SELECT
    o.period,
    l.description AS label,
    COUNT(DISTINCT o.object_id) AS artwork_cnt
  FROM `bigquery-public-data.the_met.objects` AS o
  JOIN `bigquery-public-data.the_met.vision_api_data` AS v
  USING (object_id)
  CROSS JOIN UNNEST(v.labelAnnotations) AS l
  WHERE o.period IS NOT NULL
  GROUP BY o.period, l.description
  HAVING COUNT(DISTINCT o.object_id) >= 500
)
SELECT
  period,
  label,
  artwork_cnt
FROM (
  SELECT
    period,
    label,
    artwork_cnt,
    ROW_NUMBER() OVER (PARTITION BY period ORDER BY artwork_cnt DESC) AS rn
  FROM period_label_counts
)
WHERE rn <= 3
ORDER BY period, artwork_cnt DESC;
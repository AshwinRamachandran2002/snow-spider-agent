WITH frequent_labels AS (           -- labels linked to ≥ 500 distinct artworks
  SELECT LOWER(l.description) AS label
  FROM   `bigquery-public-data.the_met.vision_api_data` v
  CROSS  JOIN UNNEST(v.labelAnnotations) AS l
  GROUP  BY label
  HAVING COUNT(DISTINCT v.object_id) >= 500
),
period_label_counts AS (            -- how often each of those labels occurs per period
  SELECT o.period,
         LOWER(l.description)        AS label,
         COUNT(DISTINCT o.object_id) AS artworks
  FROM   `bigquery-public-data.the_met.objects`         o
  JOIN   `bigquery-public-data.the_met.vision_api_data` v
         ON o.object_id = v.object_id
  CROSS  JOIN UNNEST(v.labelAnnotations) AS l
  WHERE  o.period IS NOT NULL
    AND  LOWER(l.description) IN (SELECT label FROM frequent_labels)
  GROUP  BY o.period, label
),
ranked AS (                         -- keep the three most frequent labels for each period
  SELECT *,
         DENSE_RANK() OVER (PARTITION BY period ORDER BY artworks DESC) AS rnk
  FROM   period_label_counts
)
SELECT period,
       label,
       artworks
FROM   ranked
WHERE  rnk <= 3
ORDER  BY period, artworks DESC;
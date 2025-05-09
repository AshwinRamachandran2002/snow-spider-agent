WITH cat_urls AS (
  SELECT DISTINCT i.original_url
  FROM `bigquery-public-data.open_images.labels`  AS l
  JOIN `bigquery-public-data.open_images.images`  AS i
    ON l.image_id = i.image_id
  WHERE l.label_name = '/m/01yrx'           -- cat label
    AND l.confidence = 1                    -- positive confirmation
    AND i.original_url IS NOT NULL
),
all_urls AS (
  SELECT DISTINCT original_url
  FROM `bigquery-public-data.open_images.images`
  WHERE original_url IS NOT NULL
)
SELECT
  CASE WHEN c.original_url IS NOT NULL THEN 'cat' ELSE 'other' END AS category,
  COUNT(*) AS url_count
FROM all_urls a
LEFT JOIN cat_urls c
ON a.original_url = c.original_url
GROUP BY category
ORDER BY category;
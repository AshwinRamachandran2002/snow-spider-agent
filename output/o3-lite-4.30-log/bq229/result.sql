WITH img_cat_flag AS (
  SELECT
    i.original_url,
    MAX(CASE WHEN l.label_name = '/m/01yrx' AND l.confidence = 1 THEN 1 ELSE 0 END) AS has_cat
  FROM `bigquery-public-data.open_images.images` AS i
  LEFT JOIN `bigquery-public-data.open_images.labels` AS l
    ON i.image_id = l.image_id
  GROUP BY i.original_url
)
SELECT
  CASE WHEN has_cat = 1 THEN 'cat' ELSE 'other' END AS category,
  COUNT(*) AS url_count
FROM img_cat_flag
GROUP BY category
ORDER BY category;
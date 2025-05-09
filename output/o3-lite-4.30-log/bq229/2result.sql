WITH cat_images AS (
  SELECT DISTINCT image_id
  FROM `bigquery-public-data.open_images.annotations_bbox`
  WHERE label_name = '/m/01yrx'
    AND confidence = 1
),
cat_urls AS (
  SELECT DISTINCT 'cat' AS category, i.original_url
  FROM `bigquery-public-data.open_images.images` AS i
  JOIN cat_images AS c
  ON i.image_id = c.image_id
),
other_urls AS (
  SELECT DISTINCT 'other' AS category, i.original_url
  FROM `bigquery-public-data.open_images.images` AS i
  WHERE i.image_id NOT IN (SELECT image_id FROM cat_images)
)
SELECT category,
       COUNT(*) AS url_count
FROM (
  SELECT * FROM cat_urls
  UNION ALL
  SELECT * FROM other_urls
)
GROUP BY category;
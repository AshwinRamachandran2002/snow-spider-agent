WITH total_images AS (
  SELECT COUNT(DISTINCT image_id) AS total_count
  FROM `bigquery-public-data.open_images.images`
), cat_images AS (
  SELECT COUNT(DISTINCT image_id) AS cat_count
  FROM `bigquery-public-data.open_images.labels`
  WHERE label_name = '/m/01yrx' AND confidence = 1.0
)
SELECT 'Cat' AS Category, cat_count AS Count
FROM cat_images
UNION ALL
SELECT 'Other' AS Category, total_count - cat_count AS Count
FROM total_images, cat_images;
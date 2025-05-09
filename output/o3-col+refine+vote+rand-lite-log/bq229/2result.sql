WITH cat_images AS (
  -- All images that contain at least one bounding-box annotation
  -- of the “Cat” label (/m/01yrx) with confidence = 1
  SELECT DISTINCT image_id
  FROM `bigquery-public-data.open_images.annotations_bbox`
  WHERE label_name = '/m/01yrx'
    AND confidence = 1.0
)

SELECT
  COUNT(DISTINCT IF(ci.image_id IS NOT NULL, i.original_url, NULL)) AS cat_url_count,
  COUNT(DISTINCT IF(ci.image_id IS NULL,  i.original_url, NULL)) AS other_url_count
FROM `bigquery-public-data.open_images.images` AS i
LEFT JOIN cat_images AS ci
ON i.image_id = ci.image_id;
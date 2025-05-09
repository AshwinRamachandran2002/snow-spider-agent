WITH cat_images AS (
  -- all images that have at least one CAT (/m/01yrx) annotation with confidence = 1
  SELECT DISTINCT image_id
  FROM `bigquery-public-data.open_images.annotations_bbox`
  WHERE label_name = '/m/01yrx'
    AND confidence = 1.0
)

SELECT
  CASE
    WHEN cat.image_id IS NOT NULL THEN 'cat'
    ELSE 'other'
  END AS category,
  COUNT(DISTINCT img.original_url) AS url_count
FROM `bigquery-public-data.open_images.images` AS img
LEFT JOIN cat_images AS cat
  ON img.image_id = cat.image_id
GROUP BY category;
-- Distinct image-URL counts: “cat” vs “other”
WITH cat_images AS (
  SELECT DISTINCT image_id
  FROM `bigquery-public-data.open_images.annotations_bbox`
  WHERE label_name = '/m/01yrx'    -- label code for “Cat”
    AND confidence = 1
),
all_urls AS (
  SELECT DISTINCT image_id, original_url
  FROM `bigquery-public-data.open_images.images`
)
SELECT
  COUNT(DISTINCT IF(ci.image_id IS NOT NULL, au.original_url, NULL)) AS cat_image_url_cnt,
  COUNT(DISTINCT IF(ci.image_id IS NULL,  au.original_url, NULL))    AS other_image_url_cnt
FROM all_urls AS au
LEFT JOIN cat_images AS ci
ON au.image_id = ci.image_id;
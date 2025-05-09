-- Count distinct image URLs that DO have a confirmed Cat bbox (confidence = 1)
-- versus those that have NO Cat bbox at all.
WITH cat_images AS (
  SELECT DISTINCT image_id
  FROM `bigquery-public-data.open_images.annotations_bbox`
  WHERE label_name = '/m/01yrx'   -- internal code for "Cat"
    AND confidence = 1            -- only positively‑confirmed bboxes
)

SELECT 'cat'   AS category,
       COUNT(DISTINCT im.original_url) AS url_count
FROM `bigquery-public-data.open_images.images` AS im
JOIN cat_images AS ci
  ON im.image_id = ci.image_id

UNION ALL

SELECT 'other' AS category,
       COUNT(DISTINCT im.original_url) AS url_count
FROM `bigquery-public-data.open_images.images` AS im
LEFT JOIN cat_images AS ci
  ON im.image_id = ci.image_id
WHERE ci.image_id IS NULL;
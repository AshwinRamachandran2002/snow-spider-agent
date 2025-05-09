/*  Count distinct image URLs that
    1) DO have a positive “cat” label  (/m/01yrx , confidence = 1)
    2) have NO positive “cat” label at all                           */

WITH cat_images AS (
  SELECT DISTINCT image_id
  FROM `bigquery-public-data.open_images.labels`
  WHERE label_name = '/m/01yrx'
    AND confidence = 1
)

-- two-row result: “cat” vs “other”
SELECT
  'cat'   AS category,
  COUNT(DISTINCT i.original_url) AS distinct_url_cnt
FROM   `bigquery-public-data.open_images.images` AS i
JOIN   cat_images AS c
ON     i.image_id = c.image_id

UNION ALL

SELECT
  'other' AS category,
  COUNT(DISTINCT i.original_url) AS distinct_url_cnt
FROM   `bigquery-public-data.open_images.images` AS i
LEFT JOIN cat_images AS c
ON     i.image_id = c.image_id
WHERE  c.image_id IS NULL;
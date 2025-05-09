-- Count distinct image URLs that are positively labeled as “cat” vs. those with no cat label
WITH cat_urls AS (
  SELECT DISTINCT i.original_url
  FROM `bigquery-public-data.open_images.images`  AS i
  JOIN `bigquery-public-data.open_images.labels`  AS l
  ON   i.image_id = l.image_id
  WHERE l.label_name = '/m/01yrx'         -- “cat” label
    AND l.confidence = 1                  -- positive (confidence = 1)
)

SELECT 'cat'   AS category, COUNT(*) AS url_count
FROM   cat_urls

UNION ALL

SELECT 'other' AS category,
       COUNT(DISTINCT i.original_url) AS url_count
FROM   `bigquery-public-data.open_images.images` AS i
LEFT  JOIN cat_urls AS c
ON     i.original_url = c.original_url
WHERE  c.original_url IS NULL;
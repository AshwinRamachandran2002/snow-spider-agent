-- Count distinct image URLs that are labeled as “cat” (label '/m/01yrx' with confidence = 1)
-- and those that have no such cat label at all.
WITH url_flags AS (
  SELECT
    i.original_url,
    -- 1 if the image is positively labeled as a cat, 0 otherwise
    MAX(CASE WHEN l.label_name = '/m/01yrx' AND l.confidence = 1 THEN 1 ELSE 0 END) AS is_cat
  FROM `bigquery-public-data.open_images.images` AS i
  LEFT JOIN `bigquery-public-data.open_images.labels` AS l
    ON i.image_id = l.image_id
  GROUP BY i.original_url
)
SELECT
  SUM(CASE WHEN is_cat = 1 THEN 1 ELSE 0 END) AS cat_url_count,
  SUM(CASE WHEN is_cat = 0 THEN 1 ELSE 0 END) AS other_url_count
FROM url_flags;
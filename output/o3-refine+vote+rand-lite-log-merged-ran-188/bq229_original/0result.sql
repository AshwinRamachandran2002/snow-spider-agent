-- Count distinct image URLs that belong to “cat” and “other” categories
WITH cat_images AS (
  -- image_ids that are positively labeled as cat
  SELECT DISTINCT image_id
  FROM `bigquery-public-data.open_images.labels`
  WHERE label_name = '/m/01yrx'      -- “cat” label
    AND confidence = 1
),
cat_urls AS (
  -- corresponding distinct URLs for those cat images
  SELECT DISTINCT original_url
  FROM `bigquery-public-data.open_images.images` AS img
  JOIN cat_images AS c
    ON img.image_id = c.image_id
  WHERE original_url IS NOT NULL
),
all_urls AS (
  -- every distinct image URL in the dataset
  SELECT DISTINCT original_url
  FROM `bigquery-public-data.open_images.images`
  WHERE original_url IS NOT NULL
)

SELECT
  (SELECT COUNT(*) FROM cat_urls)                    AS cat_url_count,
  (SELECT COUNT(*) FROM all_urls) -
  (SELECT COUNT(*) FROM cat_urls)                    AS other_url_count;
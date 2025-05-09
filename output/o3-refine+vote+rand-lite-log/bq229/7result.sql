WITH cat_urls AS (
  -- All distinct image URLs that contain a “cat” bounding‑box annotation
  SELECT DISTINCT i.original_url
  FROM `bigquery-public-data.open_images.annotations_bbox` AS b
  JOIN `bigquery-public-data.open_images.images`          AS i
    ON b.image_id = i.image_id
  WHERE b.label_name = '/m/01yrx'      -- “cat” label
    AND b.confidence  = 1              -- keep only confident annotations
    AND i.original_url IS NOT NULL
),
all_urls AS (
  -- Every distinct image URL in the whole dataset
  SELECT DISTINCT original_url
  FROM `bigquery-public-data.open_images.images`
  WHERE original_url IS NOT NULL
)
SELECT
  (SELECT COUNT(*) FROM cat_urls)                  AS cat_url_count,
  (SELECT COUNT(*) FROM all_urls)                 - 
  (SELECT COUNT(*) FROM cat_urls)                  AS other_url_count;
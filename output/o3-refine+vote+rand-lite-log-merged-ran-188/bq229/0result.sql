WITH
  -- every image that has ANY “cat” label (any confidence level)
  cat_img_any AS (
    SELECT DISTINCT image_id
    FROM `bigquery-public-data.open_images.labels`
    WHERE label_name = '/m/01yrx'
  ),

  -- URLs of images confidently labeled as cats (confidence = 1)
  cat_urls AS (
    SELECT DISTINCT i.original_url
    FROM `bigquery-public-data.open_images.labels`  l
    JOIN `bigquery-public-data.open_images.images` i
      ON l.image_id = i.image_id
    WHERE l.label_name = '/m/01yrx'
      AND l.confidence = 1
  ),

  -- URLs of images that carry NO cat label at all
  other_urls AS (
    SELECT DISTINCT i.original_url
    FROM `bigquery-public-data.open_images.images` i
    LEFT JOIN cat_img_any c
      ON i.image_id = c.image_id
    WHERE c.image_id IS NULL
  )

SELECT
  (SELECT COUNT(*) FROM cat_urls)  AS cat_url_count,
  (SELECT COUNT(*) FROM other_urls) AS other_url_count;
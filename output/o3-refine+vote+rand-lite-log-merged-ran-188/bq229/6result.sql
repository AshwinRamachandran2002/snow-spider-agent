-- Count distinct original URLs for images labeled as 'cat' (confidence = 1)
-- and for images that have no 'cat' label at all
WITH
  cat_conf1 AS (      -- images confidently labeled as cat
    SELECT DISTINCT image_id
    FROM `bigquery-public-data.open_images.labels`
    WHERE label_name = '/m/01yrx'
      AND confidence = 1
  ),
  cat_any AS (        -- images that have ANY cat label, any confidence
    SELECT DISTINCT image_id
    FROM `bigquery-public-data.open_images.labels`
    WHERE label_name = '/m/01yrx'
  )

SELECT
  -- # of distinct URLs whose image_id appears in cat_conf1
  (SELECT COUNT(DISTINCT i.original_url)
   FROM `bigquery-public-data.open_images.images` AS i
   JOIN cat_conf1 c ON c.image_id = i.image_id
  ) AS cat_url_cnt,

  -- # of distinct URLs whose image_id never appears in cat_any
  (SELECT COUNT(DISTINCT i.original_url)
   FROM `bigquery-public-data.open_images.images` AS i
   LEFT JOIN cat_any a ON a.image_id = i.image_id
   WHERE a.image_id IS NULL
  ) AS other_url_cnt;
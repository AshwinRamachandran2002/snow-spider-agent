WITH cat_image_ids AS (
  -- All images that contain a CAT bounding‑box with confidence = 1
  SELECT DISTINCT image_id
  FROM `bigquery-public-data.open_images.annotations_bbox`
  WHERE label_name = '/m/01yrx'
    AND confidence = 1
),
url_categories AS (
  -- Attach a CAT / OTHER flag to every image URL
  SELECT DISTINCT
         i.original_url,
         IF(c.image_id IS NOT NULL, TRUE, FALSE) AS is_cat
  FROM `bigquery-public-data.open_images.images` AS i
  LEFT JOIN cat_image_ids AS c
  ON i.image_id = c.image_id
)
-- Count distinct URLs in each category
SELECT
  SUM(CASE WHEN is_cat THEN 1 ELSE 0 END) AS cat_url_count,
  SUM(CASE WHEN is_cat THEN 0 ELSE 1 END) AS other_url_count
FROM url_categories;
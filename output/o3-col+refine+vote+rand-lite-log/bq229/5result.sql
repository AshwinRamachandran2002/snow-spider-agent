WITH cat_urls AS (
  SELECT DISTINCT i.original_url
  FROM `bigquery-public-data.open_images.images`            AS i
  JOIN `bigquery-public-data.open_images.annotations_bbox`  AS b
    ON i.image_id = b.image_id
  WHERE b.label_name = '/m/01yrx'   -- CAT label ID
    AND b.confidence = 1            -- keep only high-confidence labels
),
all_urls AS (
  SELECT DISTINCT original_url
  FROM `bigquery-public-data.open_images.images`
)
SELECT
  (SELECT COUNT(*) FROM cat_urls)                                          AS cat_url_cnt,
  (SELECT COUNT(*) FROM all_urls) - (SELECT COUNT(*) FROM cat_urls)        AS other_url_cnt
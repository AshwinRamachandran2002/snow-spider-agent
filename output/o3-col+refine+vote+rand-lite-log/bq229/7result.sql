-- Count of distinct image URLs that ARE cats vs. NOT cats
WITH cat_images AS (
  SELECT DISTINCT i.original_url
  FROM `bigquery-public-data.open_images.annotations_bbox` AS a
  JOIN `bigquery-public-data.open_images.images`           AS i
  ON a.image_id = i.image_id
  WHERE a.label_name = '/m/01yrx'      -- “Cat” label
    AND a.confidence = 1               -- high-confidence annotations
    AND i.original_url IS NOT NULL
),
all_images AS (
  SELECT DISTINCT original_url
  FROM `bigquery-public-data.open_images.images`
  WHERE original_url IS NOT NULL
)
SELECT
  (SELECT COUNT(*) FROM cat_images)                                            AS cat_url_count,
  (SELECT COUNT(*) FROM all_images) - (SELECT COUNT(*) FROM cat_images)        AS other_url_count;
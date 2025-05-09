/* Count distinct image URLs that
   1) have at least one bounding‑box annotation of a cat
      (label '/m/01yrx') with confidence = 1      -> cat_count
   2) have no such annotation at all              -> other_count
*/
WITH url_flags AS (
  SELECT
    i.original_url,
    -- true if any matching cat annotation exists for this URL
    COUNTIF(ab.label_name = '/m/01yrx' AND ab.confidence = 1) > 0 AS is_cat
  FROM `bigquery-public-data.open_images.images`            AS i
  LEFT JOIN `bigquery-public-data.open_images.annotations_bbox` AS ab
         ON i.image_id = ab.image_id
  GROUP BY i.original_url
)
SELECT
  COUNTIF(is_cat)           AS cat_count,
  COUNTIF(NOT is_cat)       AS other_count
FROM url_flags;
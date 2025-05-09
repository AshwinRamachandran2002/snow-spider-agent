SELECT
  CASE
    WHEN cat_labels."image_id" IS NOT NULL THEN 'Cat'
    ELSE 'Other'
  END AS "Category",
  COUNT(DISTINCT images."image_id") AS "Count"
FROM
  "OPEN_IMAGES"."OPEN_IMAGES"."IMAGES" AS images
LEFT JOIN
  (
    SELECT DISTINCT "image_id"
    FROM "OPEN_IMAGES"."OPEN_IMAGES"."LABELS"
    WHERE "label_name" = '/m/01yrx' AND "confidence" = 1.0
  ) AS cat_labels
  ON images."image_id" = cat_labels."image_id"
WHERE images."original_url" IS NOT NULL AND images."original_url" != ''
GROUP BY "Category";
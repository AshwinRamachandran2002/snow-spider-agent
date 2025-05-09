SELECT
  "Category",
  COUNT(*) AS "Count"
FROM (
  SELECT
    "i"."image_id",
    CASE
      WHEN EXISTS (
        SELECT 1
        FROM "OPEN_IMAGES"."OPEN_IMAGES"."LABELS" AS "l"
        WHERE "l"."image_id" = "i"."image_id"
          AND "l"."label_name" = '/m/01yrx'
          AND "l"."confidence" = 1.0
      ) THEN 'Cat'
      ELSE 'Other'
    END AS "Category"
  FROM "OPEN_IMAGES"."OPEN_IMAGES"."IMAGES" AS "i"
) AS "sub"
GROUP BY "Category";
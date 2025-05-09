WITH "cat_label_images" AS (        -- images that have the cat label with confidence = 1
    SELECT DISTINCT "image_id"
    FROM OPEN_IMAGES.OPEN_IMAGES.LABELS
    WHERE "label_name" = '/m/01yrx'
      AND "confidence" = 1
),
"images_with_url" AS (              -- keep only images that have an original_url
    SELECT "image_id",
           "original_url"
    FROM   OPEN_IMAGES.OPEN_IMAGES.IMAGES
    WHERE  "original_url" IS NOT NULL
),
"cat_urls" AS (                     -- distinct URLs of cat images
    SELECT DISTINCT i."original_url"
    FROM   "images_with_url" i
    JOIN   "cat_label_images" c
      ON   i."image_id" = c."image_id"
),
"other_urls" AS (                   -- distinct URLs of non-cat images
    SELECT DISTINCT i."original_url"
    FROM   "images_with_url" i
    LEFT  JOIN "cat_label_images" c
           ON i."image_id" = c."image_id"
    WHERE  c."image_id" IS NULL
)
SELECT
    (SELECT COUNT(*) FROM "cat_urls")   AS "cat_count",
    (SELECT COUNT(*) FROM "other_urls") AS "other_count";
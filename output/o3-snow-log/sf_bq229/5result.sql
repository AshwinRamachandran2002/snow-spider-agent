WITH "cat_images" AS (
    SELECT DISTINCT "image_id"
    FROM OPEN_IMAGES.OPEN_IMAGES.LABELS
    WHERE "label_name" = '/m/01yrx'   -- label for “cat”
      AND "confidence" = 1            -- only keep highest-confidence labels
)
SELECT
    COUNT(DISTINCT CASE WHEN ci."image_id" IS NOT NULL THEN im."original_url" END)  AS "cat_url_count",
    COUNT(DISTINCT CASE WHEN ci."image_id" IS NULL  THEN im."original_url" END)    AS "other_url_count"
FROM OPEN_IMAGES.OPEN_IMAGES.IMAGES  AS im
LEFT JOIN "cat_images"               AS ci
       ON im."image_id" = ci."image_id";
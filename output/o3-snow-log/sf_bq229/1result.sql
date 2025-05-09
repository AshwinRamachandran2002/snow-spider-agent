WITH "CAT_IMAGES" AS (    -- image_ids that have a cat label with confidence = 1
    SELECT DISTINCT "image_id"
    FROM OPEN_IMAGES.OPEN_IMAGES.LABELS
    WHERE "label_name" = '/m/01yrx'
      AND "confidence" = 1
)

SELECT
    COUNT(DISTINCT CASE WHEN c."image_id" IS NOT NULL THEN i."original_url" END) AS "CAT_URL_COUNT",
    COUNT(DISTINCT CASE WHEN c."image_id" IS NULL THEN i."original_url" END) AS "OTHER_URL_COUNT"
FROM OPEN_IMAGES.OPEN_IMAGES.IMAGES AS i
LEFT JOIN "CAT_IMAGES" AS c
       ON i."image_id" = c."image_id";
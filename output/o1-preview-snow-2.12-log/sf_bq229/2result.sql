SELECT
    CASE WHEN l."image_id" IS NOT NULL THEN 'Cat' ELSE 'Other' END AS "Category",
    COUNT(DISTINCT i."image_id") AS "Count"
FROM "OPEN_IMAGES"."OPEN_IMAGES"."IMAGES" i
LEFT JOIN (
    SELECT DISTINCT l."image_id"
    FROM "OPEN_IMAGES"."OPEN_IMAGES"."LABELS" l
    WHERE l."label_name" = '/m/01yrx' AND l."confidence" = 1.0
) l ON i."image_id" = l."image_id"
GROUP BY "Category";
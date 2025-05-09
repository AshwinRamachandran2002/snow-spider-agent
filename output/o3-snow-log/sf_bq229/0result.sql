WITH cat_images AS (
    /* image_ids that have a cat label with confidence = 1 */
    SELECT DISTINCT "image_id"
    FROM OPEN_IMAGES.OPEN_IMAGES.LABELS
    WHERE "label_name" = '/m/01yrx'
      AND "confidence" = 1
),
urls AS (
    /* map image_id to its original_url */
    SELECT "image_id",
           "original_url"
    FROM OPEN_IMAGES.OPEN_IMAGES.IMAGES
),
cat_urls AS (
    /* URLs that belong to cat images */
    SELECT DISTINCT u."original_url"
    FROM urls u
    JOIN cat_images c
      ON u."image_id" = c."image_id"
),
other_urls AS (
    /* URLs whose images never have a cat label */
    SELECT DISTINCT u."original_url"
    FROM urls u
    LEFT JOIN cat_images c
      ON u."image_id" = c."image_id"
    WHERE c."image_id" IS NULL
)
SELECT 'cat'   AS "category", COUNT(*) AS "url_count" FROM cat_urls
UNION ALL
SELECT 'other' AS "category", COUNT(*) AS "url_count" FROM other_urls;
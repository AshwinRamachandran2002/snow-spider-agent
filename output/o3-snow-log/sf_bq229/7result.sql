WITH cat_images AS (
    /* image URLs that contain a CAT label '/m/01yrx' with confidence = 1 */
    SELECT  DISTINCT img."original_url"
    FROM    OPEN_IMAGES.OPEN_IMAGES.IMAGES             AS img
    JOIN    OPEN_IMAGES.OPEN_IMAGES.ANNOTATIONS_BBOX   AS ann
           ON img."image_id" = ann."image_id"
    WHERE   ann."label_name"   = '/m/01yrx'
      AND   ann."confidence"   = 1
      AND   img."original_url" IS NOT NULL
),
other_images AS (
    /* every other image URL that never appears in cat_images */
    SELECT DISTINCT img."original_url"
    FROM   OPEN_IMAGES.OPEN_IMAGES.IMAGES AS img
    WHERE  img."original_url" IS NOT NULL
      AND  NOT EXISTS (
              SELECT 1
              FROM   cat_images c
              WHERE  c."original_url" = img."original_url"
           )
)
SELECT
       (SELECT COUNT(*) FROM cat_images)   AS "cat_count",
       (SELECT COUNT(*) FROM other_images) AS "other_count";
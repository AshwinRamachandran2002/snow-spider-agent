WITH cat_images AS (
    SELECT DISTINCT i."original_url"
    FROM OPEN_IMAGES.OPEN_IMAGES.IMAGES  AS i
    JOIN OPEN_IMAGES.OPEN_IMAGES.LABELS  AS l
      ON i."image_id" = l."image_id"
    WHERE l."label_name" = '/m/01yrx'     -- cat label
      AND l."confidence" = 1              -- only confidence = 1
      AND i."original_url" IS NOT NULL
),
other_images AS (
    SELECT DISTINCT i."original_url"
    FROM OPEN_IMAGES.OPEN_IMAGES.IMAGES AS i
    WHERE i."original_url" IS NOT NULL
      AND i."image_id" NOT IN (           -- exclude every image that has a cat label (any confidence)
          SELECT DISTINCT "image_id"
          FROM OPEN_IMAGES.OPEN_IMAGES.LABELS
          WHERE "label_name" = '/m/01yrx'
      )
)
SELECT 'cat'   AS "category", COUNT(*) AS "distinct_image_url_count" FROM cat_images
UNION ALL
SELECT 'other', COUNT(*) FROM other_images;
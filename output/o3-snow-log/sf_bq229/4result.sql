WITH
    -- all image_ids that have the “cat” label with confidence = 1
    cat_images AS (
        SELECT DISTINCT "image_id"
        FROM OPEN_IMAGES.OPEN_IMAGES.LABELS
        WHERE "label_name" = '/m/01yrx'
          AND "confidence" = 1
    ),

    -- every distinct (image_id , original_url) pair present in the dataset
    all_urls AS (
        SELECT DISTINCT "image_id",
                        "original_url"
        FROM OPEN_IMAGES.OPEN_IMAGES.IMAGES
        WHERE "original_url" IS NOT NULL
    )

SELECT
    COUNT(DISTINCT CASE WHEN ci."image_id" IS NOT NULL THEN au."original_url" END) AS "cat_count",
    COUNT(DISTINCT CASE WHEN ci."image_id" IS NULL THEN au."original_url" END) AS "other_count"
FROM all_urls au
LEFT JOIN cat_images ci
       ON au."image_id" = ci."image_id";
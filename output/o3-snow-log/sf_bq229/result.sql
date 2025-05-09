WITH
  cat_urls AS (   -- every image URL that has a “cat” label (/m/01yrx) with confidence = 1
    SELECT DISTINCT I."original_url"
    FROM OPEN_IMAGES.OPEN_IMAGES.IMAGES  AS I
    JOIN OPEN_IMAGES.OPEN_IMAGES.LABELS  AS L
          ON I."image_id" = L."image_id"
    WHERE L."label_name"  = '/m/01yrx'
      AND L."confidence"  = 1
      AND I."original_url" IS NOT NULL
  ),

  all_urls AS (   -- every image URL in the dataset
    SELECT DISTINCT "original_url"
    FROM OPEN_IMAGES.OPEN_IMAGES.IMAGES
    WHERE "original_url" IS NOT NULL
  )

SELECT
  (SELECT COUNT(*) FROM cat_urls)                                         AS "cat",
  (SELECT COUNT(*) FROM all_urls) - (SELECT COUNT(*) FROM cat_urls)       AS "other";
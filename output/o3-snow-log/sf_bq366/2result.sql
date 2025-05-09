WITH label_per_object AS (   -- pull out every Vision-API label for each artwork
    SELECT
        v."object_id",
        la.value:"description"::STRING AS "label_description"
    FROM THE_MET.THE_MET.VISION_API_DATA v,
         LATERAL FLATTEN (INPUT => v."labelAnnotations") la
),

big_labels AS (              -- keep only labels that occur on ≥ 500 different artworks
    SELECT
        "label_description"
    FROM label_per_object
    GROUP BY "label_description"
    HAVING COUNT(DISTINCT "object_id") >= 500
),

period_label_counts AS (     -- count how often each “big” label appears within each period
    SELECT
        o."period",
        l."label_description",
        COUNT(DISTINCT o."object_id") AS "artwork_count"
    FROM THE_MET.THE_MET.OBJECTS           o
    JOIN label_per_object                  l  ON l."object_id" = o."object_id"
    JOIN big_labels                        b  ON b."label_description" = l."label_description"
    WHERE o."period" IS NOT NULL
    GROUP BY o."period", l."label_description"
),

ranked AS (                  -- rank labels per period by descending frequency
    SELECT
        "period",
        "label_description",
        "artwork_count",
        ROW_NUMBER() OVER (PARTITION BY "period"
                           ORDER BY "artwork_count" DESC, "label_description") AS rn
    FROM period_label_counts
)

SELECT
    "period",
    "label_description" AS "label",
    "artwork_count"
FROM ranked
WHERE rn <= 3                -- top-3 labels for each historical period
ORDER BY
    "period",
    "artwork_count" DESC,
    "label";
WITH popular_labels AS (   -- labels linked to ≥ 500 distinct artworks
    SELECT
        f.value::VARIANT:"description"::STRING AS "label"
    FROM THE_MET.THE_MET.VISION_API_DATA v,
         LATERAL FLATTEN(input => v."labelAnnotations") f
    GROUP BY "label"
    HAVING COUNT(DISTINCT v."object_id") >= 500
),
period_label_counts AS (   -- count artworks per (period, label)
    SELECT
        o."period",
        f.value::VARIANT:"description"::STRING AS "label",
        COUNT(DISTINCT o."object_id")          AS "cnt"
    FROM THE_MET.THE_MET.OBJECTS          o
    JOIN THE_MET.THE_MET.VISION_API_DATA v
      ON o."object_id" = v."object_id"
    ,    LATERAL FLATTEN(input => v."labelAnnotations") f
    WHERE o."period" IS NOT NULL
      AND f.value::VARIANT:"description"::STRING IN (SELECT "label" FROM popular_labels)
    GROUP BY o."period", "label"
),
ranked AS (                 -- rank labels within each period
    SELECT
        "period",
        "label",
        "cnt",
        ROW_NUMBER() OVER (PARTITION BY "period" ORDER BY "cnt" DESC) AS "rn"
    FROM period_label_counts
)
SELECT
    "period",
    "label",
    "cnt"
FROM ranked
WHERE "rn" <= 3
ORDER BY "period", "rn";
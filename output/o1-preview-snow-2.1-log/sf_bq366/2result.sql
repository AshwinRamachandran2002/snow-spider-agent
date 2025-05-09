SELECT
    "period",
    "label",
    "count"
FROM (
    SELECT
        o."period",
        f.value:"description"::STRING AS "label",
        COUNT(DISTINCT o."object_id") AS "count",
        ROW_NUMBER() OVER (
            PARTITION BY o."period"
            ORDER BY COUNT(DISTINCT o."object_id") DESC NULLS LAST
        ) AS rn
    FROM
        THE_MET.THE_MET.OBJECTS o
    JOIN
        THE_MET.THE_MET.VISION_API_DATA v
            ON o."object_id" = v."object_id",
        LATERAL FLATTEN(input => v."labelAnnotations") f
    WHERE
        o."period" IS NOT NULL AND o."period" <> ''
    GROUP BY
        o."period",
        "label"
    HAVING
        COUNT(DISTINCT o."object_id") >= 50
) sub
WHERE
    rn <= 3
ORDER BY
    "period",
    "count" DESC NULLS LAST;
WITH big_labels AS (                 -- labels linked to ≥ 500 artworks overall
    SELECT
        f.value:"description"::STRING AS label
    FROM THE_MET.THE_MET.VISION_API_DATA v,
         LATERAL FLATTEN(INPUT => v."labelAnnotations") f
    GROUP BY 1
    HAVING COUNT(DISTINCT v."object_id") >= 500
),
period_label_counts AS (             -- label frequency within each historical period
    SELECT
        o."period"                            AS period,
        f.value:"description"::STRING         AS label,
        COUNT(DISTINCT o."object_id")         AS artwork_cnt
    FROM THE_MET.THE_MET.OBJECTS o
    JOIN THE_MET.THE_MET.VISION_API_DATA v
          ON o."object_id" = v."object_id"
         ,LATERAL FLATTEN(INPUT => v."labelAnnotations") f
    JOIN big_labels bl
          ON bl.label = f.value:"description"::STRING
    WHERE o."period" IS NOT NULL
    GROUP BY
        o."period",
        f.value:"description"::STRING
)
SELECT
    period,
    label,
    artwork_cnt
FROM (
    SELECT
        plc.*,
        ROW_NUMBER() OVER (PARTITION BY period
                           ORDER BY artwork_cnt DESC) AS rn
    FROM period_label_counts plc
) ranked
WHERE rn <= 3
ORDER BY
    period,
    artwork_cnt DESC NULLS LAST;
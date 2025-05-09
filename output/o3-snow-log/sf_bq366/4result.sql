/* Top-3 most frequent Vision-API labels (appearing on ≥500 artworks) 
   for every historical “period” in The Met collection                 */

WITH label_counts AS (
    SELECT
        o."period"                               AS "period",
        f.value:"description"::STRING            AS "label",
        COUNT(*)                                 AS "cnt"
    FROM THE_MET.THE_MET.VISION_API_DATA  v
    JOIN THE_MET.THE_MET.OBJECTS          o
      ON v."object_id" = o."object_id",
         LATERAL FLATTEN(
             INPUT => TRY_PARSE_JSON(v."labelAnnotations")
         ) f
    WHERE o."period" IS NOT NULL                      -- keep only defined periods
    GROUP BY o."period",
             f.value:"description"::STRING
    HAVING COUNT(*) >= 500                            -- labels linked to ≥500 artworks
), ranked AS (
    SELECT
        "period",
        "label",
        "cnt",
        ROW_NUMBER() OVER (PARTITION BY "period"
                           ORDER BY "cnt" DESC) AS "rn"
    FROM label_counts
)

SELECT
    "period",
    "label",
    "cnt"
FROM ranked
WHERE "rn" <= 3                                        -- top-3 per period
ORDER BY "period",
         "cnt" DESC NULLS LAST;
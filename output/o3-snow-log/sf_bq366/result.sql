WITH
/* 1) keep only the labels that occur on ≥ 500 distinct artworks  */
label_counts AS (
    SELECT 
        f.value:"description"::STRING    AS "label",
        COUNT(DISTINCT v."object_id")    AS "artwork_cnt"
    FROM THE_MET.THE_MET.VISION_API_DATA v ,
         LATERAL FLATTEN(input => v."labelAnnotations") f
    GROUP BY 1
    HAVING COUNT(DISTINCT v."object_id") >= 500
),
/* 2) count how many artworks of every (period , label) pair      */
period_label_counts AS (
    SELECT 
        o."period",
        lc."label",
        COUNT(DISTINCT o."object_id")    AS "artwork_cnt"
    FROM THE_MET.THE_MET.OBJECTS          o
    JOIN THE_MET.THE_MET.VISION_API_DATA  v  ON o."object_id" = v."object_id"
    ,    LATERAL FLATTEN(input => v."labelAnnotations") f
    JOIN  label_counts                    lc ON lc."label" = f.value:"description"::STRING
    WHERE o."period" IS NOT NULL
    GROUP BY o."period", lc."label"
),
/* 3) rank labels inside every period                             */
ranked AS (
    SELECT 
        plc.*,
        ROW_NUMBER() OVER (PARTITION BY plc."period"
                           ORDER BY plc."artwork_cnt" DESC, plc."label") AS "rnk"
    FROM period_label_counts plc
)
/* 4) return the top-3 labels for each historical period          */
SELECT 
    "period",
    "label",
    "artwork_cnt"
FROM ranked
WHERE "rnk" <= 3
ORDER BY "period", "artwork_cnt" DESC NULLS LAST;
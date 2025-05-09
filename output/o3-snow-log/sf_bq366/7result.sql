/*  Top-3 Vision-API labels for every historical period
    – restricted to “popular” labels (≥500 artworks overall) */

WITH objects_with_period AS (          -- artworks that have a recorded period
    SELECT "object_id",
           "period"
    FROM   THE_MET.THE_MET."OBJECTS"
    WHERE  "period" IS NOT NULL
),

popular_labels AS (                    -- labels linked to ≥500 distinct artworks
    SELECT  f.value:"description"::STRING AS label
    FROM    THE_MET.THE_MET."VISION_API_DATA" v,
            LATERAL FLATTEN (INPUT => PARSE_JSON(v."labelAnnotations")) f
    GROUP BY label
    HAVING  COUNT(DISTINCT v."object_id") >= 500
),

labels_per_object AS (                 -- (period , object_id , label) filtered to popular labels
    SELECT DISTINCT
           op."period",
           op."object_id",
           f.value:"description"::STRING AS label
    FROM   objects_with_period op
    JOIN   THE_MET.THE_MET."VISION_API_DATA" v
           ON v."object_id" = op."object_id"
    ,      LATERAL FLATTEN (INPUT => PARSE_JSON(v."labelAnnotations")) f
    WHERE  f.value:"description"::STRING IN (SELECT label FROM popular_labels)
),

period_label_counts AS (               -- artwork counts per (period , label)
    SELECT  "period",
            label,
            COUNT(*) AS cnt
    FROM    labels_per_object
    GROUP BY "period", label
),

ranked AS (                            -- rank labels within each period
    SELECT  plc.*,
            ROW_NUMBER() OVER (PARTITION BY plc."period"
                               ORDER BY plc.cnt DESC) AS rn
    FROM    period_label_counts plc
)

SELECT  "period",
        label,
        cnt
FROM    ranked
WHERE   rn <= 3                        -- top-3 labels for each period
ORDER BY "period",
         cnt DESC NULLS LAST;
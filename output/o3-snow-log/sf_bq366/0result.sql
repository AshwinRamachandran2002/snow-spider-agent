WITH big_labels AS (   -- labels that appear with at least 500 distinct artworks
    SELECT  
        f.value:"description"::STRING       AS "label"
    FROM THE_MET.THE_MET."VISION_API_DATA"  v,
         LATERAL FLATTEN (INPUT => PARSE_JSON(v."labelAnnotations")) f
    GROUP BY "label"
    HAVING COUNT(DISTINCT v."object_id") >= 500
),

period_label_counts AS (   -- how often each of those labels occurs inside each historical period
    SELECT  
        o."period"                              AS "period",
        f.value:"description"::STRING           AS "label",
        COUNT(DISTINCT v."object_id")           AS "artwork_cnt"
    FROM THE_MET.THE_MET."VISION_API_DATA"  v
    JOIN THE_MET.THE_MET."OBJECTS"          o  USING ("object_id")
    JOIN LATERAL FLATTEN (INPUT => PARSE_JSON(v."labelAnnotations")) f
    WHERE f.value:"description"::STRING IN (SELECT "label" FROM big_labels)
      AND o."period" IS NOT NULL
    GROUP BY o."period", f.value:"description"
),

ranked AS (            -- rank labels inside every period by decreasing frequency
    SELECT  
        "period",
        "label",
        "artwork_cnt",
        ROW_NUMBER() OVER (PARTITION BY "period" ORDER BY "artwork_cnt" DESC) AS "rnk"
    FROM period_label_counts
)

SELECT  
    "period",
    "label",
    "artwork_cnt"
FROM ranked
WHERE "rnk" <= 3
ORDER BY "period", "artwork_cnt" DESC NULLS LAST;
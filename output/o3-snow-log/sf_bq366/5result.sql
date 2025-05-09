WITH label_pairs AS (       -- 1. one row per (object_id , label) pair
    SELECT DISTINCT
           v."object_id",
           lf.value:"description"::STRING AS "label"
    FROM   THE_MET.THE_MET.VISION_API_DATA v,
           LATERAL FLATTEN ( INPUT => PARSE_JSON(v."labelAnnotations") ) lf
),
label_counts AS (           -- 2. occurrences of each label within each period
    SELECT  o."period",
            lp."label",
            COUNT(*) AS "cnt"
    FROM    label_pairs lp
    JOIN    THE_MET.THE_MET.OBJECTS o
           ON lp."object_id" = o."object_id"
    WHERE   o."period" IS NOT NULL
    GROUP BY o."period", lp."label"
    HAVING  COUNT(*) >= 500            -- only keep labels linked to ≥ 500 artworks
),
ranked AS (                  -- 3. rank labels inside every period by frequency
    SELECT  "period",
            "label",
            "cnt",
            ROW_NUMBER() OVER (PARTITION BY "period"
                               ORDER BY "cnt" DESC, "label") AS "rnk"
    FROM    label_counts
)
-- 4. return the Top-3 labels for each historical period
SELECT  "period",
        "label",
        "cnt"
FROM    ranked
WHERE   "rnk" <= 3
ORDER BY "period", "cnt" DESC NULLS LAST;
WITH per_cat AS (   -- count collisions by year & cause
    SELECT
        ci."db_year"           AS "year",
        c."pcf_violation_category" AS "cause",
        COUNT(*)               AS "cnt"
    FROM CALIFORNIA_TRAFFIC_COLLISION.CALIFORNIA_TRAFFIC_COLLISION."COLLISIONS"  c
    JOIN CALIFORNIA_TRAFFIC_COLLISION.CALIFORNIA_TRAFFIC_COLLISION."CASE_IDS"    ci
         ON ci."case_id" = c."case_id"
    WHERE c."pcf_violation_category" IS NOT NULL
      AND c."pcf_violation_category" <> ''
    GROUP BY ci."db_year", c."pcf_violation_category"
),
ranked AS (          -- rank causes within each year
    SELECT
        "year",
        "cause",
        ROW_NUMBER() OVER (PARTITION BY "year"
                           ORDER BY "cnt" DESC NULLS LAST, "cause") AS "rn"
    FROM per_cat
),
top2 AS (            -- keep top-2 causes per year
    SELECT "year", "cause", "rn"
    FROM   ranked
    WHERE  "rn" <= 2
),
agg AS (             -- concatenate the two causes to compare years
    SELECT
        "year",
        LISTAGG("cause", ' | ') WITHIN GROUP (ORDER BY "rn") AS "top2_causes"
    FROM top2
    GROUP BY "year"
),
combo_counts AS (    -- how many years share each top-2 combination?
    SELECT
        "top2_causes",
        COUNT(*) AS "years_with_this_combo"
    FROM agg
    GROUP BY "top2_causes"
)
-- years whose two most common causes are unique
SELECT a."year"
FROM   agg           a
JOIN   combo_counts  c
       ON a."top2_causes" = c."top2_causes"
WHERE  c."years_with_this_combo" = 1
ORDER  BY a."year";
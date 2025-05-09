WITH cn_july AS (
    SELECT 
        "city_id",
        "city_name",
        "insert_date" AS "dt"
    FROM "cities"
    WHERE "country_code_2" = 'cn'
      AND "insert_date" BETWEEN '2021-07-01' AND '2021-07-31'
),
ordered AS (
    SELECT
        "city_id",
        "city_name",
        "dt",
        ROW_NUMBER() OVER (ORDER BY "dt")        AS "rn",
        julianday("dt")                          AS "jd"
    FROM cn_july
),
streaks AS (
    SELECT
        "city_id",
        "city_name",
        "dt",
        ("rn" - "jd")                            AS "grp"
    FROM ordered
),
lens AS (
    SELECT 
        "grp",
        COUNT(*)                                 AS "streak_len"
    FROM streaks
    GROUP BY "grp"
),
target_grps AS (
    -- groups for the shortest and longest consecutive-date streaks
    SELECT "grp" FROM lens
    WHERE "streak_len" = (SELECT MIN("streak_len") FROM lens)
       OR "streak_len" = (SELECT MAX("streak_len") FROM lens)
),
one_city_per_date AS (
    -- pick one (alphabetically first) city for each date in those streaks
    SELECT
        "dt",
        MIN("city_name") AS "city_name"
    FROM streaks
    WHERE "grp" IN (SELECT "grp" FROM target_grps)
    GROUP BY "dt"
)
SELECT
    "dt" AS "date",
    UPPER(SUBSTR("city_name",1,1)) || LOWER(SUBSTR("city_name",2)) AS "city_name"
FROM one_city_per_date
ORDER BY "dt";
WITH US_LATEST AS (       -- latest refresh in U.S. rising terms
    SELECT  "term",
            "rank",
            "week"
    FROM    GOOGLE_TRENDS.GOOGLE_TRENDS.TOP_RISING_TERMS
    WHERE   "refresh_date" = (
               SELECT MAX("refresh_date")
               FROM GOOGLE_TRENDS.GOOGLE_TRENDS.TOP_RISING_TERMS
           )
),   
INTL_LATEST AS (         -- latest refresh in international rising terms
    SELECT  "term",
            "rank",
            "week"
    FROM    GOOGLE_TRENDS.GOOGLE_TRENDS.INTERNATIONAL_TOP_RISING_TERMS
    WHERE   "refresh_date" = (
               SELECT MAX("refresh_date")
               FROM GOOGLE_TRENDS.GOOGLE_TRENDS.INTERNATIONAL_TOP_RISING_TERMS
           )
),
UNION_RISING AS (        -- combine both sets
    SELECT * FROM US_LATEST
    UNION ALL
    SELECT * FROM INTL_LATEST
),
LATEST_WEEK AS (         -- most‑recent week across the combined data
    SELECT MAX("week") AS "latest_week"
    FROM   UNION_RISING
),
TARGET_WEEK AS (         -- week exactly 52 weeks (1 year) earlier
    SELECT DATEADD(week, -52, "latest_week") AS "target_week"
    FROM   LATEST_WEEK
),
CANDIDATES AS (          -- rows for that target week
    SELECT  u."term",
            u."rank",
            u."week"
    FROM    UNION_RISING u
    JOIN    TARGET_WEEK t
      ON    u."week" = t."target_week"
)
SELECT  "term",
        "rank",
        "week"
FROM    CANDIDATES
ORDER BY
        "rank" ASC NULLS LAST,   -- best rank first
        "term" ASC
LIMIT 1;
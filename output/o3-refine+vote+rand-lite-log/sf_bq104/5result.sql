WITH "COMBINED" AS (          -- all rising‑term records (US + International)
    SELECT "refresh_date",
           "week",
           "rank",
           "term"
    FROM GOOGLE_TRENDS.GOOGLE_TRENDS."TOP_RISING_TERMS"
    
    UNION ALL
    
    SELECT "refresh_date",
           "week",
           "rank",
           "term"
    FROM GOOGLE_TRENDS.GOOGLE_TRENDS."INTERNATIONAL_TOP_RISING_TERMS"
),
"LATEST_REFRESH" AS (         -- most‑recent load date
    SELECT MAX("refresh_date") AS "latest_refresh_date"
    FROM "COMBINED"
),
"LATEST_WEEK" AS (            -- latest week within that refresh
    SELECT MAX("week") AS "latest_week"
    FROM "COMBINED"
    WHERE "refresh_date" = (SELECT "latest_refresh_date" FROM "LATEST_REFRESH")
),
"TARGET_WEEK" AS (            -- week exactly one year (52 wks) earlier
    SELECT DATEADD(week, -52, "latest_week") AS "target_week"
    FROM "LATEST_WEEK"
),
"TARGET_ROWS" AS (            -- rows for that target week and latest refresh
    SELECT *
    FROM "COMBINED"
    WHERE "refresh_date" = (SELECT "latest_refresh_date" FROM "LATEST_REFRESH")
      AND "week" = (SELECT "target_week" FROM "TARGET_WEEK")
)
SELECT "term",                -- top‑ranked rising search term one year prior
       "rank",
       "week",
       "refresh_date"
FROM "TARGET_ROWS"
ORDER BY "rank" ASC NULLS LAST, "term" ASC
LIMIT 1;
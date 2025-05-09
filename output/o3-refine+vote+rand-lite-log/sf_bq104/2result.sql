WITH RISING_TERMS AS (                      -- combine all rising‑term data
    SELECT "week",
           "term",
           "rank",
           "refresh_date"
    FROM GOOGLE_TRENDS.GOOGLE_TRENDS.TOP_RISING_TERMS
    UNION ALL
    SELECT "week",
           "term",
           "rank",
           "refresh_date"
    FROM GOOGLE_TRENDS.GOOGLE_TRENDS.INTERNATIONAL_TOP_RISING_TERMS
),
LATEST_DATE AS (                            -- most‑recent refresh date
    SELECT MAX("refresh_date") AS "latest_refresh_date"
    FROM RISING_TERMS
),
LATEST_WEEK AS (                            -- latest week within that refresh
    SELECT MAX("week") AS "latest_week"
    FROM RISING_TERMS RT
    JOIN LATEST_DATE LD
      ON RT."refresh_date" = LD."latest_refresh_date"
),
TARGET_WEEK AS (                            -- week exactly 52 weeks earlier
    SELECT DATEADD(week, -52, "latest_week") AS "target_week"
    FROM LATEST_WEEK
)
SELECT
       RT."term",
       RT."rank",
       RT."week",
       RT."refresh_date"
FROM RISING_TERMS RT
JOIN LATEST_DATE LD
  ON RT."refresh_date" = LD."latest_refresh_date"
JOIN TARGET_WEEK TW
  ON RT."week" = TW."target_week"
ORDER BY
       RT."rank" ASC NULLS LAST,            -- best (lowest) rank first
       RT."term" ASC
FETCH FIRST 1 ROWS ONLY;
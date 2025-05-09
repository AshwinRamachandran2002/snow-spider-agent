WITH filtered AS (   -- keep only the relevant records
    SELECT  "year",
            "month",
            "day"
    FROM    GBIF.GBIF.OCCURRENCES
    WHERE   "decimallatitude" > 40                    -- north of 40° latitude
      AND   LOWER("species") = 'sterna paradisaea'    -- Arctic Tern
      AND   "month" > 1                               -- after January
      AND   "month" IS NOT NULL
      AND   "day"   IS NOT NULL
),
daily_counts AS (     -- count sightings per (year, month, day)
    SELECT  "year",
            "month",
            "day",
            COUNT(*) AS sightings
    FROM    filtered
    GROUP BY "year", "month", "day"
    HAVING  COUNT(*) > 10                             -- more than 10 sightings
),
earliest_per_year AS ( -- first qualifying day in each year
    SELECT
        "year",
        MIN(
            TO_DATE(
                TO_CHAR("year") || '-' ||
                LPAD(TO_CHAR("month"), 2, '0') || '-' ||
                LPAD(TO_CHAR("day")  , 2, '0')
            )
        ) AS first_date
    FROM   daily_counts
    GROUP BY "year"
)
-- pick the year whose first qualifying day is the earliest overall
SELECT  "year",
        first_date
FROM    earliest_per_year
ORDER BY first_date ASC NULLS LAST
LIMIT 1;
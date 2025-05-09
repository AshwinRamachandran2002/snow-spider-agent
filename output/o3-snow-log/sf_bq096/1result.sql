WITH
-- 1. keep only sightings of Sterna paradisaea north of 40° and after January
filtered AS (
    SELECT
        "year",
        "month",
        "day"
    FROM GBIF.GBIF."OCCURRENCES"
    WHERE "species" = 'Sterna paradisaea'
      AND "decimallatitude" > 40
      AND "month" > 1                    -- after January
      AND "year"  IS NOT NULL
      AND "month" IS NOT NULL
      AND "day"   IS NOT NULL
),

-- 2. count sightings per (year, month, day) and keep only days with > 10 sightings
daily_counts AS (
    SELECT
        "year",
        "month",
        "day",
        COUNT(*) AS sighting_cnt
    FROM filtered
    GROUP BY "year", "month", "day"
    HAVING COUNT(*) > 10
),

-- 3. for every year, pick the first (month-day) that satisfies the >10 rule
earliest_per_year AS (
    SELECT
        "year",
        "month",
        "day",
        /* use a constant year (2000) so dates from different years are comparable */
        DATE_FROM_PARTS(2000, "month", "day") AS std_date,
        ROW_NUMBER() OVER (PARTITION BY "year"
                           ORDER BY "month", "day") AS rn
    FROM daily_counts
)

-- 4. among all years’ first qualifying dates, find the overall earliest
SELECT
    "year",
    "month",
    "day"
FROM earliest_per_year
WHERE rn = 1               -- only the first qualifying date in each year
ORDER BY std_date          -- earliest calendar date wins
LIMIT 1;
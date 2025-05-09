/* 1. Filter to Sterna paradisaea records north of 40° latitude,
      after January, and with complete year-month-day information.      */
WITH relevant AS (
    SELECT "year",
           "month",
           "day"
    FROM GBIF.GBIF."OCCURRENCES"
    WHERE "species" = 'Sterna paradisaea'          -- target species
      AND "decimallatitude" > 40                  -- north of 40°
      AND "month" > 1                             -- strictly after January
      AND "year"  IS NOT NULL
      AND "month" IS NOT NULL
      AND "day"   IS NOT NULL
),

/* 2. Count sightings for each calendar day in each year
      and keep only days with more than 10 sightings.                  */
daily_counts AS (
    SELECT "year",
           "month",
           "day",
           COUNT(*) AS cnt
    FROM relevant
    GROUP BY "year", "month", "day"
    HAVING cnt > 10                               -- more than 10 sightings
),

/* 3. For every year, find the first (earliest) calendar day
      that satisfies the >10-sightings condition.                      */
first_big_day_per_year AS (
    SELECT
        "year",
        MIN(
            TO_DATE(
                TO_CHAR("year") || '-' ||
                LPAD("month", 2, '0') || '-' ||
                LPAD("day",   2, '0')
            )
        ) AS first_big_day
    FROM daily_counts
    GROUP BY "year"
),

/* 4. Rank the years by how early that first_big_day occurs
      and pick the year (or years) with the absolute earliest date.    */
ranked AS (
    SELECT
        "year",
        first_big_day,
        RANK() OVER (ORDER BY first_big_day) AS rnk
    FROM first_big_day_per_year
)

/* 5. Return the year (and the corresponding date, for reference)
      whose qualifying day is earliest among all years.                */
SELECT
    "year",
    first_big_day          -- optional: remove if only the year is needed
FROM ranked
WHERE rnk = 1;
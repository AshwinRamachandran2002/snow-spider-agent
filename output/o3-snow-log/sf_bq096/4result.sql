WITH daily_counts AS (   -- count sightings for each individual calendar day
    SELECT
        "year",
        DATE_FROM_PARTS("year","month","day")                 AS obs_date,
        COUNT(*)                                              AS sighting_cnt
    FROM GBIF.GBIF."OCCURRENCES"
    WHERE UPPER("species") = 'STERNA PARADISAEA'              -- target species
      AND "decimallatitude" > 40                              -- north of 40° N
      AND "month"  IS NOT NULL
      AND "day"    IS NOT NULL
      AND "month"  > 1                                        -- after January
    GROUP BY "year","month","day"
    HAVING COUNT(*) > 10                                      -- more than 10 sightings
), first_day_per_year AS (     -- first qualifying day in each year
    SELECT
        "year",
        MIN(obs_date) AS first_qualifying_date
    FROM daily_counts
    GROUP BY "year"
), earliest_year AS (          -- year whose first qualifying day is earliest overall
    SELECT
        "year",
        first_qualifying_date
    FROM first_day_per_year
    ORDER BY first_qualifying_date ASC
    LIMIT 1
)
SELECT
    "year",
    first_qualifying_date
FROM earliest_year;
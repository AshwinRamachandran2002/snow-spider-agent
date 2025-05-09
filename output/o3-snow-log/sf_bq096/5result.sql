WITH filtered AS (
    SELECT 
        "year",
        "month",
        "day"
    FROM GBIF.GBIF.OCCURRENCES
    WHERE "species" = 'Sterna paradisaea'        -- target species
      AND "decimallatitude" > 40                -- north of 40° N
      AND "month" IS NOT NULL                   -- ensure complete dates
      AND "day"   IS NOT NULL
      AND "year"  IS NOT NULL
      AND "month" >= 2                          -- after January
),  
daily_counts AS (                               -- count sightings per day
    SELECT
        "year",
        "month",
        "day",
        COUNT(*)                          AS sightings,
        DATE_FROM_PARTS("year","month","day") AS obs_date
    FROM filtered
    GROUP BY "year","month","day"
),  
first_dates AS (                               -- first qualifying date per year
    SELECT
        "year",
        MIN(obs_date) AS first_date
    FROM daily_counts
    WHERE sightings > 10                       -- > 10 sightings on that day
    GROUP BY "year"
)
SELECT "year"
FROM first_dates
ORDER BY first_date ASC          -- earliest such date overall
LIMIT 1;
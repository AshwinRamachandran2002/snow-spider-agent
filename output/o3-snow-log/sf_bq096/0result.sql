WITH daily_counts AS (   -- count sightings for every day after January
    SELECT
        "year",
        "month",
        "day",
        COUNT(*) AS cnt
    FROM GBIF.GBIF."OCCURRENCES"
    WHERE
        ( "species" ILIKE 'Sterna paradisaea%'      -- Arctic Tern
          OR "scientificname" ILIKE 'Sterna paradisaea%' )
        AND "decimallatitude" > 40                  -- north of 40° N
        AND "month" > 1                             -- after January
        AND "month" IS NOT NULL
        AND "day"   IS NOT NULL
    GROUP BY "year","month","day"
), first_after_jan AS (  -- first day in each year with >10 sightings
    SELECT
        "year",
        MIN( DATE_FROM_PARTS("year","month","day") ) AS first_date
    FROM daily_counts
    WHERE cnt > 10
    GROUP BY "year"
), ranked AS (           -- rank years by the earliest such date
    SELECT
        "year",
        first_date,
        RANK() OVER (ORDER BY first_date) AS rnk
    FROM first_after_jan
)
SELECT "year"            -- year whose qualifying date is earliest of all
FROM ranked
WHERE rnk = 1
ORDER BY "year"
LIMIT 1;
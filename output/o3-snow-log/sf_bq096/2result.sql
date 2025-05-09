WITH filtered AS (     -- keep only relevant records
    SELECT
        "year",
        "month",
        "day",
        DATE_FROM_PARTS("year","month","day") AS obs_date
    FROM GBIF.GBIF."OCCURRENCES"
    WHERE "decimallatitude" > 40                     -- north of 40° N
      AND "month" >= 2                               -- after January
      AND "day" IS NOT NULL
      AND ( "species" = 'Sterna paradisaea'
            OR "scientificname" ILIKE 'Sterna paradisaea%' )
), daily_counts AS (    -- count sightings per day
    SELECT
        "year",
        obs_date,
        COUNT(*) AS sighting_cnt
    FROM filtered
    GROUP BY "year", obs_date
    HAVING sighting_cnt > 10                         -- >10 sightings that day
), earliest_per_year AS (  -- first qualifying day for each year
    SELECT
        "year",
        MIN(obs_date) AS first_sighting_date
    FROM daily_counts
    GROUP BY "year"
), ranked AS (          -- rank years by how early that first day occurs
    SELECT
        "year",
        first_sighting_date,
        ROW_NUMBER() OVER (
            ORDER BY EXTRACT(DOY FROM first_sighting_date) ASC,
                     "year" ASC
        ) AS rn
    FROM earliest_per_year
)
SELECT "year"
FROM ranked
WHERE rn = 1;
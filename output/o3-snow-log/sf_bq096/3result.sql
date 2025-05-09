WITH filtered AS (
    SELECT 
        "year",
        "month",
        "day"
    FROM GBIF.GBIF."OCCURRENCES"
    WHERE "decimallatitude" > 40
      AND (
             "species" ILIKE 'Sterna paradisaea'
          OR "scientificname" ILIKE 'Sterna paradisaea%'
      )
      AND "year"  IS NOT NULL
      AND "month" IS NOT NULL
      AND "day"   IS NOT NULL
), daily_counts AS (
    SELECT 
        "year",
        "month",
        "day",
        COUNT(*) AS sighting_count
    FROM filtered
    GROUP BY "year", "month", "day"
), qualified_days AS (
    SELECT
        "year",
        "month",
        "day",
        sighting_count,
        EXTRACT(dayofyear FROM DATE_FROM_PARTS(2000, "month", "day")) AS doy
    FROM daily_counts
    WHERE "month" > 1                -- after January
      AND sighting_count > 10        -- more than 10 sightings
), earliest_per_year AS (
    SELECT
        "year",
        MIN(doy) AS first_doy_after_jan
    FROM qualified_days
    GROUP BY "year"
), overall_earliest AS (
    SELECT
        "year",
        first_doy_after_jan,
        ROW_NUMBER() OVER (ORDER BY first_doy_after_jan ASC, "year" ASC) AS rn
    FROM earliest_per_year
)
SELECT "year"
FROM overall_earliest
WHERE rn = 1;
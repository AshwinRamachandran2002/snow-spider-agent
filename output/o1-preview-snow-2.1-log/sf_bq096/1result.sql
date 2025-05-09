WITH daily_counts AS (
    SELECT "year", "month", "day", COUNT("gbifid") AS "sightings_count"
    FROM GBIF.GBIF.OCCURRENCES
    WHERE "species" = 'Sterna paradisaea'
      AND "decimallatitude" > 40
      AND "month" > 1
    GROUP BY "year", "month", "day"
    HAVING COUNT("gbifid") > 10
),
yearly_first_dates AS (
    SELECT "year", MIN(DATE_FROM_PARTS("year", "month", "day")) AS "first_high_sightings_date"
    FROM daily_counts
    GROUP BY "year"
)
SELECT "year"
FROM yearly_first_dates
ORDER BY "first_high_sightings_date"
LIMIT 1;
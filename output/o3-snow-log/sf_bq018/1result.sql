WITH us_daily AS (
    /* All United-States country-level rows (aggregation_level = 0) */
    SELECT
        "date",
        "new_confirmed",
        "cumulative_confirmed"
    FROM COVID19_OPEN_DATA.COVID19_OPEN_DATA.COVID19_OPEN_DATA
    WHERE "aggregation_level" = 0
      AND "country_code" = 'US'
),
growth_rates AS (
    /* Compute previous day’s cumulative total to calculate daily growth rate */
    SELECT
        "date",
        "new_confirmed",
        LAG("cumulative_confirmed") OVER (ORDER BY "date")            AS prev_confirmed
    FROM us_daily
)
SELECT
    TO_CHAR("date", 'MM-DD')                                          AS "highest_growth_day"
FROM growth_rates
/* Keep only March (3) and April (4) and days with a valid previous total */
WHERE DATE_PART('month', "date") IN (3, 4)
  AND prev_confirmed > 0
/* Growth rate = new_confirmed / previous day's cumulative confirmed */
ORDER BY ("new_confirmed" / prev_confirmed) DESC NULLS LAST
LIMIT 1;
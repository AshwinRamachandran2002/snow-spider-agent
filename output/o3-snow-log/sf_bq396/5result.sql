WITH weekend_accidents AS (   -- crashes on Saturdays (7) or Sundays (1) in 2016
    SELECT
        "state_name",
        CASE
            WHEN UPPER("atmospheric_conditions_name") LIKE '%RAIN%'  THEN 'RAIN'
            WHEN UPPER("atmospheric_conditions_name") LIKE '%CLEAR%' THEN 'CLEAR'
        END                                                             AS weather_category
    FROM NHTSA_TRAFFIC_FATALITIES.NHTSA_TRAFFIC_FATALITIES.ACCIDENT_2016
    WHERE "year_of_crash" = 2016
      AND "day_of_week" IN (1, 7)                                       -- weekend
      AND (   UPPER("atmospheric_conditions_name") LIKE '%RAIN%'        -- keep only Rain or Clear
           OR UPPER("atmospheric_conditions_name") LIKE '%CLEAR%' )
),

by_state_weather AS (           -- count crashes per state & weather
    SELECT
        "state_name",
        weather_category,
        COUNT(*) AS crash_cnt
    FROM weekend_accidents
    GROUP BY "state_name", weather_category
),

pivoted AS (                    -- put rain / clear in separate columns, default 0
    SELECT
        "state_name",
        COALESCE(MAX(CASE WHEN weather_category = 'RAIN'  THEN crash_cnt END),  0) AS rain_crashes,
        COALESCE(MAX(CASE WHEN weather_category = 'CLEAR' THEN crash_cnt END),  0) AS clear_crashes
    FROM by_state_weather
    GROUP BY "state_name"
),

diffs AS (                      -- absolute difference between the two weather types
    SELECT
        "state_name",
        ABS(rain_crashes - clear_crashes) AS difference
    FROM pivoted
)

SELECT
    "state_name",
    difference
FROM diffs
ORDER BY difference DESC NULLS LAST
LIMIT 3;
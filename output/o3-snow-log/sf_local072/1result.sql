WITH jan22 AS (      -- all city rows inserted in January-2022
    SELECT 
        "country_code_2",
        TO_DATE("insert_date")          AS dt,
        "capital"
    FROM CITY_LEGISLATION.CITY_LEGISLATION.CITIES
    WHERE TO_DATE("insert_date") BETWEEN '2022-01-01' AND '2022-01-31'
),
-- country that has data on exactly nine different January-2022 days
country_with_nine_days AS (
    SELECT "country_code_2"
    FROM jan22
    GROUP BY "country_code_2"
    HAVING COUNT(DISTINCT dt) = 9
),
-- build consecutive-day groups for that country
streaks AS (
    SELECT
        j.dt,
        j."capital",
        ROW_NUMBER() OVER (ORDER BY j.dt)                          AS rn,
        DATEDIFF('day', '1900-01-01', j.dt)
          - ROW_NUMBER() OVER (ORDER BY j.dt)                      AS grp        -- identical for members of same streak
    FROM jan22 j
    JOIN country_with_nine_days c 
          ON j."country_code_2" = c."country_code_2"
),
-- longest consecutive insertion period
longest_streak AS (
    SELECT 
        grp,
        MIN(dt) AS period_start,
        MAX(dt) AS period_end,
        COUNT(*) AS days_in_period
    FROM streaks
    GROUP BY grp
    QUALIFY days_in_period = MAX(days_in_period) OVER ()
),
-- compute required proportion within that period
final AS (
    SELECT 
        c."country_code_2"                            AS country_code,
        l.period_start,
        l.period_end,
        SUM(CASE WHEN s."capital" = 1 THEN 1 ELSE 0 END) AS capital_entries,
        COUNT(*)                                          AS total_entries
    FROM country_with_nine_days c
    CROSS JOIN longest_streak           l
    JOIN streaks                        s
      ON s.dt BETWEEN l.period_start AND l.period_end
    GROUP BY c."country_code_2", l.period_start, l.period_end
)
SELECT 
    country_code,
    period_start,
    period_end,
    capital_entries,
    total_entries,
    capital_entries / total_entries::FLOAT  AS capital_entry_ratio
FROM final;
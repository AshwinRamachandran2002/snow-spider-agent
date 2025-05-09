WITH jan2022 AS (          -- keep only January‑2022 rows
    SELECT  city_id,
            city_name,
            country_code_2,
            capital,
            DATE(insert_date) AS ins_date
    FROM    cities
    WHERE   insert_date >= '2022-01-01'
      AND   insert_date <  '2022-02-01'
),
-- 1. country that has data on exactly nine different days in Jan‑2022
country_with_nine_days AS (
    SELECT  country_code_2
    FROM    jan2022
    GROUP BY country_code_2
    HAVING  COUNT(DISTINCT ins_date) = 9
    LIMIT 1                    -- assume only one such country is needed
),
-- 2. all distinct insertion dates for that country
country_dates AS (
    SELECT  DISTINCT ins_date
    FROM    jan2022
    WHERE   country_code_2 = (SELECT country_code_2 FROM country_with_nine_days)
),
-- order them and prepare to detect consecutive streaks
ordered_dates AS (
    SELECT  ins_date,
            ROW_NUMBER() OVER (ORDER BY ins_date)            AS rn,
            CAST(julianday(ins_date) AS INTEGER)             AS jd
    FROM    country_dates
),
-- the key trick: consecutive calendar dates keep (rn‑jd) constant
grouped_dates AS (
    SELECT  ins_date,
            rn - jd AS grp
    FROM    ordered_dates
),
-- length and span of every consecutive run
streaks AS (
    SELECT  grp,
            MIN(ins_date) AS streak_start,
            MAX(ins_date) AS streak_end,
            COUNT(*)      AS streak_len
    FROM    grouped_dates
    GROUP BY grp
),
-- longest consecutive streak in January‑2022 for the target country
longest_streak AS (
    SELECT  *
    FROM    streaks
    ORDER BY streak_len DESC, streak_start
    LIMIT 1
),
-- 3. all rows that fall inside that longest streak
period_entries AS (
    SELECT  *
    FROM    jan2022
    WHERE   country_code_2 = (SELECT country_code_2 FROM country_with_nine_days)
      AND   ins_date BETWEEN (SELECT streak_start FROM longest_streak)
                          AND (SELECT streak_end   FROM longest_streak)
),
-- aggregate to compute capital‑city proportion
proportion AS (
    SELECT  (SELECT country_code_2 FROM country_with_nine_days) AS country_code_2,
            (SELECT streak_start FROM longest_streak)           AS streak_start,
            (SELECT streak_end   FROM longest_streak)           AS streak_end,
            COUNT(*)                                            AS total_entries,
            SUM(CASE WHEN capital = 1 THEN 1 ELSE 0 END)        AS capital_entries
    FROM    period_entries
)
-- final output with country name and requested proportion
SELECT  cc.country_name,
        p.streak_start,
        p.streak_end,
        ROUND(1.0 * p.capital_entries / p.total_entries, 4) AS capital_entry_proportion
FROM    proportion       p
LEFT JOIN cities_countries cc
       ON cc.country_code_2 = p.country_code_2;
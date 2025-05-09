WITH cn_july AS (
    SELECT 
        city_id,
        city_name,
        DATE(insert_date) AS dt
    FROM cities
    WHERE LOWER(country_code_2) = 'cn'
      AND DATE(insert_date) BETWEEN '2021-07-01' AND '2021-07-31'
), 
distinct_dates AS (
    SELECT DISTINCT
        dt AS the_date
    FROM cn_july
),
ordered_dates AS (
    SELECT
        the_date,
        ROW_NUMBER() OVER (ORDER BY the_date)                  AS rn,
        JULIANDAY(the_date)                                    AS jd
    FROM distinct_dates
),
streak_assign AS (
    SELECT
        the_date,
        jd - rn                                                AS grp
    FROM ordered_dates
),
streak_lengths AS (
    SELECT
        grp,
        COUNT(*)                                               AS streak_len
    FROM streak_assign
    GROUP BY grp
),
min_max AS (
    SELECT
        MIN(streak_len) AS min_len,
        MAX(streak_len) AS max_len
    FROM streak_lengths
),
target_grps AS (
    SELECT grp
    FROM streak_lengths, min_max
    WHERE streak_len = min_len
       OR streak_len = max_len
),
target_dates AS (
    SELECT sa.the_date
    FROM streak_assign sa
    JOIN target_grps tg ON sa.grp = tg.grp
),
one_city_per_date AS (
    SELECT
        td.the_date                                           AS date,
        UPPER(SUBSTR(cj.city_name,1,1)) ||
        LOWER(SUBSTR(cj.city_name,2))                         AS city_name,
        ROW_NUMBER() OVER (PARTITION BY td.the_date
                           ORDER BY cj.city_id)               AS city_rank
    FROM target_dates td
    JOIN cn_july cj
      ON cj.dt = td.the_date
)
SELECT
    date,
    city_name
FROM one_city_per_date
WHERE city_rank = 1      -- exactly one record per date
ORDER BY date;
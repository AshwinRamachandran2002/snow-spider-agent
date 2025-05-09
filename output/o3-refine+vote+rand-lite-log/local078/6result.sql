WITH best_per_interest AS (
    /* For every interest pick the month in which it recorded its
       highest composition value (ties => earliest month) */
    SELECT
        im.id                    AS interest_id,
        im.interest_name,
        m.month_year,            -- format MM-YYYY
        m.composition,
        ROW_NUMBER() OVER (
            PARTITION BY im.id
            ORDER BY m.composition DESC, m._year, m._month   -- highest, then earliest
        ) AS rn
    FROM interest_map     AS im
    JOIN interest_metrics AS m
         ON im.id = m.interest_id
),
best_unique AS (
    /* keep just one row (the highest) per interest category */
    SELECT
        interest_name,
        month_year,
        composition
    FROM best_per_interest
    WHERE rn = 1
),
top10 AS (
    SELECT
        'Top 10'   AS rank_group,
        month_year AS time,
        interest_name,
        composition
    FROM best_unique
    ORDER BY composition DESC, interest_name
    LIMIT 10
),
bottom10 AS (
    SELECT
        'Bottom 10' AS rank_group,
        month_year  AS time,
        interest_name,
        composition
    FROM best_unique
    ORDER BY composition ASC, interest_name
    LIMIT 10
)
/* final output: top 10 followed by bottom 10 */
SELECT *
FROM (
    SELECT * FROM top10
    UNION ALL
    SELECT * FROM bottom10
)
ORDER BY
    CASE rank_group WHEN 'Top 10' THEN 0 ELSE 1 END,
    /* within each section keep the required order:
       descending for Top 10, ascending for Bottom 10 */
    CASE
        WHEN rank_group = 'Top 10'  THEN -composition
        ELSE  composition
    END,
    interest_name;
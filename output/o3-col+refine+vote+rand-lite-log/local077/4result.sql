WITH per_int AS (
    /* 1. average composition for every interest each month */
    SELECT
        _year,
        _month,
        month_year,
        interest_id,
        AVG(composition / NULLIF(index_value, 0)) AS avg_comp_ratio
    FROM interest_metrics
    WHERE (_year = 2018 AND _month >= 9)
       OR (_year = 2019 AND _month <= 8)
    GROUP BY _year, _month, month_year, interest_id
),
monthly_max AS (
    /* 2. take the interest with the highest avg_comp_ratio each month */
    SELECT p.*
    FROM per_int p
    JOIN (
        SELECT _year, _month, MAX(avg_comp_ratio) AS max_ratio
        FROM per_int
        GROUP BY _year, _month
    ) mx
      ON mx._year  = p._year
     AND mx._month = p._month
     AND mx.max_ratio = p.avg_comp_ratio
),
monthly_named AS (
    /* 3. attach readable interest names */
    SELECT
        mm._year,
        mm._month,
        mm.month_year,
        im.interest_name,
        mm.avg_comp_ratio AS max_index_comp
    FROM monthly_max mm
    JOIN interest_map im
      ON im.id = CAST(mm.interest_id AS INTEGER)
)
SELECT
    month_year AS date,
    interest_name,
    ROUND(max_index_comp, 4) AS max_index_composition,
    ROUND(
        AVG(max_index_comp) OVER (
            ORDER BY _year, _month
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ),
        4
    ) AS rolling_avg_3m,
    LAG(interest_name, 1) OVER (ORDER BY _year, _month) AS last_month_interest,
    ROUND(LAG(max_index_comp, 1) OVER (ORDER BY _year, _month), 4) AS last_month_max_index_comp,
    LAG(interest_name, 2) OVER (ORDER BY _year, _month) AS two_months_ago_interest,
    ROUND(LAG(max_index_comp, 2) OVER (ORDER BY _year, _month), 4) AS two_months_ago_max_index_comp
FROM monthly_named
ORDER BY _year, _month;
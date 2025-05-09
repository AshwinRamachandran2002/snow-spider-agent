WITH filtered AS (
    SELECT
        CAST(_year  AS INTEGER)                AS yr,
        CAST(_month AS INTEGER)                AS mn,
        month_year,
        interest_id,
        composition,
        index_value
    FROM interest_metrics
    WHERE (_year = 2018 AND _month >= 9)
       OR (_year = 2019 AND _month <= 8)
),
monthly_interest AS (
    SELECT
        yr,
        mn,
        month_year,
        interest_id,
        AVG(composition / NULLIF(index_value, 0)) AS avg_comp
    FROM filtered
    GROUP BY yr, mn, month_year, interest_id
),
monthly_best AS (
    SELECT
        yr,
        mn,
        month_year,
        interest_id,
        avg_comp                                  AS max_index_composition,
        ROW_NUMBER() OVER (PARTITION BY yr, mn
                           ORDER BY avg_comp DESC) AS rn
    FROM monthly_interest
),
top_per_month AS (
    SELECT
        yr,
        mn,
        month_year,
        interest_id,
        max_index_composition
    FROM monthly_best
    WHERE rn = 1
),
with_names AS (
    SELECT
        t.*,
        im.interest_name
    FROM top_per_month t
    LEFT JOIN interest_map im
           ON im.id = t.interest_id
),
rolling AS (
    SELECT
        *,
        AVG(max_index_composition) OVER (
            ORDER BY yr, mn
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        )                                         AS rolling_avg_3mo_max
    FROM with_names
)
SELECT
    month_year                                   AS date,
    interest_name                                AS interest_name,
    ROUND(max_index_composition, 4)              AS max_index_composition,
    ROUND(rolling_avg_3mo_max, 4)                AS rolling_avg_3mo_max,
    LAG(interest_name, 1) OVER (ORDER BY yr, mn) AS last_month_interest_name,
    ROUND(LAG(max_index_composition, 1) OVER
          (ORDER BY yr, mn), 4)                  AS last_month_max_index_composition,
    LAG(interest_name, 2) OVER (ORDER BY yr, mn) AS two_months_ago_interest_name,
    ROUND(LAG(max_index_composition, 2) OVER
          (ORDER BY yr, mn), 4)                  AS two_months_ago_max_index_composition
FROM rolling
ORDER BY yr, mn;
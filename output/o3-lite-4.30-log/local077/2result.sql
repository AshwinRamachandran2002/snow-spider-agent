WITH monthly AS (
    /* 1 ── average composition for every interest in the window               */
    SELECT
        month_year,
        CAST(substr(month_year, 4) AS INTEGER)          AS yr,        -- YYYY
        CAST(substr(month_year, 1, 2) AS INTEGER)       AS mo,        -- MM
        interest_id,
        composition / NULLIF(index_value, 0)            AS avg_comp
    FROM interest_metrics
    WHERE (_year * 100 + _month) BETWEEN 201809 AND 201908
      AND index_value <> 0
),
top_per_month AS (
    /* 2 ── highest‐avg_comp interest each month                                */
    SELECT
        month_year, yr, mo, interest_id, avg_comp,
        ROW_NUMBER() OVER (PARTITION BY month_year ORDER BY avg_comp DESC) AS rn
    FROM monthly
),
winner AS (
    /* 3 ── keep only winners                                                   */
    SELECT month_year, yr, mo, interest_id, avg_comp
    FROM   top_per_month
    WHERE  rn = 1
),
calc AS (
    /* 4 ── add 3‑month rolling avg and lag information                         */
    SELECT
        *,
        AVG(avg_comp) OVER (ORDER BY yr, mo
                            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)  AS rolling_avg_3mo,
        LAG(interest_id, 1) OVER (ORDER BY yr, mo)                     AS prev_id_1,
        LAG(avg_comp,   1) OVER (ORDER BY yr, mo)                     AS prev_comp_1,
        LAG(interest_id, 2) OVER (ORDER BY yr, mo)                     AS prev_id_2,
        LAG(avg_comp,   2) OVER (ORDER BY yr, mo)                     AS prev_comp_2
    FROM winner
)
SELECT
    date,
    interest_name,
    ROUND(max_index_composition, 4)                        AS max_index_composition,
    ROUND(rolling_avg_3mo_max, 4)                          AS rolling_avg_3mo_max,
    last_month_interest_name,
    ROUND(last_month_max_index_composition, 4)             AS last_month_max_index_composition,
    two_months_ago_interest_name,
    ROUND(two_months_ago_max_index_composition, 4)         AS two_months_ago_max_index_composition
FROM (
    /* 5 ── attach readable names for current and lagged interests             */
    SELECT
        c.month_year                              AS date,
        im0.interest_name                         AS interest_name,
        c.avg_comp                                AS max_index_composition,
        c.rolling_avg_3mo                         AS rolling_avg_3mo_max,
        im1.interest_name                         AS last_month_interest_name,
        c.prev_comp_1                             AS last_month_max_index_composition,
        im2.interest_name                         AS two_months_ago_interest_name,
        c.prev_comp_2                             AS two_months_ago_max_index_composition,
        c.yr, c.mo
    FROM calc        AS c
    JOIN interest_map AS im0 ON im0.id = c.interest_id
    LEFT JOIN interest_map AS im1 ON im1.id = c.prev_id_1
    LEFT JOIN interest_map AS im2 ON im2.id = c.prev_id_2
)
ORDER BY yr, mo;
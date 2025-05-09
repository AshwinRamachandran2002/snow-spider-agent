/* --------------------------------------------------------------------
   Analyse interest data (Sep-2018 → Aug-2019)

   1. Safely turn month_year (e.g. '09-2018') into a proper first-of-month
      date using TRY_TO_DATE; discard rows that fail to convert.
   2. Calculate average composition = composition / index_value.
   3. For every month, pick the interest with the highest average value.
   4. Derive a 3-month rolling average of those monthly maxima and bring
      forward the prior-month and two-months-ago winners & their values.
-------------------------------------------------------------------- */

WITH raw AS (  -- safe date conversion
    SELECT
        TRY_TO_DATE('01-'||TRIM("month_year"),'DD-MM-YYYY')  AS month_dt,
        "interest_id",
        "composition",
        "index_value"
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.INTEREST_METRICS
),

metrics_filtered AS (  -- Sep-2018 → Aug-2019 + avg_comp
    SELECT
        month_dt,
        "interest_id",
        "composition",
        "index_value",
        "composition" / NULLIF("index_value",0)               AS avg_comp
    FROM raw
    WHERE month_dt BETWEEN '2018-09-01' AND '2019-08-01'
          AND month_dt IS NOT NULL
),

monthly_ranked AS (  -- rank interests within each month
    SELECT
        mf.month_dt,
        mf."interest_id",
        im."interest_name",
        mf.avg_comp,
        ROW_NUMBER() OVER (PARTITION BY mf.month_dt
                           ORDER BY mf.avg_comp DESC NULLS LAST) AS rn
    FROM metrics_filtered mf
    LEFT JOIN BANK_SALES_TRADING.BANK_SALES_TRADING.INTEREST_MAP im
           ON mf."interest_id" = im."id"
),

top_per_month AS (  -- keep monthly winner
    SELECT
        month_dt,
        "interest_name"      AS top_interest,
        avg_comp             AS max_index_comp
    FROM monthly_ranked
    WHERE rn = 1
),

final AS (  -- rolling averages & lagged winners
    SELECT
        month_dt,
        TO_CHAR(month_dt,'YYYY-MM')                           AS month_year,
        top_interest,
        max_index_comp,
        ROUND(
              AVG(max_index_comp) OVER (ORDER BY month_dt
                                        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW),
              4)                                              AS rolling_3m_avg_max_index_comp,
        LAG(top_interest ,1) OVER (ORDER BY month_dt)         AS prev1_top_interest,
        LAG(max_index_comp,1) OVER (ORDER BY month_dt)        AS prev1_max_index_comp,
        LAG(top_interest ,2) OVER (ORDER BY month_dt)         AS prev2_top_interest,
        LAG(max_index_comp,2) OVER (ORDER BY month_dt)        AS prev2_max_index_comp
    FROM top_per_month
)

SELECT
    month_year                              AS "date",
    top_interest                            AS "interest_name",
    max_index_comp                          AS "max_index_composition",
    rolling_3m_avg_max_index_comp           AS "rolling_3m_average",
    prev1_top_interest                      AS "top_interest_1_month_ago",
    prev1_max_index_comp                    AS "max_index_composition_1_month_ago",
    prev2_top_interest                      AS "top_interest_2_months_ago",
    prev2_max_index_comp                    AS "max_index_composition_2_months_ago"
FROM final
ORDER BY month_dt;
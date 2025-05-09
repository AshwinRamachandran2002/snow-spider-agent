/* -------------------------------------------------------------
   Monthly top-interest analysis with 3-month rolling statistics
   Period: 2018-09 to 2019-08
--------------------------------------------------------------*/
WITH metrics_parsed AS (                          -- add a real date column safely
    SELECT
        TRY_TO_DATE('01-' || "month_year", 'DD-MM-YYYY') AS "month_start",
        "month_year",
        "interest_id",
        "composition",
        "index_value"
    FROM "BANK_SALES_TRADING"."BANK_SALES_TRADING"."INTEREST_METRICS"
), filtered AS (                                  -- keep only the required period & valid dates
    SELECT *
    FROM metrics_parsed
    WHERE "month_start" BETWEEN '2018-09-01' AND '2019-08-31'
), ratio_per_interest AS (                        -- average composition / index_value per interest & month
    SELECT
        "month_start",
        "month_year",
        "interest_id",
        AVG("composition" / NULLIF("index_value", 0))  AS "avg_comp_index"
    FROM filtered
    GROUP BY "month_start", "month_year", "interest_id"
), monthly_top AS (                               -- find the highest value each month
    SELECT
        rpi.*,
        ROW_NUMBER() OVER (
            PARTITION BY rpi."month_start"
            ORDER BY rpi."avg_comp_index" DESC NULLS LAST
        ) AS "rn"
    FROM ratio_per_interest rpi
), monthly_max AS (                               -- bring in the interest name
    SELECT
        mt."month_start",
        mt."month_year",
        im."interest_name",
        mt."avg_comp_index"          AS "max_index_composition"
    FROM monthly_top mt
    JOIN "BANK_SALES_TRADING"."BANK_SALES_TRADING"."INTEREST_MAP" im
         ON im."id" = mt."interest_id"
    WHERE mt."rn" = 1
), rolling_calc AS (                              -- 3-month rolling average & look-backs
    SELECT
        mm."month_start",
        TO_CHAR(mm."month_start", 'YYYY-MM')                     AS "month",
        mm."interest_name"                                       AS "current_month_top_interest",
        mm."max_index_composition",
        AVG(mm."max_index_composition") OVER (
            ORDER BY mm."month_start"
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        )                                                        AS "rolling_avg_3m",
        LAG(mm."interest_name", 1)  OVER (ORDER BY mm."month_start") AS "top_interest_1m_ago",
        LAG(mm."max_index_composition", 1) OVER (ORDER BY mm."month_start") AS "max_index_comp_1m_ago",
        LAG(mm."interest_name", 2)  OVER (ORDER BY mm."month_start") AS "top_interest_2m_ago",
        LAG(mm."max_index_composition", 2) OVER (ORDER BY mm."month_start") AS "max_index_comp_2m_ago"
    FROM monthly_max mm
)
SELECT
    "month",
    "current_month_top_interest",
    "max_index_composition",
    "rolling_avg_3m",
    "top_interest_1m_ago",
    "max_index_comp_1m_ago",
    "top_interest_2m_ago",
    "max_index_comp_2m_ago"
FROM rolling_calc
ORDER BY "month_start" NULLS LAST;
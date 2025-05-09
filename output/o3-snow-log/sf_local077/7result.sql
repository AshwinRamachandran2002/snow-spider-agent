/* -----------------------------------------------------------
   Monthly leading interest (max avg_comp) from Sep-2018 to Aug-2019,
   plus 3-month rolling average and look-backs to the prior 1 & 2 months
-------------------------------------------------------------*/
WITH im_parsed AS (      -- safely convert month text to date
    SELECT
        TRY_TO_DATE("month_year", 'MM-YYYY')       AS month_start,
        "interest_id",
        "composition",
        "index_value"
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.INTEREST_METRICS
    WHERE TRY_TO_DATE("month_year", 'MM-YYYY') IS NOT NULL
),
monthly_interest_avg AS ( -- average composition / index_value per interest & month
    SELECT
        ip.month_start,
        ip."interest_id",
        mp."interest_name",
        AVG(ip."composition" / NULLIF(ip."index_value", 0))  AS avg_comp
    FROM   im_parsed ip
           JOIN BANK_SALES_TRADING.BANK_SALES_TRADING.INTEREST_MAP mp
             ON mp."id" = ip."interest_id"
    WHERE  ip.month_start BETWEEN '2018-09-01' AND '2019-08-31'
    GROUP BY ip.month_start, ip."interest_id", mp."interest_name"
),
monthly_max AS (         -- keep only the top interest each month
    SELECT
        month_start,
        "interest_name",
        avg_comp AS max_index_comp
    FROM   monthly_interest_avg
    QUALIFY ROW_NUMBER() OVER (PARTITION BY month_start
                               ORDER BY avg_comp DESC NULLS LAST) = 1
)
SELECT
    month_start                                                          AS "date",
    "interest_name"                                                      AS "interest_name",
    ROUND(max_index_comp, 4)                                             AS "max_index_composition",
    ROUND(AVG(max_index_comp) OVER (ORDER BY month_start
                                    ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 4)
                                                                        AS "rolling_avg_3m",
    LAG("interest_name", 1) OVER (ORDER BY month_start)                  AS "prev1_interest_name",
    ROUND(LAG(max_index_comp, 1) OVER (ORDER BY month_start), 4)         AS "prev1_max_index_comp",
    LAG("interest_name", 2) OVER (ORDER BY month_start)                  AS "prev2_interest_name",
    ROUND(LAG(max_index_comp, 2) OVER (ORDER BY month_start), 4)         AS "prev2_max_index_comp"
FROM   monthly_max
ORDER BY month_start;
/*---------------------------------------------------------------------------
Average % change in sales for each attribute type
(12 weeks BEFORE vs 12 weeks AFTER 15-Jun-2020)
and the attribute type with the greatest negative impact
---------------------------------------------------------------------------*/
WITH base AS (   -- keep only the 24-week window around 15-Jun-2020
    SELECT
        TO_DATE("week_date")                    AS week_dt,
        "sales",
        "region",
        "platform",
        "age_band",
        "demographic",
        "customer_type"
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.CLEANED_WEEKLY_SALES
    WHERE TO_DATE("week_date")
          BETWEEN DATEADD(week,-12,'2020-06-15'::DATE)
              AND DATEADD(week, 12,'2020-06-15'::DATE)
), period_flag AS (   -- flag weeks as BEFORE or AFTER the pivot date
    SELECT
        *,
        CASE
            WHEN week_dt <  '2020-06-15'::DATE THEN 'before'
            WHEN week_dt >= '2020-06-15'::DATE THEN 'after'
        END                                               AS period
    FROM base
),                                   /* -------------------------------
                                       aggregate average weekly sales
                                       for every attribute value & period
                                       --------------------------------*/
attr_avgs AS (
    /* REGION */
    SELECT 'region'         AS attr_type,
           "region"         AS attr_value,
           period,
           AVG("sales")     AS avg_sales
    FROM period_flag
    WHERE "region" IS NOT NULL
    GROUP BY "region", period
    UNION ALL
    /* PLATFORM */
    SELECT 'platform', "platform", period, AVG("sales")
    FROM period_flag
    WHERE "platform" IS NOT NULL
    GROUP BY "platform", period
    UNION ALL
    /* AGE BAND */
    SELECT 'age_band', "age_band", period, AVG("sales")
    FROM period_flag
    WHERE "age_band" IS NOT NULL
    GROUP BY "age_band", period
    UNION ALL
    /* DEMOGRAPHIC */
    SELECT 'demographic', "demographic", period, AVG("sales")
    FROM period_flag
    WHERE "demographic" IS NOT NULL
    GROUP BY "demographic", period
    UNION ALL
    /* CUSTOMER TYPE */
    SELECT 'customer_type', "customer_type", period, AVG("sales")
    FROM period_flag
    WHERE "customer_type" IS NOT NULL
    GROUP BY "customer_type", period
),                                   /* -------------------------------
                                       compute % change for each value
                                       --------------------------------*/
value_changes AS (
    SELECT
        attr_type,
        attr_value,
        MAX(CASE WHEN period='before' THEN avg_sales END) AS before_avg,
        MAX(CASE WHEN period='after'  THEN avg_sales END) AS after_avg
    FROM attr_avgs
    GROUP BY attr_type, attr_value
    HAVING MAX(CASE WHEN period='before' THEN avg_sales END) > 0      -- avoid div/0
),                                   /* -------------------------------
                                       average % change per attribute type
                                       --------------------------------*/
type_changes AS (
    SELECT
        attr_type,
        AVG( (after_avg - before_avg) / before_avg * 100 )  AS avg_pct_change
    FROM value_changes
    WHERE after_avg IS NOT NULL
    GROUP BY attr_type
)
SELECT
    attr_type                           AS attribute_type,
    ROUND(avg_pct_change,4)             AS average_pct_change_percent
FROM type_changes
ORDER BY avg_pct_change ASC NULLS LAST   -- most negative first
LIMIT 1;                                 -- attribute type with highest negative impact
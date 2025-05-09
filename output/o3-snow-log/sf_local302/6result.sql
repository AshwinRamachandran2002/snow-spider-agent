WITH base AS (
    /* keep only required columns and cast week date to DATE.
       Alias columns without double-quotes so they remain case-insensitive. */
    SELECT  
        TO_DATE("week_date",'YYYY-MM-DD')  AS week_dt ,
        "region"                           AS region ,
        "platform"                         AS platform ,
        "age_band"                         AS age_band ,
        "demographic"                      AS demographic ,
        "customer_type"                    AS customer_type ,
        "sales"                            AS sales
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.CLEANED_WEEKLY_SALES
),  

period_tag AS (
    /* label each week as PRE (12 wks before 15-Jun-2020 inclusive)
       or POST (12 wks after 15-Jun-2020 exclusive)                  */
    SELECT  *,
            CASE
                WHEN week_dt BETWEEN DATEADD(week,-12,DATE'2020-06-15')
                                 AND        DATE'2020-06-15'        THEN 'PRE'
                WHEN week_dt  >  DATE'2020-06-15'
                     AND week_dt <= DATEADD(week, 12,DATE'2020-06-15') THEN 'POST'
            END AS period_flag
    FROM base
    WHERE week_dt BETWEEN DATEADD(week,-12,DATE'2020-06-15')
                      AND  DATEADD(week, 12,DATE'2020-06-15')
),  

unpivoted AS (
    /* convert every attribute type/value pair into its own row      */
    SELECT 'region'        AS attr_type,  region        AS attr_value, period_flag, sales FROM period_tag
    UNION ALL
    SELECT 'platform'      ,  platform      , period_flag, sales FROM period_tag
    UNION ALL
    SELECT 'age_band'      ,  age_band      , period_flag, sales FROM period_tag
    UNION ALL
    SELECT 'demographic'   ,  demographic   , period_flag, sales FROM period_tag
    UNION ALL
    SELECT 'customer_type' ,  customer_type , period_flag, sales FROM period_tag
),  

agg AS (
    /* total PRE and POST sales per attribute value                  */
    SELECT
        attr_type,
        attr_value,
        SUM(CASE WHEN period_flag='PRE'  THEN sales END) AS pre_sales,
        SUM(CASE WHEN period_flag='POST' THEN sales END) AS post_sales
    FROM unpivoted
    WHERE period_flag IS NOT NULL
    GROUP BY attr_type, attr_value
),  

pct_change AS (
    /* % change for each attribute value                             */
    SELECT
        attr_type,
        attr_value,
        CASE 
            WHEN pre_sales = 0 OR pre_sales IS NULL THEN NULL
            ELSE (post_sales - pre_sales) * 100.0 / pre_sales
        END AS pct_change
    FROM agg
),  

avg_change_by_type AS (
    /* average % change across values of each attribute type         */
    SELECT
        attr_type,
        AVG(pct_change) AS avg_pct_change
    FROM pct_change
    GROUP BY attr_type
)

SELECT 
    attr_type   AS attribute_with_highest_negative_impact,
    avg_pct_change
FROM avg_change_by_type
ORDER BY avg_pct_change ASC NULLS LAST   -- most negative first
LIMIT 1;
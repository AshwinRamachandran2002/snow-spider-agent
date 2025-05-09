WITH cleaned AS (
    SELECT  
        TO_DATE("week_date")                                     AS week_dt,
        "region",
        "platform",
        "age_band",
        "demographic",
        "customer_type",
        "sales"
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.CLEANED_WEEKLY_SALES
),

/* reference dates around 15-Jun-2020 */
bounds AS (
    SELECT  
        TO_DATE('2020-06-15')                                            AS mid_dt,
        DATEADD(WEEK,-12,TO_DATE('2020-06-15'))                          AS start_before,
        DATEADD(DAY ,-1 ,TO_DATE('2020-06-15'))                          AS end_before,
        DATEADD(DAY , 1 ,TO_DATE('2020-06-15'))                          AS start_after,
        DATEADD(WEEK, 12,TO_DATE('2020-06-15'))                          AS end_after
),

/* tag every record as BEFORE or AFTER the cut-off (within the 24-week window) */
tagged AS (
    SELECT  c.*,
            CASE 
                  WHEN c.week_dt BETWEEN b.start_before AND b.end_before THEN 'BEFORE'
                  WHEN c.week_dt BETWEEN b.start_after  AND b.end_after  THEN 'AFTER'
            END                                                         AS period
    FROM    cleaned c
    CROSS   JOIN bounds b
    WHERE   c.week_dt BETWEEN b.start_before AND b.end_after
),

/* ---------- REGION ---------- */
region_stats AS (
    SELECT  "region"                                                    AS attr_val,
            SUM(CASE WHEN period='BEFORE' THEN "sales" END)             AS sales_before,
            SUM(CASE WHEN period='AFTER'  THEN "sales" END)             AS sales_after
    FROM    tagged
    GROUP BY "region"
),
region_pct AS (
    SELECT  'region'                                                    AS attribute_type,
            AVG( (sales_after - sales_before)/NULLIF(sales_before,0)
               * 100 )                                                  AS avg_pct_change
    FROM    region_stats
),

/* ---------- PLATFORM ---------- */
platform_stats AS (
    SELECT  "platform"                                                  AS attr_val,
            SUM(CASE WHEN period='BEFORE' THEN "sales" END)             AS sales_before,
            SUM(CASE WHEN period='AFTER'  THEN "sales" END)             AS sales_after
    FROM    tagged
    GROUP BY "platform"
),
platform_pct AS (
    SELECT  'platform'                                                  AS attribute_type,
            AVG( (sales_after - sales_before)/NULLIF(sales_before,0)
               * 100 )                                                  AS avg_pct_change
    FROM    platform_stats
),

/* ---------- AGE BAND ---------- */
age_stats AS (
    SELECT  "age_band"                                                  AS attr_val,
            SUM(CASE WHEN period='BEFORE' THEN "sales" END)             AS sales_before,
            SUM(CASE WHEN period='AFTER'  THEN "sales" END)             AS sales_after
    FROM    tagged
    GROUP BY "age_band"
),
age_pct AS (
    SELECT  'age_band'                                                  AS attribute_type,
            AVG( (sales_after - sales_before)/NULLIF(sales_before,0)
               * 100 )                                                  AS avg_pct_change
    FROM    age_stats
),

/* ---------- DEMOGRAPHIC ---------- */
demo_stats AS (
    SELECT  "demographic"                                               AS attr_val,
            SUM(CASE WHEN period='BEFORE' THEN "sales" END)             AS sales_before,
            SUM(CASE WHEN period='AFTER'  THEN "sales" END)             AS sales_after
    FROM    tagged
    GROUP BY "demographic"
),
demo_pct AS (
    SELECT  'demographic'                                               AS attribute_type,
            AVG( (sales_after - sales_before)/NULLIF(sales_before,0)
               * 100 )                                                  AS avg_pct_change
    FROM    demo_stats
),

/* ---------- CUSTOMER TYPE ---------- */
cust_stats AS (
    SELECT  "customer_type"                                             AS attr_val,
            SUM(CASE WHEN period='BEFORE' THEN "sales" END)             AS sales_before,
            SUM(CASE WHEN period='AFTER'  THEN "sales" END)             AS sales_after
    FROM    tagged
    GROUP BY "customer_type"
),
cust_pct AS (
    SELECT  'customer_type'                                             AS attribute_type,
            AVG( (sales_after - sales_before)/NULLIF(sales_before,0)
               * 100 )                                                  AS avg_pct_change
    FROM    cust_stats
),

/* bring all attribute-level averages together */
combined AS (
    SELECT * FROM region_pct
    UNION ALL
    SELECT * FROM platform_pct
    UNION ALL
    SELECT * FROM age_pct
    UNION ALL
    SELECT * FROM demo_pct
    UNION ALL
    SELECT * FROM cust_pct
)

/* -------- final output: attribute type with the largest negative impact -------- */
SELECT  attribute_type,
        avg_pct_change
FROM    combined
ORDER BY avg_pct_change ASC NULLS LAST      -- most negative first
FETCH FIRST 1 ROW ONLY;
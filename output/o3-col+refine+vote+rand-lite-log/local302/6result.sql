WITH date_window AS (
    SELECT   date('2020-06-15','-12 weeks') AS pre_start ,
             date('2020-06-14')             AS pre_end   ,
             date('2020-06-15')             AS post_start,
             date('2020-06-15','+11 weeks') AS post_end
),
attribute_sales AS (

    /* ---------- region ---------- */
    SELECT 'region' AS attr_type ,
           region   AS attr_value ,
           SUM(CASE
                   WHEN date(week_date) BETWEEN (SELECT pre_start  FROM date_window)
                                         AND     (SELECT pre_end    FROM date_window)
                   THEN sales ELSE 0 END) AS before_sales ,
           SUM(CASE
                   WHEN date(week_date) BETWEEN (SELECT post_start FROM date_window)
                                         AND     (SELECT post_end   FROM date_window)
                   THEN sales ELSE 0 END) AS after_sales
    FROM   cleaned_weekly_sales
    GROUP  BY region

    UNION ALL

    /* ---------- platform ---------- */
    SELECT 'platform' , platform ,
           SUM(CASE
                   WHEN date(week_date) BETWEEN (SELECT pre_start FROM date_window)
                                         AND     (SELECT pre_end   FROM date_window)
                   THEN sales ELSE 0 END) ,
           SUM(CASE
                   WHEN date(week_date) BETWEEN (SELECT post_start FROM date_window)
                                         AND     (SELECT post_end   FROM date_window)
                   THEN sales ELSE 0 END)
    FROM   cleaned_weekly_sales
    GROUP  BY platform

    UNION ALL

    /* ---------- age band ---------- */
    SELECT 'age_band' , age_band ,
           SUM(CASE
                   WHEN date(week_date) BETWEEN (SELECT pre_start FROM date_window)
                                         AND     (SELECT pre_end   FROM date_window)
                   THEN sales ELSE 0 END) ,
           SUM(CASE
                   WHEN date(week_date) BETWEEN (SELECT post_start FROM date_window)
                                         AND     (SELECT post_end   FROM date_window)
                   THEN sales ELSE 0 END)
    FROM   cleaned_weekly_sales
    GROUP  BY age_band

    UNION ALL

    /* ---------- demographic ---------- */
    SELECT 'demographic' , demographic ,
           SUM(CASE
                   WHEN date(week_date) BETWEEN (SELECT pre_start FROM date_window)
                                         AND     (SELECT pre_end   FROM date_window)
                   THEN sales ELSE 0 END) ,
           SUM(CASE
                   WHEN date(week_date) BETWEEN (SELECT post_start FROM date_window)
                                         AND     (SELECT post_end  FROM date_window)
                   THEN sales ELSE 0 END)
    FROM   cleaned_weekly_sales
    GROUP  BY demographic

    UNION ALL

    /* ---------- customer type ---------- */
    SELECT 'customer_type' , customer_type ,
           SUM(CASE
                   WHEN date(week_date) BETWEEN (SELECT pre_start FROM date_window)
                                         AND     (SELECT pre_end   FROM date_window)
                   THEN sales ELSE 0 END) ,
           SUM(CASE
                   WHEN date(week_date) BETWEEN (SELECT post_start FROM date_window)
                                         AND     (SELECT post_end  FROM date_window)
                   THEN sales ELSE 0 END)
    FROM   cleaned_weekly_sales
    GROUP  BY customer_type
),
pct_changes AS (
    SELECT attr_type ,
           attr_value ,
           CASE
                WHEN before_sales = 0 THEN NULL
                ELSE (after_sales - before_sales)*100.0 / before_sales
           END AS pct_change
    FROM   attribute_sales
),
avg_pct_change AS (
    SELECT  attr_type ,
            ROUND(AVG(pct_change),4) AS avg_pct_change
    FROM    pct_changes
    GROUP   BY attr_type
)

/* attribute type with the highest negative impact */
SELECT  attr_type ,
        avg_pct_change
FROM    avg_pct_change
ORDER BY avg_pct_change ASC     -- most negative first
LIMIT 1;
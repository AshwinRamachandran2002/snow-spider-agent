WITH period_sales AS (
  SELECT
        calendar_year,
        CASE
          WHEN week_date < DATE(calendar_year || '-06-15')
               AND week_date >= DATE(calendar_year || '-06-15','-28 days')
               THEN 'before'
          WHEN week_date >= DATE(calendar_year || '-06-15')
               AND week_date <  DATE(calendar_year || '-06-15','+28 days')
               THEN 'after'
        END                                             AS period,
        sales
  FROM cleaned_weekly_sales
  WHERE calendar_year IN (2018, 2019, 2020)
    AND week_date BETWEEN DATE(calendar_year || '-06-15','-28 days')
                      AND DATE(calendar_year || '-06-15','+27 days')
)
SELECT
      calendar_year,
      ROUND(
            (SUM(CASE WHEN period = 'after'  THEN sales END) -
             SUM(CASE WHEN period = 'before' THEN sales END)) * 100.0
            / SUM(CASE WHEN period = 'before' THEN sales END)
           , 4)                                          AS pct_change_after_vs_before
FROM period_sales
GROUP BY calendar_year
ORDER BY calendar_year;
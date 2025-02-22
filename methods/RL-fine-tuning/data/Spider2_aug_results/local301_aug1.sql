-- Task: For the weekly-sales data, calculate the percentage change in sales between the four weeks leading up to June 15 and the four weeks following June 15 for the year 2018.
SELECT 
    before_effect,
    after_effect,
    after_effect - before_effect AS change_amount,
    ROUND(((after_effect * 1.0 / before_effect) - 1) * 100, 2) AS percent_change,
    '2018' AS year
FROM (
    SELECT 
        SUM(CASE WHEN delta_weeks BETWEEN 1 AND 4 THEN sales END) AS after_effect,
        SUM(CASE WHEN delta_weeks BETWEEN -3 AND 0 THEN sales END) AS before_effect
    FROM (
        SELECT 
            week_date,
            ROUND((JULIANDAY(week_date) - JULIANDAY('2018-06-15')) / 7.0) + 1 AS delta_weeks,
            sales 
        FROM cleaned_weekly_sales
    ) add_delta_weeks
) AS add_before_after;
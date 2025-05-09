WITH unicorns AS (
    -- companies valued at $1B+
    SELECT company_id
    FROM companies_funding
    WHERE valuation >= 1000000000
),
unicorn_dates AS (
    -- unicorns that joined between 2019 and 2021
    SELECT  u.company_id,
            SUBSTR(cd.date_joined, 1, 4) AS join_year
    FROM    unicorns u
    JOIN    companies_dates cd  ON cd.company_id = u.company_id
    WHERE   SUBSTR(cd.date_joined, 1, 4) BETWEEN '2019' AND '2021'
),
unicorn_industries AS (
    -- attach industry
    SELECT  ud.company_id,
            ud.join_year,
            ci.industry
    FROM    unicorn_dates ud
    JOIN    companies_industries ci ON ci.company_id = ud.company_id
),
top_industry AS (
    -- industry with the most unicorns during 2019‑2021
    SELECT  industry
    FROM    unicorn_industries
    GROUP BY industry
    ORDER BY COUNT(*) DESC
    LIMIT 1
),
yearly_counts AS (
    -- count unicorns in the top industry by year
    SELECT  ui.join_year,
            COUNT(*) AS unicorns_in_year
    FROM    unicorn_industries ui
    JOIN    top_industry ti ON ui.industry = ti.industry
    GROUP BY ui.join_year
),
all_years AS (
    -- ensure every year 2019‑2021 is represented
    SELECT '2019' AS join_year UNION ALL
    SELECT '2020' UNION ALL
    SELECT '2021'
),
filled_counts AS (
    SELECT  ay.join_year,
            COALESCE(yc.unicorns_in_year, 0) AS unicorns_in_year
    FROM    all_years ay
    LEFT JOIN yearly_counts yc USING (join_year)
)
SELECT AVG(unicorns_in_year * 1.0) AS average_new_unicorns_per_year
FROM   filled_counts;
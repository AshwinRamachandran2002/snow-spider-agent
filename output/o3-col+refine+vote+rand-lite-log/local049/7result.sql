WITH unicorns AS (
    /* 1. all companies valued at least $1B (“unicorns”) */
    SELECT DISTINCT company_id
    FROM companies_funding
    WHERE valuation >= 1000000000
),
unicorn_2019_2021 AS (
    /* 2. add join year (2019-2021 only) and industry */
    SELECT  u.company_id,
            substr(cd.date_joined,1,4) AS join_year,
            ci.industry
    FROM    unicorns           u
    JOIN    companies_dates    cd ON cd.company_id = u.company_id
    JOIN    companies_industries ci ON ci.company_id = u.company_id
    WHERE   substr(cd.date_joined,1,4) BETWEEN '2019' AND '2021'
),
top_industry AS (
    /* 3. find the single industry with the most new unicorns */
    SELECT industry
    FROM   unicorn_2019_2021
    GROUP BY industry
    ORDER BY COUNT(*) DESC
    LIMIT 1
),
yearly_counts AS (
    /* 4. count new unicorns per year in that top industry */
    SELECT join_year,
           COUNT(*) AS yearly_unicorns
    FROM   unicorn_2019_2021
    WHERE  industry = (SELECT industry FROM top_industry)
    GROUP BY join_year
)
/* 5. average yearly count (2019-2021) */
SELECT AVG(yearly_unicorns) AS avg_new_unicorns_per_year
FROM   yearly_counts;
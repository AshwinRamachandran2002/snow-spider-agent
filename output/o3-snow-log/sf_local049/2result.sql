/*  Average number of new unicorn companies per year (2019-2021) 
    for the industry that has the most unicorns overall              */

WITH unicorns AS (                       -- all companies valued ≥ $1B
    SELECT DISTINCT "company_id"
    FROM MODERN_DATA.MODERN_DATA.COMPANIES_FUNDING
    WHERE "valuation" >= 1000000000
),
unicorn_industries AS (                  -- map those unicorns to industries
    SELECT u."company_id",
           ci."industry"
    FROM   unicorns                   u
    JOIN   MODERN_DATA.MODERN_DATA.COMPANIES_INDUSTRIES ci 
           ON u."company_id" = ci."company_id"
),
top_industry AS (                        -- the single industry with MOST unicorns
    SELECT "industry"
    FROM   unicorn_industries
    GROUP  BY "industry"
    ORDER  BY COUNT(*) DESC
    LIMIT  1
),
yearly_counts AS (                       -- count NEW unicorns per year (2019-2021)
    SELECT LEFT(cd."date_joined", 4)              AS "year",
           COUNT(DISTINCT ui."company_id")        AS "cnt"
    FROM   unicorn_industries               ui
    JOIN   top_industry                      ti  ON ui."industry" = ti."industry"
    JOIN   MODERN_DATA.MODERN_DATA.COMPANIES_DATES cd 
           ON ui."company_id" = cd."company_id"
    WHERE  LEFT(cd."date_joined", 4) IN ('2019','2020','2021')
    GROUP  BY LEFT(cd."date_joined", 4)
)
SELECT AVG("cnt") AS "avg_new_unicorns_per_year"
FROM   yearly_counts;
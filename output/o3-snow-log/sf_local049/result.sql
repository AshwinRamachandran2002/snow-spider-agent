WITH unicorns AS (
    -- all unicorns (valuation ≥ $1B) created between 2019-2021
    SELECT
        cf."company_id",
        ci."industry",
        SUBSTR(cd."date_joined",1,4)          AS "year_joined"
    FROM MODERN_DATA.MODERN_DATA."COMPANIES_FUNDING"   cf
    JOIN MODERN_DATA.MODERN_DATA."COMPANIES_DATES"     cd
          ON cf."company_id" = cd."company_id"
    JOIN MODERN_DATA.MODERN_DATA."COMPANIES_INDUSTRIES" ci
          ON cf."company_id" = ci."company_id"
    WHERE cf."valuation" >= 1000000000
      AND SUBSTR(cd."date_joined",1,4) BETWEEN '2019' AND '2021'
),
top_industry AS (
    -- find the single industry with the most unicorns in 2019-2021
    SELECT "industry"
    FROM unicorns
    GROUP BY "industry"
    ORDER BY COUNT(*) DESC NULLS LAST
    LIMIT 1
),
yearly_counts AS (
    -- count new unicorns each year for that top industry
    SELECT
        u."year_joined",
        COUNT(*) AS "new_unicorns"
    FROM unicorns u
    JOIN top_industry t
          ON u."industry" = t."industry"
    GROUP BY u."year_joined"
)
-- average number of new unicorns per year (2019-2021) for the top industry
SELECT
    AVG("new_unicorns") AS "avg_new_unicorns_per_year"
FROM yearly_counts;
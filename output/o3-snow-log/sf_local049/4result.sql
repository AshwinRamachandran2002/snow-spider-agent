WITH unicorns_2019_2021 AS (
    SELECT
        i."industry",
        SUBSTR(d."date_joined", 1, 4) AS "year"
    FROM MODERN_DATA.MODERN_DATA.COMPANIES_FUNDING   f
    JOIN MODERN_DATA.MODERN_DATA.COMPANIES_DATES     d
          ON f."company_id" = d."company_id"
    JOIN MODERN_DATA.MODERN_DATA.COMPANIES_INDUSTRIES i
          ON f."company_id" = i."company_id"
    WHERE f."valuation" >= 1000000000                -- qualifies as a “unicorn”
      AND SUBSTR(d."date_joined", 1, 4) IN ('2019','2020','2021')
),
top_industry AS (                                   -- find the single top industry
    SELECT "industry"
    FROM unicorns_2019_2021
    GROUP BY "industry"
    ORDER BY COUNT(*) DESC NULLS LAST
    LIMIT 1
),
yearly_totals AS (                                  -- count new unicorns each year for that industry
    SELECT
        u."industry",
        u."year",
        COUNT(*) AS "new_unicorns"
    FROM unicorns_2019_2021 u
    JOIN top_industry t
      ON u."industry" = t."industry"
    GROUP BY u."industry", u."year"
)
SELECT
    "industry"                               AS "top_industry",
    AVG("new_unicorns")                      AS "avg_new_unicorns_per_year"
FROM yearly_totals
GROUP BY "industry";
WITH unicorns AS (   -- all companies that became unicorns in 2019-2021
    SELECT 
        i."industry",
        d."company_id",
        d."date_joined"
    FROM MODERN_DATA.MODERN_DATA.COMPANIES_INDUSTRIES  i
    JOIN MODERN_DATA.MODERN_DATA.COMPANIES_DATES       d ON i."company_id" = d."company_id"
    JOIN MODERN_DATA.MODERN_DATA.COMPANIES_FUNDING     f ON i."company_id" = f."company_id"
    WHERE f."valuation" >= 1000000000
      AND SUBSTR(d."date_joined",1,4) BETWEEN '2019' AND '2021'
), 
top_industry AS (    -- find the single most common industry among those unicorns
    SELECT 
        "industry"
    FROM unicorns
    GROUP BY "industry"
    ORDER BY COUNT(*) DESC NULLS LAST
    LIMIT 1
),
yearly_counts AS (   -- count new unicorns per year in that top industry
    SELECT 
        SUBSTR(u."date_joined",1,4)           AS "join_year",
        COUNT(*)                              AS "yearly_unicorns"
    FROM unicorns u
    JOIN top_industry t
      ON u."industry" = t."industry"
    GROUP BY SUBSTR(u."date_joined",1,4)
)
-- final average for 2019-2021
SELECT 
    AVG("yearly_unicorns") AS "avg_new_unicorns_per_year"
FROM yearly_counts;
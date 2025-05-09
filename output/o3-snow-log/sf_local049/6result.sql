WITH top_industry AS (   /* 1. Identify the industry with the most new unicorns, 2019-2021 */
    SELECT i."industry"
    FROM MODERN_DATA.MODERN_DATA.COMPANIES_FUNDING     f
    JOIN MODERN_DATA.MODERN_DATA.COMPANIES_INDUSTRIES  i ON f."company_id" = i."company_id"
    JOIN MODERN_DATA.MODERN_DATA.COMPANIES_DATES       d ON f."company_id" = d."company_id"
    WHERE f."valuation" >= 1000000000
      AND SUBSTR(d."date_joined", 1, 4) IN ('2019','2020','2021')
    GROUP BY i."industry"
    ORDER BY COUNT(*) DESC NULLS LAST
    LIMIT 1
),
yearly_counts AS (       /* 2. Count new unicorns in that top industry for each year */
    SELECT 
        SUBSTR(d."date_joined", 1, 4) AS "join_year",
        COUNT(*)                     AS "new_unicorns"
    FROM MODERN_DATA.MODERN_DATA.COMPANIES_FUNDING     f
    JOIN MODERN_DATA.MODERN_DATA.COMPANIES_INDUSTRIES  i ON f."company_id" = i."company_id"
    JOIN MODERN_DATA.MODERN_DATA.COMPANIES_DATES       d ON f."company_id" = d."company_id"
    JOIN top_industry t                                   ON i."industry"  = t."industry"
    WHERE f."valuation" >= 1000000000
      AND SUBSTR(d."date_joined", 1, 4) IN ('2019','2020','2021')
    GROUP BY SUBSTR(d."date_joined", 1, 4)
)
SELECT                   /* 3. Average number of new unicorns per year (2019-2021) */
    AVG("new_unicorns") AS "avg_new_unicorns_per_year_top_industry_2019_2021"
FROM yearly_counts;
WITH unicorns AS (
    -- 1.  Identify all unicorn companies (valuation ≥ 1 B) that joined in 2019-2021
    SELECT
        f."company_id",
        TO_NUMBER(SUBSTR(d."date_joined", 1, 4))  AS "join_year",
        i."industry"
    FROM MODERN_DATA.MODERN_DATA.COMPANIES_FUNDING     f
    JOIN MODERN_DATA.MODERN_DATA.COMPANIES_DATES       d  ON f."company_id" = d."company_id"
    JOIN MODERN_DATA.MODERN_DATA.COMPANIES_INDUSTRIES  i  ON f."company_id" = i."company_id"
    WHERE f."valuation" >= 1000000000
      AND TO_NUMBER(SUBSTR(d."date_joined", 1, 4)) BETWEEN 2019 AND 2021
), industry_totals AS (
    -- 2.  Find the industry with the most new unicorns during this period
    SELECT
        "industry",
        COUNT(*)                                    AS "unicorn_cnt",
        RANK() OVER (ORDER BY COUNT(*) DESC)        AS "rnk"
    FROM unicorns
    GROUP BY "industry"
), top_industry AS (
    -- 3.  Keep only the top industry (rank = 1)
    SELECT "industry"
    FROM industry_totals
    WHERE "rnk" = 1
), yearly_counts AS (
    -- 4.  Count new unicorns per year within the top industry
    SELECT
        u."join_year",
        COUNT(*)  AS "yearly_unicorns"
    FROM unicorns u
    JOIN top_industry t
          ON u."industry" = t."industry"
    GROUP BY u."join_year"
)
-- 5.  Compute the average number of new unicorns per year (2019-2021) in that industry
SELECT
    AVG("yearly_unicorns") AS "avg_new_unicorns_per_year"
FROM yearly_counts;
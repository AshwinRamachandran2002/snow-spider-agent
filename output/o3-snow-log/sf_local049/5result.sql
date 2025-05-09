WITH
-- 1. unicorn companies (valuation ≥ 1 B)
"unicorns" AS (
    SELECT  f."company_id"
    FROM    MODERN_DATA.MODERN_DATA.COMPANIES_FUNDING f
    WHERE   f."valuation" >= 1000000000
),

-- 2. unicorns that joined between 2019-2021 (inclusive) with their join year
"dated_unicorns" AS (
    SELECT  u."company_id",
            LEFT(d."date_joined", 4) AS "join_year"
    FROM    "unicorns"                u
    JOIN    MODERN_DATA.MODERN_DATA.COMPANIES_DATES d
            ON u."company_id" = d."company_id"
    WHERE   LEFT(d."date_joined", 4) BETWEEN '2019' AND '2021'
),

-- 3. attach industries
"sector_unicorns" AS (
    SELECT  du."company_id",
            du."join_year",
            i."industry"
    FROM    "dated_unicorns"         du
    JOIN    MODERN_DATA.MODERN_DATA.COMPANIES_INDUSTRIES i
            ON du."company_id" = i."company_id"
),

-- 4. identify the top industry during 2019-2021
"industry_rank" AS (
    SELECT  s."industry",
            COUNT(*)                       AS "total_unicorns",
            ROW_NUMBER() OVER (
                ORDER BY COUNT(*) DESC
            )                              AS "rn"
    FROM    "sector_unicorns" s
    GROUP BY s."industry"
),
"top_industry" AS (
    SELECT  "industry"
    FROM    "industry_rank"
    WHERE   "rn" = 1        -- highest count
),

-- 5. count new unicorns per year for that top industry
"yearly_counts" AS (
    SELECT  su."join_year",
            COUNT(*) AS "new_unicorns"
    FROM    "sector_unicorns" su
    JOIN    "top_industry"    ti
            ON su."industry" = ti."industry"
    GROUP BY su."join_year"
)

-- 6. average number of new unicorns per year (2019-2021) in the top industry
SELECT  AVG("new_unicorns") AS "avg_new_unicorns_per_year"
FROM    "yearly_counts";
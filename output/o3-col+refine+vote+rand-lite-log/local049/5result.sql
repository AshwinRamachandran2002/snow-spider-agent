WITH unicorns_2019_2021 AS (
    SELECT cf."company_id",
           ci."industry",
           cd."date_joined",
           strftime('%Y', cd."date_joined") AS "year"
    FROM   "companies_funding"    AS cf
    JOIN   "companies_industries" AS ci ON cf."company_id" = ci."company_id"
    JOIN   "companies_dates"      AS cd ON cf."company_id" = cd."company_id"
    WHERE  cf."valuation" >= 1000000000                -- unicorn threshold
      AND  cd."date_joined" >= '2019-01-01'            -- start of window
      AND  cd."date_joined" <  '2022-01-01'            -- end of window
),
top_industry AS (                                   -- industry with most unicorns
    SELECT "industry"
    FROM   unicorns_2019_2021
    GROUP  BY "industry"
    ORDER  BY COUNT(*) DESC
    LIMIT  1
),
yearly_counts AS (                                  -- yearly counts for that industry
    SELECT "year",
           COUNT(*) AS "unicorn_count"
    FROM   unicorns_2019_2021
    WHERE  "industry" = (SELECT "industry" FROM top_industry)
    GROUP  BY "year"
)
SELECT AVG("unicorn_count") AS "avg_unicorns_per_year"
FROM   yearly_counts;
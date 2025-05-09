WITH unicorns AS (
    SELECT f."company_id",
           substr(d."date_joined", 1, 4) AS "year_joined",
           i."industry"
    FROM "companies_funding"   AS f
    JOIN "companies_dates"     AS d USING ("company_id")
    JOIN "companies_industries" AS i USING ("company_id")
    WHERE f."valuation" >= 1000000000
      AND substr(d."date_joined", 1, 4) BETWEEN '2019' AND '2021'
),
top_industry AS (
    SELECT "industry"
    FROM unicorns
    GROUP BY "industry"
    ORDER BY COUNT(*) DESC
    LIMIT 1
),
yearly_counts AS (
    SELECT "year_joined",
           COUNT(*) AS "unicorns"
    FROM unicorns
    WHERE "industry" = (SELECT "industry" FROM top_industry)
    GROUP BY "year_joined"
)
SELECT (SELECT "industry" FROM top_industry)          AS "top_industry",
       ROUND(AVG("unicorns"), 4)                      AS "avg_unicorns_per_year_2019_2021"
FROM yearly_counts;
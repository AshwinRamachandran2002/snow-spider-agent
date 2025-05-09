WITH "unicorns" AS (           -- all unicorns created between 2019-01-01 and 2021-12-31
    SELECT
        f."company_id",
        TO_DATE(d."date_joined")        AS "joined_date",
        i."industry"
    FROM "MODERN_DATA"."MODERN_DATA"."COMPANIES_FUNDING"     f
    JOIN "MODERN_DATA"."MODERN_DATA"."COMPANIES_DATES"       d
          ON f."company_id" = d."company_id"
    JOIN "MODERN_DATA"."MODERN_DATA"."COMPANIES_INDUSTRIES"  i
          ON f."company_id" = i."company_id"
    WHERE f."valuation" >= 1000000000
      AND TO_DATE(d."date_joined") BETWEEN '2019-01-01' AND '2021-12-31'
),
"top_industry" AS (            -- industry with the most unicorns in that window
    SELECT "industry"
    FROM   "unicorns"
    GROUP  BY "industry"
    ORDER  BY COUNT(*) DESC NULLS LAST
    LIMIT  1
),
"yearly_counts" AS (           -- yearly new-unicorn counts for the top industry
    SELECT
        TO_CHAR("joined_date", 'YYYY')  AS "year_joined",
        COUNT(*)                        AS "new_unicorns"
    FROM   "unicorns" u
    JOIN   "top_industry" t
           ON u."industry" = t."industry"
    GROUP  BY TO_CHAR("joined_date", 'YYYY')
)
SELECT
    AVG("new_unicorns") AS "avg_new_unicorns_per_year"
FROM   "yearly_counts";
WITH
top_industry AS (
    SELECT
        i."industry"
    FROM
        "MODERN_DATA"."MODERN_DATA"."COMPANIES_FUNDING" f
        JOIN "MODERN_DATA"."MODERN_DATA"."COMPANIES_DATES" d
            ON f."company_id" = d."company_id"
        JOIN "MODERN_DATA"."MODERN_DATA"."COMPANIES_INDUSTRIES" i
            ON f."company_id" = i."company_id"
    WHERE
        f."valuation" >= 1000000000
        AND TO_DATE(SUBSTRING(d."date_joined", 1, 10), 'YYYY-MM-DD') BETWEEN TO_DATE('2019-01-01', 'YYYY-MM-DD') AND TO_DATE('2021-12-31', 'YYYY-MM-DD')
    GROUP BY
        i."industry"
    ORDER BY
        COUNT(DISTINCT f."company_id") DESC NULLS LAST
    LIMIT 1
),
per_year AS (
    SELECT
        EXTRACT(year FROM TO_DATE(SUBSTRING(d."date_joined", 1, 10), 'YYYY-MM-DD')) AS "year",
        COUNT(DISTINCT f."company_id") AS "company_count"
    FROM
        "MODERN_DATA"."MODERN_DATA"."COMPANIES_FUNDING" f
        JOIN "MODERN_DATA"."MODERN_DATA"."COMPANIES_DATES" d
            ON f."company_id" = d."company_id"
        JOIN "MODERN_DATA"."MODERN_DATA"."COMPANIES_INDUSTRIES" i
            ON f."company_id" = i."company_id"
    WHERE
        f."valuation" >= 1000000000
        AND i."industry" = (SELECT "industry" FROM top_industry)
        AND EXTRACT(year FROM TO_DATE(SUBSTRING(d."date_joined", 1, 10), 'YYYY-MM-DD')) BETWEEN 2019 AND 2021
    GROUP BY
        EXTRACT(year FROM TO_DATE(SUBSTRING(d."date_joined", 1, 10), 'YYYY-MM-DD'))
)
SELECT
    ROUND(AVG("company_count"), 4) AS "Average_new_unicorn_companies_per_year_in_top_industry"
FROM
    per_year;
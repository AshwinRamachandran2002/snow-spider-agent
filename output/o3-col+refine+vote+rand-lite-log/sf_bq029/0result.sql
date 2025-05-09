WITH "ca_pub_inventors" AS (
    SELECT
        p."publication_number",
        COUNT(f.value)                      AS "inventor_cnt",
        FLOOR(p."publication_date" / 10000) AS "pub_year"
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN(input => p."inventor") f
    WHERE p."country_code" = 'CA'
      AND p."inventor" IS NOT NULL                -- ensure at least one inventor
      AND FLOOR(p."publication_date" / 10000) BETWEEN 1960 AND 2020
    GROUP BY
        p."publication_number",
        FLOOR(p."publication_date" / 10000)
)

SELECT
    FLOOR( ("pub_year" - 1960) / 5 ) * 5 + 1960 AS "five_year_period_start",
    COUNT(*)                                    AS "total_publications_CA",
    AVG("inventor_cnt")                         AS "average_inventors_per_patent"
FROM "ca_pub_inventors"
GROUP BY
    FLOOR( ("pub_year" - 1960) / 5 ) * 5 + 1960
ORDER BY
    "five_year_period_start";
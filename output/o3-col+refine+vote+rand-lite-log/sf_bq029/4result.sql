WITH per_publication AS (
    SELECT
        p."publication_number",
        COUNT(inv.value)                                   AS "inventor_cnt",
        TO_NUMBER(SUBSTR(TO_VARCHAR(p."publication_date"), 1, 4)) AS "pub_year",
        CONCAT(
            5 * FLOOR((TO_NUMBER(SUBSTR(TO_VARCHAR(p."publication_date"), 1, 4)) - 1960) / 5) + 1960,
            '-',
            5 * FLOOR((TO_NUMBER(SUBSTR(TO_VARCHAR(p."publication_date"), 1, 4)) - 1960) / 5) + 1964
        )                                                 AS "five_year_period"
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN(input => p."inventor") inv
    WHERE p."country_code" = 'CA'
    GROUP BY p."publication_number", p."publication_date"
)

SELECT
    "five_year_period",
    COUNT(*)                              AS "total_publications",
    AVG("inventor_cnt")                   AS "avg_inventors_per_patent"
FROM per_publication
WHERE "inventor_cnt" > 0
  AND "pub_year" BETWEEN 1960 AND 2020
GROUP BY "five_year_period"
ORDER BY TO_NUMBER(SUBSTR("five_year_period", 1, 4));
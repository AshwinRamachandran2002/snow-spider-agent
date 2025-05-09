WITH per_patent AS (
    SELECT
        "publication_number",
        /* 5-year interval label, e.g. 1960-1964 */
        TO_CHAR(1960 + 5 * FLOOR((FLOOR("publication_date" / 10000) - 1960) / 5)) || '-' ||
        TO_CHAR(1964 + 5 * FLOOR((FLOOR("publication_date" / 10000) - 1960) / 5))  AS "period_5yr",
        COUNT(inv.value) AS "inventor_count"
    FROM PATENTS.PATENTS.PUBLICATIONS
         , LATERAL FLATTEN(input => "inventor") inv
    WHERE "country_code" = 'CA'
      AND FLOOR("publication_date" / 10000) BETWEEN 1960 AND 2020
    GROUP BY "publication_number", "period_5yr"
    HAVING COUNT(inv.value) > 0            -- keep patents with ≥1 inventor
)
SELECT
    "period_5yr",
    COUNT(*)                                AS "publication_count",
    ROUND(AVG("inventor_count"), 4)         AS "avg_inventors_per_patent"
FROM per_patent
GROUP BY "period_5yr"
ORDER BY "period_5yr";
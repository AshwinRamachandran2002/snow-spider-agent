WITH ca_pubs AS (
    SELECT
        "publication_number",
        "publication_date",
        "inventor",
        ARRAY_SIZE("inventor") AS inventor_cnt
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "country_code" = 'CA'
      AND "inventor" IS NOT NULL
      AND ARRAY_SIZE("inventor") > 0
      AND "publication_date" >= 19600101
      AND "publication_date" < 20210101
),
periodized AS (
    SELECT
        "publication_number",
        inventor_cnt,
        /* derive 5-year interval start: 1960, 1965, …, 2020 */
        (FLOOR( (FLOOR("publication_date" / 10000) - 1960) / 5 ) * 5 + 1960) AS period_start
    FROM ca_pubs
)
SELECT
    TO_VARCHAR(period_start) || '-' || TO_VARCHAR(period_start + 4) AS "five_year_period",
    COUNT(*)                                                        AS "total_publications",
    ROUND(AVG(inventor_cnt), 4)                                     AS "avg_inventors_per_patent"
FROM periodized
GROUP BY period_start
ORDER BY period_start NULLS LAST;
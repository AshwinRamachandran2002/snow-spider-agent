WITH ca_patents AS (
    /* 1.  Count inventors on each Canadian patent publication               */
    SELECT
        p."publication_number",
        COUNT(*)                                           AS inventor_cnt,
        FLOOR(p."publication_date" / 10000)               AS pub_year
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN(input => PARSE_JSON(p."inventor")) f
    WHERE p."country_code"      = 'CA'
      AND p."publication_date" BETWEEN 19600101 AND 20201231
      AND p."inventor" IS NOT NULL
      AND ARRAY_SIZE(PARSE_JSON(p."inventor")) > 0
    GROUP BY
        p."publication_number",
        FLOOR(p."publication_date" / 10000)
)

SELECT
    /* 2.  Start year of the 5-year bucket (e.g., 1960, 1965, …, 2020) */
    1960 + 5 * FLOOR( (pub_year - 1960) / 5 )           AS period_start,
    /* 3.  Publications and average inventors (4-decimal precision)    */
    COUNT(*)                                            AS total_publications,
    ROUND(AVG(inventor_cnt), 4)                         AS avg_inventors_per_patent
FROM ca_patents
GROUP BY
    1960 + 5 * FLOOR( (pub_year - 1960) / 5 )
ORDER BY
    period_start;
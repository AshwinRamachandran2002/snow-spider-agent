WITH ca_publications AS (
    SELECT
        /* publication year */
        (p."publication_date" / 10000)::INT                                     AS pub_year,
        /* beginning of 5-year period (1960-1964, 1965-1969, …) */
        FLOOR(((p."publication_date" / 10000)::INT - 1960) / 5) * 5 + 1960      AS period_start,
        p."publication_number",
        COUNT(f.value)                                                          AS inventor_cnt
    FROM PATENTS.PATENTS.PUBLICATIONS p
         , LATERAL FLATTEN(INPUT => p."inventor") f
    WHERE p."country_code" = 'CA'
      AND (p."publication_date" / 10000) BETWEEN 1960 AND 2020                 -- 1960-2020 inclusive
    GROUP BY
        period_start,
        p."publication_number",
        (p."publication_date" / 10000)::INT
    HAVING COUNT(f.value) > 0                                                  -- keep only publications with ≥1 inventor
)

SELECT
    period_start                       AS "period_start_year",
    period_start + 4                   AS "period_end_year",
    COUNT(*)                           AS "publication_cnt",
    AVG(inventor_cnt)::DECIMAL(10,4)   AS "avg_inventor_cnt"
FROM ca_publications
GROUP BY period_start
ORDER BY period_start;
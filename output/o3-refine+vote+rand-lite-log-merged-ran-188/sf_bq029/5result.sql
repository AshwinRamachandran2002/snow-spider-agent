WITH ca_pubs AS (
    SELECT
        "publication_number",
        "publication_date",
        PARSE_JSON("inventor")                     AS inventor_json
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "country_code" = 'CA'
      AND "publication_date" BETWEEN 19600101 AND 20201231    -- 1960‑01‑01 to 2020‑12‑31
      AND "inventor" IS NOT NULL                              -- must have inventor data
),
valid_pubs AS (
    SELECT
        "publication_number",
        "publication_date",
        ARRAY_SIZE(inventor_json)                                       AS inventor_count,
        /* derive the 5‑year bucket start (1960‑1964, 1965‑1969, …) */
        FLOOR( ( FLOOR("publication_date" / 10000) - 1960 ) / 5 ) * 5  + 1960
                                                                        AS period_start_year
    FROM ca_pubs
    WHERE ARRAY_SIZE(inventor_json) > 0                                -- at least one inventor
)
SELECT
    TO_CHAR(period_start_year) || '-' || TO_CHAR(period_start_year + 4) AS "FIVE_YEAR_PERIOD",
    COUNT(*)                                                            AS "TOTAL_PUBLICATIONS",
    AVG(inventor_count)                                                 AS "AVG_INVENTORS_PER_PATENT"
FROM valid_pubs
GROUP BY period_start_year
ORDER BY period_start_year;
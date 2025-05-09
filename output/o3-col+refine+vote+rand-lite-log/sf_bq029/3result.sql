WITH ca_publications AS (
    /* 1)  Gather Canadian publications (1960-2020) and count their inventors      */
    SELECT
        p."publication_number",
        CAST(SUBSTR(p."publication_date"::STRING, 1, 4) AS INT)             AS "year",
        COUNT(f.value)                                                      AS "inventor_count"
    FROM  PATENTS.PATENTS.PUBLICATIONS p,
          LATERAL FLATTEN ( INPUT => p."inventor" ) f
    WHERE p."country_code" = 'CA'
      AND CAST(SUBSTR(p."publication_date"::STRING, 1, 4) AS INT)
          BETWEEN 1960 AND 2020                 -- restrict to requested span
    GROUP BY p."publication_number", p."publication_date"
    HAVING COUNT(f.value) > 0                   -- keep only patents with ≥1 inventor
)

SELECT
    /* 2)  Build the five-year bucket label (e.g. 1960-1964)                       */
    CONCAT(
        1960 + 5 * FLOOR( ("year" - 1960) / 5 ),
        '-',
        1960 + 5 * FLOOR( ("year" - 1960) / 5 ) + 4
    )                                                         AS "five_year_period",
    /* 3)  Aggregate counts and average inventors per patent                       */
    COUNT(DISTINCT "publication_number")                       AS "publication_count",
    ROUND(AVG("inventor_count"), 4)                            AS "avg_inventors_per_publication"
FROM   ca_publications
GROUP BY
    CONCAT(
        1960 + 5 * FLOOR( ("year" - 1960) / 5 ),
        '-',
        1960 + 5 * FLOOR( ("year" - 1960) / 5 ) + 4
    )
ORDER BY "five_year_period";
WITH ca_pubs AS (
    -- Canadian publications that have at least one inventor listed
    SELECT
        CAST(FLOOR("publication_date" / 10000) AS INT)             AS publication_year,   -- YYYY
        ARRAY_SIZE("inventor")                                     AS num_inventors
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "country_code" = 'CA'
      AND "publication_date" IS NOT NULL
      AND ARRAY_SIZE("inventor") > 0
      AND CAST(FLOOR("publication_date" / 10000) AS INT) BETWEEN 1960 AND 2020
),
periodized AS (
    -- Assign each publication to a 5‑year interval
    SELECT
        publication_year,
        num_inventors,
        (FLOOR((publication_year - 1960) / 5) * 5 + 1960) AS period_start
    FROM ca_pubs
)
SELECT
    CONCAT(period_start::STRING, '-', (period_start + 4)::STRING)      AS period,
    ROUND(AVG(num_inventors), 4)                                       AS avg_inventors_per_patent,
    COUNT(*)                                                           AS total_publications
FROM periodized
GROUP BY period_start
ORDER BY period_start;
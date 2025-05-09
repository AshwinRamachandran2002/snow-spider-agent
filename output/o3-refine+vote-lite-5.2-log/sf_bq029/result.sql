WITH ca_publications AS (   -- Canadian publications with at least one inventor, 1960‑2020
    SELECT
        TO_NUMBER(SUBSTR(TO_CHAR("publication_date"),1,4))      AS pub_year,
        ARRAY_SIZE("inventor")                                  AS inventor_cnt
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "country_code"      = 'CA'
      AND "publication_date" IS NOT NULL
      AND "publication_date" BETWEEN 19600101 AND 20201231
      AND "inventor" IS NOT NULL
      AND ARRAY_SIZE("inventor") > 0
),
periodized AS (            -- assign each record to a 5‑year period
    SELECT
        (5 * FLOOR((pub_year - 1960) / 5) + 1960)  AS start_year,
        inventor_cnt
    FROM ca_publications
    WHERE pub_year BETWEEN 1960 AND 2020
)
SELECT
    CONCAT(start_year::VARCHAR, '-', (start_year + 4)::VARCHAR)     AS "period",
    COUNT(*)                                                        AS "publication_count",
    ROUND(AVG(inventor_cnt), 4)                                     AS "avg_inventors_per_patent"
FROM periodized
GROUP BY start_year
ORDER BY start_year;
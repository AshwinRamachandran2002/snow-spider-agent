WITH ca_pubs AS (
    SELECT 
        "publication_number",
        "publication_date",
        ARRAY_SIZE("inventor") AS inventor_cnt,
        FLOOR("publication_date"/10000) AS pub_year        -- extract YYYY
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "country_code" = 'CA'
      AND "publication_date" BETWEEN 19600101 AND 20201231   -- 1960‑01‑01 to 2020‑12‑31
      AND ARRAY_SIZE("inventor") > 0                         -- at least one inventor
),
bucketed AS (
    SELECT
        CONCAT(
               (1960 + FLOOR( (pub_year - 1960) / 5 ) * 5 )::STRING,
               '-',
               (1960 + FLOOR( (pub_year - 1960) / 5 ) * 5 + 4)::STRING
        )  AS "five_year_period",
        inventor_cnt
    FROM ca_pubs
)
SELECT
    "five_year_period",
    ROUND(AVG(inventor_cnt), 4) AS "avg_inventors_per_patent",
    COUNT(*)                   AS "total_publications"
FROM bucketed
GROUP BY "five_year_period"
ORDER BY "five_year_period";
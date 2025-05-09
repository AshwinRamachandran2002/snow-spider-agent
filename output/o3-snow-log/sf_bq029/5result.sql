WITH ca_pubs AS (          -- 1. Canadian publications, 1960-2020, with ≥1 inventor
    SELECT
        FLOOR("publication_date" / 10000)        AS pub_year,          -- extract year
        ARRAY_SIZE("inventor")                   AS num_inventors
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "country_code" = 'CA'
      AND "publication_date" BETWEEN 19600101 AND 20201231
      AND "inventor" IS NOT NULL
      AND ARRAY_SIZE("inventor") > 0
),
bucketed AS (              -- 2. Assign each year to a 5-year bucket
    SELECT
        1960 + FLOOR((pub_year - 1960) / 5) * 5  AS period_start,      -- e.g. 1972 → 1970
        num_inventors
    FROM ca_pubs
    WHERE pub_year BETWEEN 1960 AND 2020
)
-- 3. Aggregate results per 5-year interval
SELECT
    TO_VARCHAR(period_start) || '-' || TO_VARCHAR(period_start + 4) AS "period",
    COUNT(*)                                                      AS "total_publications",
    ROUND(AVG(num_inventors), 4)                                  AS "avg_inventors_per_patent"
FROM bucketed
GROUP BY period_start
ORDER BY period_start;
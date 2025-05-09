WITH ca_publications AS (
    -- 1. Keep Canadian publications, published 1960-01-01 through 2020-12-31,
    --    that list at least one inventor
    SELECT
        "publication_number",
        "publication_date",
        ARRAY_SIZE("inventor")      AS inventor_cnt
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "country_code"    = 'CA'
      AND "publication_date" BETWEEN 19600101 AND 20201231
      AND "inventor" IS NOT NULL
      AND ARRAY_SIZE("inventor") > 0
),
year_bucket AS (
    -- 2. Derive publication year and 5-year bucket start (1960, 1965, … , 2020)
    SELECT
        "publication_number",
        inventor_cnt,
        FLOOR("publication_date"/10000)                              AS pub_year,
        1960 + 5*FLOOR( (FLOOR("publication_date"/10000) - 1960)/5 ) AS bucket_start
    FROM ca_publications
    WHERE FLOOR("publication_date"/10000) >= 1960        -- safety filter
      AND 1960 + 5*FLOOR( (FLOOR("publication_date"/10000) - 1960)/5 ) <= 2020
),
bucket_stats AS (
    -- 3. Aggregate per 5-year period
    SELECT
        bucket_start,
        COUNT(*)                       AS total_publications,
        AVG(inventor_cnt)              AS avg_inventors_per_patent
    FROM year_bucket
    GROUP BY bucket_start
)
-- 4. Present results
SELECT
    bucket_start || '-' || (bucket_start + 4)                AS "period",
    total_publications                                       AS "total_publications",
    ROUND(avg_inventors_per_patent, 4)                       AS "avg_inventors_per_patent"
FROM bucket_stats
ORDER BY bucket_start NULLS LAST;
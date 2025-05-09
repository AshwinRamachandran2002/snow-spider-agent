WITH ca_publications AS (
    SELECT
        FLOOR("publication_date" / 10000)::INT               AS pub_year,           -- extract year
        ARRAY_SIZE("inventor")                               AS inventor_cnt        -- number of inventors
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "country_code" = 'CA'                              -- Canadian publications only
      AND "publication_date" IS NOT NULL                    -- need a publication date
      AND ARRAY_SIZE("inventor") > 0                        -- at least one inventor listed
      AND FLOOR("publication_date" / 10000)::INT BETWEEN 1960 AND 2020   -- years 1960‑2020
)
SELECT
    CONCAT(interval_start::STRING, '-', (interval_start + 4)::STRING)    AS "five_year_period",
    AVG(inventor_cnt)                                                    AS "avg_inventors_per_patent",
    COUNT(*)                                                             AS "total_publications"
FROM (
    SELECT
        pub_year,
        inventor_cnt,
        (FLOOR((pub_year - 1960) / 5) * 5 + 1960)            AS interval_start   -- 5‑year bucket
    FROM ca_publications
) AS buckets
GROUP BY interval_start
ORDER BY interval_start;
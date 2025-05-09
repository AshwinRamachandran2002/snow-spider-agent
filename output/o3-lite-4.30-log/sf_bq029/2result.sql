WITH ca_publications AS (
    SELECT
        "publication_number",
        ARRAY_SIZE("inventor")               AS inventor_cnt,
        FLOOR("publication_date" / 10000)    AS pub_year
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "country_code" = 'CA'
      AND "publication_date" BETWEEN 19600101 AND 20201231
      AND ARRAY_SIZE("inventor") > 0
),
bucketed AS (
    SELECT
        "publication_number",
        inventor_cnt,
        (FLOOR((pub_year - 1960) / 5) * 5 + 1960) AS bucket_start_year
    FROM ca_publications
)
SELECT
    CONCAT(bucket_start_year, '-', bucket_start_year + 4)       AS five_year_period,
    ROUND(AVG(inventor_cnt), 4)                                 AS avg_inventors_per_patent,
    COUNT(DISTINCT "publication_number")                        AS total_patent_publications
FROM bucketed
GROUP BY bucket_start_year
ORDER BY bucket_start_year;
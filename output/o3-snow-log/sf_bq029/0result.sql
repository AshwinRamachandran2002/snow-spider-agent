WITH ca_pubs AS (
    SELECT
        "publication_number"                       AS publication_number,      -- give an unquoted alias
        ARRAY_SIZE("inventor")                     AS inventor_cnt,            -- # inventors
        FLOOR("publication_date" / 10000)          AS pub_year                 -- YYYY
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "country_code"      = 'CA'
      AND "publication_date" BETWEEN 19600101 AND 20201231
      AND "inventor"          IS NOT NULL
      AND ARRAY_SIZE("inventor") > 0
),
periodized AS (
    SELECT
        publication_number,
        inventor_cnt,
        FLOOR( (pub_year - 1960) / 5 )             AS period_idx               -- 0=1960-64, 1=1965-69, …
    FROM ca_pubs
)
SELECT
    TO_VARCHAR(1960 + period_idx*5) || '-' ||
    TO_VARCHAR(1960 + period_idx*5 + 4)            AS period,
    COUNT(*)                                       AS total_publications,
    ROUND(AVG(inventor_cnt), 4)                    AS avg_inventors_per_patent
FROM periodized
GROUP BY period_idx
ORDER BY period_idx;
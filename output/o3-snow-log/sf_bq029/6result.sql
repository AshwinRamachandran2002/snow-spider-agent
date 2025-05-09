WITH ca_publications AS (
    SELECT
        "publication_number",
        "publication_date",
        "inventor",
        -- extract calendar year from the YYYYMMDD numeric date
        YEAR(TO_DATE("publication_date"::STRING,'YYYYMMDD'))               AS pub_year,
        -- number of inventors in the JSON/VARIANT array
        ARRAY_SIZE("inventor")                                             AS inventor_cnt
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "country_code"      = 'CA'
      AND "publication_date"  IS NOT NULL
      AND "inventor"          IS NOT NULL
), filtered AS (
    SELECT
        *,
        -- determine the 5-year period start (e.g., 1960, 1965, ...)
        1960 + FLOOR( (pub_year - 1960) / 5 ) * 5                         AS period_start
    FROM ca_publications
    WHERE inventor_cnt > 0                 -- only keep publications having at least one inventor
      AND pub_year BETWEEN 1960 AND 2020   -- restrict to requested time span
)
SELECT
    CONCAT(period_start::STRING, '-', (period_start + 4)::STRING)         AS "five_year_period",
    COUNT(*)                                                              AS "patent_publication_count",
    ROUND(AVG(inventor_cnt), 4)                                           AS "avg_inventors_per_patent"
FROM filtered
GROUP BY period_start
ORDER BY period_start NULLS LAST;
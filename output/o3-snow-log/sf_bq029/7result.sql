WITH ca_publications AS (
    SELECT
        /* extract publication year (YYYY) from YYYYMMDD integer */
        ( "publication_date" / 10000 )::INT                                            AS pub_year,
        /* number of inventors listed for the publication */
        ARRAY_SIZE( PARSE_JSON("inventor") )                                           AS num_inventors
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "country_code"      = 'CA'
      AND "publication_date" IS NOT NULL
      AND "publication_date" BETWEEN 19600101 AND 20201231
      AND ARRAY_SIZE( PARSE_JSON("inventor") ) > 0          -- keep records with ≥1 inventor
),
periodized AS (
    SELECT
        /* 5-year bucket starting year (1960-1964, 1965-1969, …) */
        1960 + 5 * FLOOR( (pub_year - 1960) / 5 )             AS start_year,
        num_inventors
    FROM ca_publications
    WHERE pub_year BETWEEN 1960 AND 2020
)
SELECT
    CONCAT(start_year, '-', start_year + 4)                   AS "period",
    ROUND(AVG(num_inventors), 4)                              AS "avg_inventors_per_patent",
    COUNT(*)                                                  AS "total_publications"
FROM periodized
GROUP BY start_year
ORDER BY start_year;
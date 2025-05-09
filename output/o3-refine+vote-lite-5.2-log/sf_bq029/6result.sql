WITH ca_publications AS (
    SELECT
        "publication_number",
        "publication_date",
        /* number of inventors per patent (0 if NULL/empty) */
        COALESCE(ARRAY_SIZE("inventor"), 0) AS num_inventors
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE
        "country_code" = 'CA'
        AND "publication_date" BETWEEN 19600101 AND 20201231   -- 1960‑01‑01 … 2020‑12‑31
        AND COALESCE(ARRAY_SIZE("inventor"), 0) > 0            -- keep only patents with ≥1 inventor
),
periodized AS (
    SELECT
        /* start year of the 5‑year period */
        ( FLOOR( ( FLOOR("publication_date" / 10000) - 1960 ) / 5 ) * 5 ) + 1960 AS period_start,
        num_inventors
    FROM ca_publications
)
SELECT
    /* label for the 5‑year interval, e.g. 1960-1964 */
    CONCAT( TO_CHAR(period_start), '-', TO_CHAR(period_start + 4) )       AS "period",
    ROUND(AVG(num_inventors), 4)                                          AS "average_inventors_per_patent",
    COUNT(*)                                                              AS "total_publications"
FROM periodized
GROUP BY period_start
ORDER BY period_start;
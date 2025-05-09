WITH ca_publications AS (
    SELECT
        FLOOR("publication_date" / 10000)                          AS "pub_year",     -- extract year
        ARRAY_SIZE("inventor")                                     AS "num_inventors" -- number of inventors
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "country_code" = 'CA'                          -- Canadian publications
      AND "publication_date" BETWEEN 19600101 AND 20201231
      AND "inventor" IS NOT NULL
      AND ARRAY_SIZE("inventor") > 0                    -- at least one inventor
),
periodised AS (
    SELECT
        1960 + FLOOR(("pub_year" - 1960) / 5) * 5        AS "start_year", -- 5‑year bucket start
        "num_inventors"
    FROM ca_publications
)
SELECT
    CONCAT("start_year", '-', "start_year" + 4)                 AS "period",
    ROUND(AVG("num_inventors"), 4)                              AS "avg_inventors_per_patent",
    COUNT(*)                                                    AS "total_publications"
FROM periodised
GROUP BY "start_year"
ORDER BY "start_year";
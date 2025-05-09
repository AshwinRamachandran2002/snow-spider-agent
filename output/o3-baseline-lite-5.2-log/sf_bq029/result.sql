WITH ca_publications AS (
    SELECT
        "publication_number",
        "publication_date",
        NVL(ARRAY_SIZE("inventor"), 0)            AS inventor_cnt              -- number of inventors
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "country_code" = 'CA'                                          -- Canadian publications
      AND NVL(ARRAY_SIZE("inventor"), 0) > 0                             -- keep only patents with ≥1 inventor
      AND "publication_date" IS NOT NULL
),
dated AS (
    SELECT
        "publication_number",
        inventor_cnt,
        FLOOR("publication_date" / 10000)            AS pub_year          -- extract YYYY from YYYYMMDD
    FROM ca_publications
    WHERE FLOOR("publication_date" / 10000) BETWEEN 1960 AND 2020        -- limit to 1960‑2020
),
bucketed AS (
    SELECT
        "publication_number",
        inventor_cnt,
        1960 + 5 * FLOOR((pub_year - 1960) / 5)      AS start_year        -- 5‑year bucket start
    FROM dated
)
SELECT
    TO_VARCHAR(start_year) || '-' || TO_VARCHAR(start_year + 4)  AS "5_YEAR_PERIOD",
    COUNT(*)                                                    AS "TOTAL_PUBLICATIONS",
    ROUND(AVG(inventor_cnt), 4)                                 AS "AVG_INVENTORS_PER_PATENT"
FROM bucketed
GROUP BY start_year
ORDER BY start_year;
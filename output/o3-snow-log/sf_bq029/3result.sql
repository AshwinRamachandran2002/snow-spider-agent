WITH ca_pubs AS (
    SELECT
        "publication_number",
        "publication_date",
        "inventor",
        FLOOR("publication_date" / 10000)                                 AS pub_year,          -- fast year‐extraction
        ARRAY_SIZE(
            COALESCE(
                TRY_PARSE_JSON("inventor"),       -- if stored as a JSON-encoded string
                "inventor"                        -- if already VARIANT/ARRAY
            )
        )                                                             AS inventor_cnt
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "country_code" = 'CA'
      AND "publication_date" BETWEEN 19600101 AND 20201231            -- 1960-01-01 … 2020-12-31
      AND "inventor" IS NOT NULL                                       -- must list inventors
),
bucketed AS (
    SELECT
        "publication_number",
        inventor_cnt,
        pub_year,
        1960 + FLOOR( (pub_year - 1960) / 5 ) * 5                      AS interval_start
    FROM ca_pubs
    WHERE inventor_cnt > 0                                             -- keep only patents with ≥1 inventor
)
SELECT
    TO_VARCHAR(interval_start) || '-' || TO_VARCHAR(interval_start + 4) AS "five_year_period",
    ROUND(AVG(inventor_cnt), 4)                                         AS "avg_inventors_per_patent",
    COUNT(*)                                                            AS "total_publications"
FROM bucketed
GROUP BY interval_start
ORDER BY interval_start NULLS LAST;
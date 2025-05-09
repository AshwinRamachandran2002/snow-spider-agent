WITH filtered_pubs AS (               -- patents granted in 2010‑2018
    SELECT
        "publication_number",
        "citation"
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "grant_date" BETWEEN 20100101 AND 20181231
),

sea_citations AS (                    -- one row per SEA‑category citation
    SELECT
        fp."publication_number"
    FROM filtered_pubs  fp,
         LATERAL FLATTEN(input => fp."citation") f
    WHERE UPPER(f.value:"category"::string) = 'SEA'
)

SELECT
    fp."publication_number",
    COALESCE(COUNT(sc."publication_number"), 0) AS "sea_backward_citation_count"
FROM filtered_pubs  fp
LEFT JOIN sea_citations sc
       ON fp."publication_number" = sc."publication_number"
GROUP BY fp."publication_number"
ORDER BY "sea_backward_citation_count" DESC NULLS LAST,
         fp."publication_number";
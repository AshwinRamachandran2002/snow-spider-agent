WITH base_publications AS (   -- patents granted 2010‑2018
    SELECT DISTINCT
           "publication_number"
    FROM   PATENTS.PATENTS.PUBLICATIONS
    WHERE  "grant_date" BETWEEN 20100101 AND 20181231
),

sea_citation_counts AS (      -- count SEA‑category backward citations
    SELECT
        p."publication_number",
        COUNT(*) AS sea_citation_count
    FROM   PATENTS.PATENTS.PUBLICATIONS p,
           LATERAL FLATTEN(input => p."citation") f
    WHERE  p."grant_date" BETWEEN 20100101 AND 20181231
      AND  f.value:"category"::string = 'SEA'
    GROUP BY p."publication_number"
)

SELECT
       b."publication_number",
       COALESCE(s.sea_citation_count, 0) AS "sea_backward_citation_count"
FROM   base_publications b
LEFT   JOIN sea_citation_counts s
       ON b."publication_number" = s."publication_number"
ORDER BY b."publication_number";
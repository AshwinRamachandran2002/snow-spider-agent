WITH granted_patents AS (
    -- All patents granted between 2010-01-01 and 2018-12-31
    SELECT
        "publication_number"
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "grant_date" BETWEEN 20100101 AND 20181231
),
sea_backward_citations AS (
    -- SEA-category backward citations for the same grant window
    SELECT
        p."publication_number",
        COUNT(*) AS "sea_citation_cnt"
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN(input => p."citation") c
    WHERE p."grant_date" BETWEEN 20100101 AND 20181231
      AND LOWER(c.value:"category"::STRING) LIKE 'sea%'
    GROUP BY p."publication_number"
)
SELECT
    g."publication_number",
    COALESCE(s."sea_citation_cnt", 0) AS "sea_citation_cnt"
FROM granted_patents g
LEFT JOIN sea_backward_citations s
       ON g."publication_number" = s."publication_number";
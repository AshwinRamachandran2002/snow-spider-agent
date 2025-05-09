WITH cited_patents AS (      /* Utility patents granted in 2010 with valid filing dates */
    SELECT 
        "publication_number"            AS "cited_pub",
        "filing_date"                   AS "cited_filing_date"
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "application_kind" = 'U'
      AND "grant_date" BETWEEN 20100101 AND 20101231
      AND TRY_TO_DATE("filing_date"::STRING, 'YYYYMMDD') IS NOT NULL
),
forward_cites AS (           /* Forward citations occurring ≤10 years after filing */
    SELECT 
        c."cited_pub",
        p."application_number"          AS "citing_app_no"
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN(input => p."citation") f
         JOIN cited_patents c
           ON f.value::VARIANT:"publication_number"::STRING = c."cited_pub"
    WHERE p."application_number" IS NOT NULL
      AND TRY_TO_DATE(p."filing_date"::STRING,'YYYYMMDD') IS NOT NULL
      AND TRY_TO_DATE(p."filing_date"::STRING,'YYYYMMDD')
          BETWEEN TRY_TO_DATE(c."cited_filing_date"::STRING,'YYYYMMDD')
              AND DATEADD(year, 10,
                           TRY_TO_DATE(c."cited_filing_date"::STRING,'YYYYMMDD'))
),
citation_counts AS (         /* Distinct forward-citation counts per cited patent */
    SELECT 
        "cited_pub",
        COUNT(DISTINCT "citing_app_no") AS "forward_cite_count"
    FROM forward_cites
    GROUP BY "cited_pub"
)
SELECT 
    COUNT(*) AS "num_utility_patents_granted_2010_with_one_forward_citation"
FROM citation_counts
WHERE "forward_cite_count" = 1;
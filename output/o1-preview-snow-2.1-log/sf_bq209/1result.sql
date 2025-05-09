WITH utility_patents AS (
    SELECT 
        "publication_number", 
        TRY_TO_DATE(TO_VARCHAR("filing_date"), 'YYYYMMDD') AS "filing_date", 
        TRY_TO_DATE(TO_VARCHAR("grant_date"), 'YYYYMMDD') AS "grant_date"
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE TRY_TO_DATE(TO_VARCHAR("grant_date"), 'YYYYMMDD') BETWEEN '2010-01-01' AND '2010-12-31'
      AND "application_kind" = 'A'
      AND "filing_date" IS NOT NULL AND "filing_date" != 0
      AND "grant_date" IS NOT NULL AND "grant_date" != 0
),
forward_citations AS (
    SELECT 
        t1."publication_number" AS "cited_publication_number",
        COUNT(DISTINCT t2."publication_number") AS "num_forward_citations"
    FROM utility_patents t1
    JOIN PATENTS.PATENTS.PUBLICATIONS t2
        ON t2."filing_date" IS NOT NULL AND t2."filing_date" != 0
    , LATERAL FLATTEN(input => t2."citation") f
    WHERE f.value::VARIANT:"publication_number"::STRING = t1."publication_number"
      AND TRY_TO_DATE(TO_VARCHAR(t2."filing_date"), 'YYYYMMDD') BETWEEN t1."filing_date" 
      AND DATEADD('day', 3650, t1."filing_date")
    GROUP BY t1."publication_number"
),
patent_counts AS (
    SELECT 
        t1."publication_number",
        COALESCE(fc."num_forward_citations", 0) AS "num_forward_citations"
    FROM utility_patents t1
    LEFT JOIN forward_citations fc
        ON t1."publication_number" = fc."cited_publication_number"
)
SELECT COUNT(*) AS number_of_patents_with_exactly_one_forward_citation
FROM patent_counts
WHERE "num_forward_citations" = 1;
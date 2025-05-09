WITH citation_links AS (
    /* every (citing-application → cited-publication) pair */
    SELECT  
        c_pub."application_number"                 AS "citing_app",
        c_pub."filing_date"                        AS "citing_filing_date",
        f.value:"publication_number"::STRING       AS "cited_pub"
    FROM PATENTS.PATENTS.PUBLICATIONS               c_pub,
         LATERAL FLATTEN (INPUT => c_pub."citation") f
    WHERE c_pub."citation" IS NOT NULL
      AND c_pub."citation" <> '[]'
), 
target_patents AS (
    /* utility (“A”) patents granted during calendar-year 2010 */
    SELECT  
        "publication_number"   AS "target_pub",
        "filing_date"          AS "target_filing_date"
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "application_kind" = 'A'
      AND "grant_date" BETWEEN 20100101 AND 20101231
)
SELECT  COUNT(*) AS "num_utility_patents_with_exactly_one_forward_citation"
FROM (
    SELECT  t."target_pub"
    FROM    target_patents   t
    LEFT JOIN citation_links cl
           ON  cl."cited_pub" = t."target_pub"
          AND cl."citing_filing_date"
              BETWEEN t."target_filing_date" 
                  AND t."target_filing_date" + 100000  -- ≈10-year window
    GROUP BY t."target_pub"
    HAVING COUNT(DISTINCT cl."citing_app") = 1
) q;
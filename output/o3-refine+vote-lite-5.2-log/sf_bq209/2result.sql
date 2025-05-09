WITH patents_granted_2010 AS (      -- utility patents granted in 2010
    SELECT
        "publication_number"          AS cited_pub_no ,
        "application_number"          AS cited_app_no ,
        "filing_date"                 AS cited_filing_dt
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "application_kind" = 'A'                    -- utility‑patent kind
      AND "grant_date" BETWEEN 20100101 AND 20101231  -- granted in 2010
      AND "filing_date" IS NOT NULL
),

-- every (citing → cited) relation coming from the “citation” array
citations_expanded AS (
    SELECT
        PUB."application_number"                      AS citing_app_no ,
        PUB."filing_date"                             AS citing_filing_dt ,
        FLT.VALUE:"publication_number"::STRING        AS cited_pub_no
    FROM PATENTS.PATENTS.PUBLICATIONS  AS PUB ,
         LATERAL FLATTEN( INPUT => PUB."citation") AS FLT
    WHERE FLT.VALUE:"publication_number" IS NOT NULL
      AND PUB."filing_date" IS NOT NULL
),

-- count distinct forward citations occurring ≤ 10 years after the cited patent’s filing date
forward_counts AS (
    SELECT
        P.cited_pub_no ,
        COUNT( DISTINCT C.citing_app_no ) AS fwd_cite_cnt
    FROM patents_granted_2010       P
    LEFT JOIN citations_expanded    C
           ON  C.cited_pub_no = P.cited_pub_no
           AND TO_DATE( C.citing_filing_dt::STRING , 'YYYYMMDD')
               <= DATEADD( YEAR , 10 ,
                           TO_DATE( P.cited_filing_dt::STRING , 'YYYYMMDD') )
    GROUP BY P.cited_pub_no
)

SELECT
    COUNT(*) AS num_utility_patents_granted_2010_with_exactly_one_forward_citation
FROM forward_counts
WHERE fwd_cite_cnt = 1;
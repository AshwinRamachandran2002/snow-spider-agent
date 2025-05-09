WITH base_patents AS (   -- utility patents granted in 2010
    SELECT 
        LOWER("publication_number")                     AS base_pub_no ,
        TO_DATE("filing_date"::STRING,'YYYYMMDD')       AS base_filing_dt
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "application_kind" = 'A'                          -- utility patents
      AND "grant_date" BETWEEN 20100101 AND 20101231        -- granted in 2010
      AND "filing_date" IS NOT NULL
), 

citing_publications AS (  -- every citing publication with its cited patents
    SELECT  
        "application_number"                               AS citing_app_no ,
        TO_DATE("filing_date"::STRING,'YYYYMMDD')           AS citing_filing_dt ,
        LOWER(f.value:"publication_number"::STRING)         AS cited_pub_no
    FROM PATENTS.PATENTS.PUBLICATIONS p
         ,LATERAL FLATTEN(INPUT => p."citation") f          -- one row per cited patent
    WHERE f.value:"publication_number" IS NOT NULL
      AND p."filing_date" IS NOT NULL
),

forward_citations AS (    -- keep only forward citations within 10-year window
    SELECT DISTINCT 
           b.base_pub_no ,
           c.citing_app_no
    FROM base_patents  b
    JOIN citing_publications c
         ON c.cited_pub_no      = b.base_pub_no                        -- cites the base patent
        AND c.citing_filing_dt  >= b.base_filing_dt                    -- forward (not backward)
        AND c.citing_filing_dt  <  DATEADD(year,10,b.base_filing_dt)   -- within 10 years
),

citation_counts AS (      -- count distinct citing applications per base patent
    SELECT 
        base_pub_no ,
        COUNT(DISTINCT citing_app_no) AS fwd_cite_cnt
    FROM forward_citations
    GROUP BY base_pub_no
)

SELECT COUNT(*) AS num_patents_with_exactly_one_forward_citation
FROM   citation_counts
WHERE  fwd_cite_cnt = 1;
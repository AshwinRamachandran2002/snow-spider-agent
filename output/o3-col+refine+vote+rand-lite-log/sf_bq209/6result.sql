/*  Count of utility patents granted in 2010 that have
    exactly ONE distinct forward-citing application
    within 10 years of their own filing date            */

WITH citing_publications AS (          -- all (citing → cited) links
    SELECT
        cp."application_number"               AS "citing_app",
        cp."filing_date"                      AS "citing_filing_date",
        f.value:"publication_number"::STRING  AS "cited_pub"
    FROM PATENTS.PATENTS.PUBLICATIONS  cp
         , LATERAL FLATTEN ( input => cp."citation" ) f
    WHERE cp."citation" IS NOT NULL
      AND cp."citation" <> '[]'
      AND f.value:"publication_number" IS NOT NULL
)

SELECT
    COUNT(*) AS "num_utility_patents_granted_2010_with_exactly_one_forward_citation_within_10_years"
FROM (
    SELECT
        base."publication_number",
        COUNT( DISTINCT cit."citing_app" ) AS "fwd_cite_cnt"
    FROM PATENTS.PATENTS.PUBLICATIONS  base
    LEFT JOIN citing_publications  cit
           ON cit."cited_pub" = base."publication_number"
          AND cit."citing_filing_date" >  base."filing_date"             -- after own filing
          AND cit."citing_filing_date" <= base."filing_date" + 100000    -- ≤ 10 years later
    WHERE base."application_kind" = 'A'                   -- utility patents
      AND base."grant_date" BETWEEN 20100101 AND 20101231 -- granted in 2010
    GROUP BY base."publication_number"
    HAVING COUNT( DISTINCT cit."citing_app" ) = 1         -- exactly one forward citation
) AS q;
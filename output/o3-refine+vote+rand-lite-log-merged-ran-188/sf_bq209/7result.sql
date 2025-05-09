/*  Count utility patents (application_kind = 'A')
    – granted during calendar year 2010
    – that received exactly ONE distinct forward‑citation
      (measured as a distinct citing application number)
      within the 10‑year period beginning on the patent’s own
      filing date.                                              */

WITH patents_2010 AS (          -- candidate set
    SELECT  "publication_number",
            "application_number",
            "filing_date",
            TO_DATE("filing_date"::STRING,'YYYYMMDD') AS filing_dt
    FROM    PATENTS.PATENTS.PUBLICATIONS
    WHERE   "application_kind" = 'A'                     -- utility patents
      AND   "grant_date" BETWEEN 20100101 AND 20101231   -- granted in 2010
      AND   "filing_date"  > 0
), forward_citations AS (       -- all forward‑citations in 10‑yr window
    SELECT  p."publication_number"            AS cited_pub,
            c."application_number"            AS citing_app
    FROM    patents_2010               p
    JOIN    PATENTS.PATENTS.PUBLICATIONS  c           -- potential citers
              ON TRUE
          , LATERAL FLATTEN(INPUT => c."citation") cit
    WHERE   (
              cit.VALUE:"publication_number"::STRING = p."publication_number"
           OR cit.VALUE:"application_number" ::STRING = p."application_number"
            )
      AND   c."application_number" IS NOT NULL
      AND   c."filing_date"  > 0
      AND   TO_DATE(c."filing_date"::STRING,'YYYYMMDD')
                BETWEEN p.filing_dt
                    AND DATEADD(YEAR,10,p.filing_dt)    -- 10‑year window
), citation_counts AS (        -- number of distinct citers per patent
    SELECT  cited_pub,
            COUNT(DISTINCT citing_app) AS fwd_cnt
    FROM    forward_citations
    GROUP BY cited_pub
)
SELECT  COUNT(*) AS patents_with_exactly_one_forward_citation
FROM    patents_2010  p
LEFT JOIN citation_counts cc
       ON p."publication_number" = cc.cited_pub
WHERE   COALESCE(cc.fwd_cnt,0) = 1;
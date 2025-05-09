WITH granted_2010 AS (          -- 1. 2010-granted U.S. utility patents
    SELECT
        "publication_number",
        "filing_date"
    FROM "PATENTS"."PATENTS"."PUBLICATIONS"
    WHERE "grant_date" BETWEEN 20100101 AND 20101231
      AND "kind_code" ILIKE 'B%'        -- granted utility kind codes (“B…”) 
      AND "filing_date" > 0             -- keep records with valid filing date
), 

citing_flat AS (               -- 2. explode every patent’s citation list
    SELECT
        p."application_number"                     AS citing_app,
        p."filing_date"                            AS citing_file,
        f.VALUE:"publication_number"::STRING       AS cited_pub
    FROM "PATENTS"."PATENTS"."PUBLICATIONS"  p,
         LATERAL FLATTEN(input => p."citation") f
    WHERE p."filing_date" > 0
), 

one_citation_only AS (         -- 3. patents with exactly one distinct forward citation in ≤10 yrs
    SELECT g."publication_number"
    FROM   granted_2010 g
    JOIN   citing_flat cf
           ON cf.cited_pub = g."publication_number"
    WHERE  DATEDIFF(
              'day',
              TO_DATE(g."filing_date"::STRING,'YYYYMMDD'),
              TO_DATE(cf.citing_file::STRING,'YYYYMMDD')
           ) BETWEEN 0 AND 3650          -- within 10 years
    GROUP BY g."publication_number"
    HAVING COUNT(DISTINCT cf.citing_app) = 1
)

SELECT COUNT(*) AS "n_utility_patents_granted_2010_with_one_forward_citation_in_10yrs"
FROM one_citation_only;
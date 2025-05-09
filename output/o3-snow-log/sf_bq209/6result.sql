/* ---------------------------------------------------------------
   1)  Select all U.S. utility patents that were granted in 2010
   2)  Unnest every publication’s backward-citation list so we can
       reverse it and treat it as a forward-citation record
   3)  Count, for each 2010-granted patent, how many distinct
       citing application numbers filed within ten years after
       the patent’s own filing date cite it
   4)  Return the number of patents that have exactly one such
       forward citation
-----------------------------------------------------------------*/
WITH base AS (   -- U.S. utility patents granted in 2010
    SELECT
        "publication_number",
        "application_number",
        "filing_date"
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "country_code"   = 'US'
      AND "application_kind" = 'A'        -- utility (non-design) patent
      AND "grant_date" BETWEEN 20100101 AND 20101231
),
citations_raw AS (   -- each backward citation, turned into a forward-citation record
    SELECT
        p."application_number"                    AS citing_app,
        p."filing_date"                           AS citing_filing_date,
        f.value:"application_number"::string      AS cited_app,
        f.value:"publication_number"::string      AS cited_pub
    FROM PATENTS.PATENTS.PUBLICATIONS  p,
         LATERAL FLATTEN ( input => p."citation" ) f
    WHERE f.value IS NOT NULL
),
forward_counts AS (  -- count distinct citing apps within 10-year window
    SELECT
        b."application_number"        AS base_app,
        COUNT ( DISTINCT cr.citing_app ) AS forward_cnt
    FROM base b
    JOIN citations_raw cr
      ON  cr.cited_app = b."application_number"
       OR cr.cited_pub = b."publication_number"
    WHERE cr.citing_filing_date IS NOT NULL
      AND cr.citing_filing_date >= b."filing_date"
      AND cr.citing_filing_date
          <= TO_NUMBER(
                 TO_CHAR(
                     DATEADD( year , 10 ,
                              TO_DATE( b."filing_date"::string , 'YYYYMMDD' )
                            ),
                 'YYYYMMDD')
             )
    GROUP BY b."application_number"
),
base_with_counts AS (   -- attach forward-citation counts to every 2010 grant
    SELECT
        b."application_number",
        COALESCE( fc.forward_cnt , 0 ) AS forward_cnt
    FROM base b
    LEFT JOIN forward_counts fc
           ON fc.base_app = b."application_number"
)
SELECT COUNT(*) AS num_utility_patents
FROM   base_with_counts
WHERE  forward_cnt = 1;
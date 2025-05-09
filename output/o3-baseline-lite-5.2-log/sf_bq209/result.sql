/*  Number of utility patents granted in 2010
    that received exactly ONE forward citation
    (distinct citing application numbers) within
    ten years of their own filing date              */

WITH candidate_patents AS (      -- utility patents granted in 2010
    SELECT
        "publication_number"           AS cited_pub_no ,
        "application_number"           AS cited_app_no ,
        "filing_date"                  AS cited_filing_num ,
        TO_DATE( LPAD("filing_date",8,'0') , 'YYYYMMDD')  AS cited_filing_dt
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "application_kind" = 'U'                         -- utility patents
      AND "grant_date" BETWEEN 20100101 AND 20101231       -- granted in 2010
      AND "filing_date" IS NOT NULL
),                                                         
flattened_citations AS (     -- every citation of every publication
    SELECT
        TO_VARIANT(f.value):"publication_number"::STRING   AS cited_pub_no ,
        p."application_number"                            AS citing_app_no ,
        p."publication_date"                              AS citing_pubdate_num
    FROM PATENTS.PATENTS.PUBLICATIONS  p,
         LATERAL FLATTEN( INPUT => p."citation" ) f
    WHERE f.value:"publication_number" IS NOT NULL
          AND p."application_number" IS NOT NULL
          AND p."publication_date"   IS NOT NULL
),
forward_cites AS (          -- citations that fall in the 10‑year window
    SELECT
        c.cited_pub_no ,
        COUNT( DISTINCT fc.citing_app_no )  AS forward_cite_cnt
    FROM candidate_patents  c
    JOIN flattened_citations fc
          ON fc.cited_pub_no = c.cited_pub_no
         AND TO_DATE( LPAD(fc.citing_pubdate_num,8,'0') , 'YYYYMMDD')
                 <= DATEADD( year , 10 , c.cited_filing_dt )
    GROUP BY c.cited_pub_no
)
SELECT COUNT(*)  AS num_util_patents_with_exactly_one_forward_cite
FROM candidate_patents  cp
LEFT JOIN forward_cites fc
       ON fc.cited_pub_no = cp.cited_pub_no
WHERE COALESCE( fc.forward_cite_cnt , 0 ) = 1;
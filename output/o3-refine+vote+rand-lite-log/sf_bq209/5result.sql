/* Utility patents granted in 2010 that received exactly one forward
   citation within 10 years of their own filing date                  */
WITH target AS (  -- 1. 2010‑granted U.S. utility patents
    SELECT
        "publication_number"                       AS pub_num,
        "application_number"                       AS app_num,
        TO_DATE(TO_CHAR("filing_date"),'YYYYMMDD') AS filing_dt
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "application_kind" = 'A'          -- utility patent
      AND "country_code"   = 'US'
      AND "grant_date" BETWEEN 20100101 AND 20101231
      AND "filing_date" IS NOT NULL
      AND "filing_date" > 0                 -- exclude 0 / invalid dates
),
citations AS (    -- 2. forward citations within 10‑year window
    SELECT
        t.pub_num                    AS cited_pub,
        c."application_number"       AS citing_app
    FROM PATENTS.PATENTS.PUBLICATIONS c,
         LATERAL FLATTEN(input => c."citation") f,
         target t
    WHERE f.value:"publication_number"::STRING = t.pub_num
      AND c."filing_date" IS NOT NULL
      AND c."filing_date" > 0
      AND TO_DATE(TO_CHAR(c."filing_date"),'YYYYMMDD')
            BETWEEN t.filing_dt
                AND DATEADD(YEAR,10,t.filing_dt)
),
forward_counts AS ( -- 3. distinct citing apps per patent
    SELECT
        cited_pub,
        COUNT(DISTINCT citing_app) AS fw_cite_cnt
    FROM citations
    GROUP BY cited_pub
)
-- 4. final answer
SELECT
    COUNT(*) AS patents_with_exactly_one_forward_citation
FROM forward_counts
WHERE fw_cite_cnt = 1;
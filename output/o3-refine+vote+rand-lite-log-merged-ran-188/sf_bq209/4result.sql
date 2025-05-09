WITH target AS (   -- 1) US utility patents granted in 2010
    SELECT
        "publication_number",
        "application_number",
        "filing_date",
        TO_DATE(TO_CHAR("filing_date"),'YYYYMMDD') AS filing_dt
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "country_code" = 'US'
      AND "kind_code" LIKE 'B%'          -- granted (e.g., B1, B2 …)
      AND "grant_date" BETWEEN 20100101 AND 20101231
      AND "application_kind" = 'A'       -- utility patent application
      AND "filing_date" IS NOT NULL
),

citing_map AS (   -- 2) every (cited‑publication ↔ citing‑application) pair
    SELECT
        c.value:"publication_number"::STRING      AS cited_pub,
        p."application_number"                    AS citing_app,
        p."filing_date"                           AS citing_filing_date
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN(INPUT => p."citation") c
    WHERE p."application_number" IS NOT NULL
      AND p."filing_date"      IS NOT NULL
),

forward_counts AS (   -- 3) forward citations within 10‑year window
    SELECT
        t."publication_number"                     AS target_pub,
        COUNT(DISTINCT cm.citing_app)              AS fwd_cnt
    FROM target t
    JOIN citing_map cm
          ON cm.cited_pub = t."publication_number"
    WHERE
          TO_DATE(TO_CHAR(cm.citing_filing_date),'YYYYMMDD') 
          BETWEEN t.filing_dt 
              AND DATEADD(year, 10, t.filing_dt)       -- ≤10 years after filing
    GROUP BY t."publication_number"
)

-- 4) number of 2010‑granted utility patents having exactly ONE forward citation
SELECT COUNT(*) AS num_patents_with_one_forward_citation
FROM forward_counts
WHERE fwd_cnt = 1;
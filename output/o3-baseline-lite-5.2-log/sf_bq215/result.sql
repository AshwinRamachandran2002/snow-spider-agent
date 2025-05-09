WITH focal AS (          -- All U.S. B2‑granted patents between 2015‑2018
    SELECT  p."publication_number"
    FROM    PATENTS.PATENTS.PUBLICATIONS  p
    WHERE   p."country_code" = 'US'
      AND   p."kind_code"   LIKE 'B2'
      AND   p."grant_date" BETWEEN 20150101 AND 20181231
),

back_citations AS (      -- Flatten the backward‑citation list of each focal patent
    SELECT  f."publication_number"                         AS focal_pub,
            c.value:"publication_number"::string           AS cited_pub
    FROM    focal                     f
    JOIN    PATENTS.PATENTS.PUBLICATIONS p
           ON p."publication_number" = f."publication_number"
    ,       LATERAL FLATTEN( INPUT => p."citation")  c
    WHERE   c.value:"publication_number" IS NOT NULL
),

cited_ipc4 AS (          -- Extract 4‑digit IPC codes of all cited patents
    SELECT  bc.focal_pub,
            SUBSTR(ip.value:"code"::string, 1, 4)          AS ipc4
    FROM    back_citations             bc
    JOIN    PATENTS.PATENTS.PUBLICATIONS cp
           ON cp."publication_number" = bc.cited_pub
    ,       LATERAL FLATTEN( INPUT => cp."ipc")  ip
    WHERE   ip.value:"code" IS NOT NULL
),

ipc_count AS (           -- Occurrence count of every IPC‑4 within each focal patent
    SELECT  focal_pub,
            ipc4,
            COUNT(*)                                          AS cnt
    FROM    cited_ipc4
    GROUP BY focal_pub, ipc4
),

agg AS (                 -- Aggregate sums needed for the originality formula
    SELECT  focal_pub,
            SUM(cnt)                               AS total_cnt,
            SUM(cnt * cnt)                         AS sum_sq
    FROM    ipc_count
    GROUP BY focal_pub
    HAVING  SUM(cnt) > 0
),

originality AS (         -- Compute originality = 1 − Σ(cnt_k²) / (Σ cnt_k)²
    SELECT  focal_pub,
            1 - (sum_sq::FLOAT / (total_cnt * total_cnt))     AS originality_score
    FROM    agg
)

SELECT  focal_pub                  AS "publication_number",
        originality_score          AS "originality_score"
FROM    originality
ORDER BY originality_score DESC NULLS LAST,
         "publication_number"     ASC
LIMIT 1;
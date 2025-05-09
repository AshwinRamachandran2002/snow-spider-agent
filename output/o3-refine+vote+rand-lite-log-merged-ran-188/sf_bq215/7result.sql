/*  Highest‑originality U.S. patents granted (kind‑code B2) between 2015‑2018 */
WITH focal AS (               -- candidate patents
    SELECT  "publication_number"  AS focal_pub ,
            "citation"            AS citation_v
    FROM    PATENTS.PATENTS.PUBLICATIONS
    WHERE   "country_code" = 'US'
      AND   "kind_code"    = 'B2'
      AND   "grant_date" BETWEEN 20150101 AND 20181231
),

cited AS (                     -- backward citations of each focal patent
    SELECT  f.focal_pub ,
            TRIM(cit.value:"publication_number"::STRING) AS cited_pub
    FROM    focal f ,
            LATERAL FLATTEN ( INPUT => f.citation_v ) cit
    WHERE   cit.value:"publication_number" IS NOT NULL
),

cited_ipc AS (                 -- 4‑digit IPC codes of cited patents
    SELECT  c.focal_pub ,
            SUBSTR(ipc_f.value:"code"::STRING , 1 , 4) AS ipc4
    FROM    cited c
    JOIN    PATENTS.PATENTS.PUBLICATIONS p
           ON p."publication_number" = c.cited_pub
    ,       LATERAL FLATTEN ( INPUT => p."ipc" ) ipc_f
    WHERE   ipc_f.value:"code" IS NOT NULL
),

cnt AS (                       -- occurrences per IPC4 for every focal patent
    SELECT  focal_pub ,
            ipc4 ,
            COUNT(*) AS n_k
    FROM    cited_ipc
    GROUP BY focal_pub , ipc4
),

orig AS (                      -- originality score of every focal patent
    SELECT  focal_pub ,
            1 - SUM( n_k * n_k ) / POWER( SUM(n_k) , 2 ) AS originality
    FROM    cnt
    GROUP BY focal_pub
    HAVING  SUM(n_k) > 0          -- exclude patents without IPC info
)

SELECT  focal_pub AS "publication_number" ,
        originality
FROM    orig
ORDER BY originality DESC NULLS LAST , focal_pub
LIMIT 1;
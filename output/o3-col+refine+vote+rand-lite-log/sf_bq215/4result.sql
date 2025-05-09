WITH citations AS (  -- backward citation links for eligible US-B2 patents
    SELECT  
        p."publication_number"                                   AS "citing_pub",
        f.value:"publication_number"::STRING                     AS "cited_pub"
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN(input => p."citation") f
    WHERE p."country_code" = 'US'
      AND p."kind_code"   = 'B2'
      AND p."grant_date" BETWEEN 20150101 AND 20181231
      AND f.value:"publication_number" IS NOT NULL
), ipc_counts AS (      -- count occurrences of each 4-digit IPC among cited docs
    SELECT  
        c."citing_pub",
        SUBSTR(ipc_item.value:"code"::STRING, 1, 4)  AS "ipc4",
        COUNT(*)                                     AS "n_k"
    FROM citations c
    JOIN PATENTS.PATENTS.PUBLICATIONS cited
         ON cited."publication_number" = c."cited_pub"
         AND cited."ipc" IS NOT NULL
         , LATERAL FLATTEN(input => cited."ipc") ipc_item
    GROUP BY  
        c."citing_pub",
        SUBSTR(ipc_item.value:"code"::STRING, 1, 4)
), stats AS (           -- totals needed for originality
    SELECT  
        "citing_pub"                          AS "publication_number",
        SUM("n_k")                            AS "n_total",
        SUM(POWER("n_k", 2))                  AS "sum_sq"
    FROM ipc_counts
    GROUP BY "citing_pub"
    HAVING SUM("n_k") > 0
)
SELECT  
    "publication_number",
    1 - ("sum_sq" / POWER("n_total", 2))      AS "originality_score"
FROM stats
ORDER BY "originality_score" DESC NULLS LAST
LIMIT 1;
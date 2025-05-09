WITH focal_pubs AS (   -- 1) US-B2 patents granted 2015-2018
    SELECT
        pub."publication_number"
    FROM PATENTS.PATENTS.PUBLICATIONS  pub
    WHERE pub."country_code" = 'US'
      AND pub."kind_code"   = 'B2'
      AND pub."grant_date" BETWEEN 20150101 AND 20181231
),
backward_ipc AS (      -- 2) 4–digit IPC codes of every backward-cited patent
    SELECT
        fp."publication_number"                         AS focal_pub ,
        SUBSTR(ipc.value:"code"::string , 1 , 4)        AS ipc4
    FROM focal_pubs            fp
    JOIN PATENTS.PATENTS.PUBLICATIONS fp_pub
         ON fp_pub."publication_number" = fp."publication_number"
    ,    LATERAL FLATTEN ( INPUT => fp_pub."citation")   cit      -- backward citations
    JOIN PATENTS.PATENTS.PUBLICATIONS          cited_pub
         ON cited_pub."publication_number" = cit.value:"publication_number"::string
    ,    LATERAL FLATTEN ( INPUT => cited_pub."ipc")     ipc      -- IPCs of cited patent
    WHERE ipc.value:"code" IS NOT NULL
),
ipc_counts AS (        -- 3) occurrences of every 4-digit IPC among cited patents
    SELECT
        focal_pub ,
        ipc4 ,
        COUNT(*)                              AS cnt
    FROM backward_ipc
    GROUP BY focal_pub , ipc4
),
orig_calc AS (         -- 4) parts needed for originality
    SELECT
        focal_pub ,
        SUM(cnt)                        AS total_cnt ,
        SUM(POWER(cnt,2))               AS sum_sq_cnt
    FROM ipc_counts
    GROUP BY focal_pub
),
orig_score AS (        -- 5) Trajtenberg originality score
    SELECT
        focal_pub ,
        1 - (sum_sq_cnt::FLOAT / (total_cnt*total_cnt)) AS originality
    FROM orig_calc
    WHERE total_cnt > 0
)
SELECT
    focal_pub            AS "publication_number" ,
    originality
FROM orig_score
ORDER BY originality DESC NULLS LAST
LIMIT 1;
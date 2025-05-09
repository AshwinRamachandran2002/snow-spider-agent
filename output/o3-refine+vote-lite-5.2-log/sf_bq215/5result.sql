WITH candidate AS (   -- US patents granted 2015‑2018 with kind code B2
    SELECT
        pub."publication_number"           AS pub_num,
        pub."citation"                     AS cit_variant
    FROM PATENTS.PATENTS.PUBLICATIONS pub
    WHERE pub."country_code" = 'US'
      AND pub."kind_code"   = 'B2'
      AND pub."grant_date" BETWEEN 20150101 AND 20181231
), cited_list AS (     -- backward‑citation publication numbers
    SELECT
        c.pub_num,
        cited.value:"publication_number"::TEXT AS cited_pub_num
    FROM candidate c,
         LATERAL FLATTEN(input => c.cit_variant) AS cited
    WHERE cited.value:"publication_number" IS NOT NULL
), cited_ipc AS (      -- 4‑digit IPC codes of the cited patents
    SELECT
        cl.pub_num,
        SUBSTR(ipc_item.value:"code"::TEXT, 1, 4) AS ipc4
    FROM cited_list cl
    JOIN PATENTS.PATENTS.PUBLICATIONS cited_pub
         ON cited_pub."publication_number" = cl.cited_pub_num
    ,    LATERAL FLATTEN(input => cited_pub."ipc") AS ipc_item
    WHERE ipc_item.value:"code" IS NOT NULL
), counts AS (         -- counts per IPC4
    SELECT
        pub_num,
        ipc4,
        COUNT(*) AS cnt
    FROM cited_ipc
    GROUP BY pub_num, ipc4
), totals AS (         -- totals and sum of squared counts
    SELECT
        pub_num,
        SUM(cnt)           AS total_citations,
        SUM(cnt*cnt)       AS sum_sq
    FROM counts
    GROUP BY pub_num
), originality AS (    -- Trajtenberg originality score
    SELECT
        pub_num,
        1 - (sum_sq / POWER(total_citations, 2)) AS originality_score
    FROM totals
    WHERE total_citations > 0
)
SELECT
    pub_num AS "publication_number"
FROM originality
ORDER BY originality_score DESC NULLS LAST, pub_num
LIMIT 1;
WITH
/* 1.  US patents granted (B2) between 2015-2018 */
target_pubs AS (
    SELECT
        "publication_number",
        "citation"
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "country_code" = 'US'
      AND "kind_code"   = 'B2'
      AND "grant_date" BETWEEN 20150101 AND 20181231
),
/* 2.  Flatten backward-citation list to the cited publication numbers          */
back_citations AS (
    SELECT
        tp."publication_number"           AS citing_pub,
        cit.value:"publication_number"::STRING AS cited_pub
    FROM target_pubs tp,
         LATERAL FLATTEN(input => tp."citation") cit
    WHERE cit.value:"publication_number" IS NOT NULL
),
/* 3.  For every cited publication, take all its IPC codes (4-digit level)      */
cited_ipc AS (
    SELECT
        bc.citing_pub,
        SUBSTR(ipc_it.value:"code"::STRING, 1, 4) AS ipc4
    FROM back_citations bc
    JOIN PATENTS.PATENTS.PUBLICATIONS cp
      ON cp."publication_number" = bc.cited_pub
    ,   LATERAL FLATTEN(input => cp."ipc") ipc_it
    WHERE ipc_it.value:"code" IS NOT NULL
),
/* 4.  Count occurrences of every IPC4 in the backward citations of each patent */
ipc_counts AS (
    SELECT
        citing_pub,
        ipc4,
        COUNT(*) AS cnt
    FROM cited_ipc
    GROUP BY citing_pub, ipc4
),
/* 5.  Aggregate to build originality inputs: Σcnt² and (Σcnt)²                 */
agg AS (
    SELECT
        citing_pub,
        SUM(cnt * cnt)         AS sum_sq,
        SUM(cnt)               AS tot
    FROM ipc_counts
    GROUP BY citing_pub
    HAVING SUM(cnt) > 0
),
/* 6.  Originality = 1 − Σcnt² / (Σcnt)²                                        */
orig_scores AS (
    SELECT
        citing_pub  AS publication_number,
        1 - (CAST(sum_sq AS FLOAT) / CAST(tot * tot AS FLOAT)) AS originality
    FROM agg
)
/* 7.  Return the patent with the highest originality                           */
SELECT
    publication_number,
    originality
FROM orig_scores
ORDER BY originality DESC NULLS LAST
LIMIT 1;
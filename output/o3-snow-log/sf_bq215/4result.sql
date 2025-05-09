/* -------------------------------------------------------------
   1.  Select all U.S. patents (kind code B2) granted 2015-2018
   2.  Get their backward-citation publication numbers
   3.  For every cited publication extract all 4-digit IPC codes
   4.  Count occurrences of every IPC4 within each focal patent
   5.  Compute ORIGINALITY  = 1 − Σ_k(cnt_k²) / (Σ_k cnt_k)²
   6.  Return the patent with the highest originality score
   -------------------------------------------------------------*/
WITH candidate_pubs AS (
    SELECT "publication_number"
    FROM   PATENTS.PATENTS.PUBLICATIONS
    WHERE  "country_code" = 'US'
      AND  "kind_code"    LIKE '%B2'
      AND  "grant_date" BETWEEN 20150101 AND 20181231
), backward_citations AS (
    SELECT
        cp."publication_number"          AS pub,
        cit.value:"publication_number"::string AS cited_pub
    FROM   PATENTS.PATENTS.PUBLICATIONS cp
           INNER JOIN candidate_pubs c
                   ON cp."publication_number" = c."publication_number",
           LATERAL FLATTEN(INPUT => cp."citation") cit
    WHERE  cit.value:"publication_number" IS NOT NULL
), cited_ipc4 AS (
    SELECT
        bc.pub,
        SUBSTR(ip.value:"code"::string, 1, 4) AS ipc4
    FROM   backward_citations bc
           JOIN PATENTS.PATENTS.PUBLICATIONS p2
                 ON p2."publication_number" = bc.cited_pub,
           LATERAL FLATTEN(INPUT => p2."ipc") ip
    WHERE  ip.value:"code" IS NOT NULL
), ipc_counts AS (
    SELECT
        pub,
        ipc4,
        COUNT(*) AS cnt
    FROM   cited_ipc4
    GROUP  BY pub, ipc4
), originality_scores AS (
    SELECT
        pub                                    AS "publication_number",
        1 - SUM(cnt*cnt)::FLOAT / POWER(SUM(cnt), 2) AS originality
    FROM   ipc_counts
    GROUP  BY pub
    HAVING SUM(cnt) > 0
)
SELECT  "publication_number",
        originality
FROM    originality_scores
ORDER BY originality DESC NULLS LAST
LIMIT 1;
WITH  -- 1) candidate US‑B2 patents granted 2015‑2018
citing AS (
    SELECT
        "publication_number",
        "citation"
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "country_code" = 'US'
      AND "kind_code"   = 'B2'
      AND "grant_date" BETWEEN 20150101 AND 20181231
      AND "citation" IS NOT NULL
),
-- 2) flatten their backward‑citation list
citations AS (
    SELECT
        c."publication_number"                    AS citing_pub,
        cit.value:"publication_number"::STRING    AS cited_pub
    FROM citing c,
         LATERAL FLATTEN(input => c."citation") cit
    WHERE cit.value:"publication_number" IS NOT NULL
),
-- 3) obtain all IPC codes of the cited publications
cited_ipc AS (
    SELECT
        cp."publication_number"                                   AS cited_pub,
        SUBSTR(ipc_u.value:"code"::STRING,1,4)                    AS ipc4
    FROM PATENTS.PATENTS.PUBLICATIONS cp,
         LATERAL FLATTEN(input => cp."ipc") ipc_u
    WHERE cp."publication_number" IN (SELECT DISTINCT cited_pub FROM citations)
          AND ipc_u.value:"code" IS NOT NULL
),
-- 4) choose the most‑frequent 4‑digit IPC per cited publication
primary_ipc AS (
    SELECT cited_pub, ipc4
    FROM (
        SELECT
            cited_pub,
            ipc4,
            COUNT(*)                                      AS cnt,
            ROW_NUMBER() OVER (PARTITION BY cited_pub
                               ORDER BY COUNT(*) DESC, ipc4) AS rn
        FROM cited_ipc
        GROUP BY cited_pub, ipc4
    ) x
    WHERE rn = 1
),
-- 5) map each citation to its primary IPC4
citation_classes AS (
    SELECT
        ci.citing_pub,
        pi.ipc4
    FROM citations ci
    JOIN primary_ipc pi
      ON ci.cited_pub = pi.cited_pub
),
-- 6) count occurrences of every IPC4 per citing patent
class_counts AS (
    SELECT
        citing_pub,
        ipc4,
        COUNT(*) AS occ
    FROM citation_classes
    GROUP BY citing_pub, ipc4
),
-- 7) compute originality components
orig AS (
    SELECT
        citing_pub,
        SUM(occ)               AS total_occ,
        SUM(occ*occ)           AS sum_sq_occ
    FROM class_counts
    GROUP BY citing_pub
),
-- 8) calculate originality score
orig_score AS (
    SELECT
        citing_pub                         AS publication_number,
        1 - (sum_sq_occ::FLOAT / (total_occ*total_occ)) AS originality
    FROM orig
    WHERE total_occ > 0
)
-- 9) patent with highest originality
SELECT publication_number
FROM orig_score
ORDER BY originality DESC NULLS LAST, publication_number
LIMIT 1;
WITH citing_rel AS (
    SELECT
        p."publication_number"                             AS "citing_pub",
        cit.value:"publication_number"::STRING             AS "cited_pub"
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN(input => p."citation") AS cit
    JOIN PATENTS.PATENTS.PUBLICATIONS c
      ON c."publication_number" = cit.value:"publication_number"::STRING
     AND c."ipc" IS NOT NULL
    WHERE p."country_code" = 'US'
      AND p."kind_code" ILIKE '%B2'
      AND p."grant_date" BETWEEN 20150101 AND 20181231
      AND cit.value:"publication_number" IS NOT NULL
), ipc_counts AS (
    SELECT
        cr."citing_pub",
        SUBSTR(ipc_u.value:"code"::STRING, 1, 4)           AS "ipc4",
        COUNT(*)                                           AS cnt
    FROM citing_rel cr
    JOIN PATENTS.PATENTS.PUBLICATIONS cited
      ON cited."publication_number" = cr."cited_pub",
         LATERAL FLATTEN(input => cited."ipc") AS ipc_u
    GROUP BY cr."citing_pub", SUBSTR(ipc_u.value:"code"::STRING, 1, 4)
), originality AS (
    SELECT
        "citing_pub"                                       AS "publication_number",
        1 - (SUM(POWER(cnt, 2))::FLOAT / POWER(SUM(cnt),2)) AS originality_score
    FROM ipc_counts
    GROUP BY "citing_pub"
)
SELECT
    "publication_number" AS patent_id,
    ROUND(originality_score, 4) AS originality_score
FROM originality
ORDER BY originality_score DESC NULLS LAST, "publication_number"
LIMIT 1;
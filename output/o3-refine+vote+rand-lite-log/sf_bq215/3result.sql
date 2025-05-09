WITH focal AS (
    SELECT "publication_number"
    FROM "PATENTS"."PATENTS"."PUBLICATIONS"
    WHERE "country_code" = 'US'
      AND "kind_code"   = 'B2'
      AND "grant_date" BETWEEN 20150101 AND 20181231
),
citations AS (   /* backward citations of each focal patent */
    SELECT
        f."publication_number"                       AS "focal_pub",
        c.value:"publication_number"::string         AS "cited_pub"
    FROM focal f
    JOIN "PATENTS"."PATENTS"."PUBLICATIONS" p
          ON p."publication_number" = f."publication_number"
    ,    LATERAL FLATTEN(input => p."citation") c
    WHERE c.value:"publication_number" IS NOT NULL
),
cited_ipc AS (   /* 4–digit IPC codes of cited patents */
    SELECT
        cit."focal_pub",
        SUBSTR(ip.value:"code"::string, 1, 4) AS "ipc4"
    FROM citations cit
    JOIN "PATENTS"."PATENTS"."PUBLICATIONS" cp
          ON cp."publication_number" = cit."cited_pub"
    ,    LATERAL FLATTEN(input => cp."ipc") ip
    WHERE ip.value:"code" IS NOT NULL
),
counts AS (      /* occurrences per IPC4 */
    SELECT
        "focal_pub",
        "ipc4",
        COUNT(*) AS n
    FROM cited_ipc
    GROUP BY "focal_pub", "ipc4"
),
totals AS (      /* total occurrences per patent */
    SELECT
        "focal_pub",
        SUM(n) AS total_n
    FROM counts
    GROUP BY "focal_pub"
),
originality AS ( /* originality = 1 - Σ(p_k^2) */
    SELECT
        c."focal_pub" AS "publication_number",
        1 - SUM(POWER(c.n, 2)) / POWER(t.total_n, 2) AS originality
    FROM counts  c
    JOIN totals  t ON t."focal_pub" = c."focal_pub"
    GROUP BY c."focal_pub", t.total_n
    HAVING t.total_n > 0
)
SELECT "publication_number", originality
FROM originality
ORDER BY originality DESC NULLS LAST, "publication_number"
LIMIT 1;
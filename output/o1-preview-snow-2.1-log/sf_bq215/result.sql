WITH citation_ipc AS (
    SELECT
        t."publication_number",
        SUBSTR(ipc_cited.value:"code"::STRING, 1, 4) AS "ipc_class"
    FROM PATENTS.PATENTS.PUBLICATIONS t
    CROSS JOIN LATERAL FLATTEN(input => t."citation") c
    JOIN PATENTS.PATENTS.PUBLICATIONS cited ON c.value:"publication_number"::STRING = cited."publication_number"
    CROSS JOIN LATERAL FLATTEN(input => cited."ipc") ipc_cited
    WHERE t."country_code" = 'US'
      AND t."kind_code" = 'B2'
      AND t."grant_date" BETWEEN 20150101 AND 20181231
),
counts AS (
    SELECT
        "publication_number",
        "ipc_class",
        COUNT(*) AS n_ik
    FROM citation_ipc
    GROUP BY "publication_number", "ipc_class"
),
total_counts AS (
    SELECT
        "publication_number",
        SUM(n_ik) AS n_i
    FROM counts
    GROUP BY "publication_number"
),
originality_calc AS (
    SELECT
        c."publication_number",
        ROUND(1 - SUM(POWER(c.n_ik * 1.0 / t.n_i, 2)), 4) AS "originality_score"
    FROM counts c
    JOIN total_counts t ON c."publication_number" = t."publication_number"
    GROUP BY c."publication_number"
)
SELECT "publication_number"
FROM originality_calc
ORDER BY "originality_score" DESC NULLS LAST
LIMIT 1;
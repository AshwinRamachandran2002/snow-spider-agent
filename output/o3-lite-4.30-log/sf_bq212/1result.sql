WITH ipc4_counts AS (
    SELECT
        t."publication_number",
        SUBSTR(f.value:"code"::STRING, 1, 4) AS "ipc4",
        COUNT(*) AS "cnt"
    FROM PATENTS.PATENTS.PUBLICATIONS t,
         LATERAL FLATTEN(input => t."ipc") f
    WHERE t."country_code"     = 'US'
      AND t."kind_code"        = 'B2'
      AND t."application_kind" = 'A'
      AND t."grant_date" BETWEEN 20220601 AND 20220930
      AND f.value:"code" IS NOT NULL
    GROUP BY t."publication_number", "ipc4"
), ipc4_ranked AS (
    SELECT
        "publication_number",
        "ipc4",
        ROW_NUMBER() OVER (
            PARTITION BY "publication_number"
            ORDER BY "cnt" DESC, "ipc4"
        ) AS rn
    FROM ipc4_counts
), ipc4_per_patent AS (
    SELECT "publication_number", "ipc4"
    FROM ipc4_ranked
    WHERE rn = 1
), ipc4_frequent AS (
    SELECT "ipc4"
    FROM ipc4_per_patent
    GROUP BY "ipc4"
    HAVING COUNT(*) >= 10
)
SELECT
    p."publication_number",
    p."ipc4"
FROM ipc4_per_patent p
JOIN ipc4_frequent f
  ON p."ipc4" = f."ipc4"
ORDER BY p."publication_number", p."ipc4";
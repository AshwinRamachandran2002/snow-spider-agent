WITH ipc_counts AS (
    SELECT
        SUBSTR(f.value:"code"::STRING, 1, 4) AS "ipc4",
        COUNT(*) AS "code_count"
    FROM PATENTS.PATENTS.PUBLICATIONS t,
         LATERAL FLATTEN(INPUT => t."ipc") f
    WHERE t."country_code" = 'US'
      AND t."kind_code" = 'B2'
      AND t."application_kind" = 'A'
      AND t."grant_date" BETWEEN 20220601 AND 20220831
    GROUP BY 1
)
SELECT
    "ipc4",
    "code_count"
FROM ipc_counts
ORDER BY "code_count" DESC NULLS LAST, "ipc4"
LIMIT 1;
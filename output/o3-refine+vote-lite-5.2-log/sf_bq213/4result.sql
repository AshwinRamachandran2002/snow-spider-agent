WITH US_B2_PATENTS AS (
    SELECT
        p."publication_number",
        FLATTEN_VALUE.value:"code"::STRING AS "IPC_CODE"
    FROM PATENTS.PATENTS.PUBLICATIONS AS p,
         LATERAL FLATTEN(input => p."ipc") AS FLATTEN_VALUE
    WHERE p."country_code" = 'US'
      AND p."kind_code" = 'B2'
      AND p."application_kind" = 'A'
      AND p."grant_date" BETWEEN 20220601 AND 20220831
)
SELECT
    SUBSTR("IPC_CODE", 1, 4) AS "IPC4",
    COUNT(DISTINCT "publication_number") AS "PATENT_COUNT"
FROM US_B2_PATENTS
WHERE "IPC_CODE" IS NOT NULL
GROUP BY "IPC4"
ORDER BY "PATENT_COUNT" DESC NULLS LAST, "IPC4"
LIMIT 1;
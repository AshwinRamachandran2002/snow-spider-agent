WITH PatentIPCCounts AS (
    SELECT t."publication_number",
           SUBSTR(ipc_u.value:"code"::STRING, 0, 4) AS ipc4,
           COUNT(*) OVER (PARTITION BY t."publication_number", SUBSTR(ipc_u.value:"code"::STRING, 0, 4)) AS ipc4_count
    FROM PATENTS.PATENTS.PUBLICATIONS t, LATERAL FLATTEN(input => t."ipc") ipc_u
    WHERE t."kind_code" = 'B2'
      AND t."publication_date" BETWEEN 20220601 AND 20220930
      AND t."country_code" = 'US'
),
PatentIPC4Max AS (
    SELECT DISTINCT "publication_number",
           FIRST_VALUE(ipc4) OVER (PARTITION BY "publication_number" ORDER BY ipc4_count DESC NULLS LAST, ipc4 ASC) AS ipc4
    FROM PatentIPCCounts
),
FrequentIPC4 AS (
    SELECT ipc4
    FROM PatentIPC4Max
    GROUP BY ipc4
    HAVING COUNT(*) >= 10
)
SELECT p."publication_number", p.ipc4
FROM PatentIPC4Max p
WHERE p.ipc4 IN (SELECT ipc4 FROM FrequentIPC4)
ORDER BY p."publication_number"
WITH ipc_codes AS (
    SELECT DISTINCT
        p."publication_number",
        SUBSTR(ipc_item.value:"code"::STRING, 1, 4) AS ipc4
    FROM PATENTS.PATENTS.PUBLICATIONS AS p,
         LATERAL FLATTEN(input => p."ipc") AS ipc_item
    WHERE p."country_code" = 'US'
      AND p."kind_code" = 'B2'
      AND p."application_kind" = 'A'
      AND p."grant_date" BETWEEN 20220601 AND 20220831
)
SELECT
    ipc4            AS ipc_code,
    COUNT(*)        AS patent_count
FROM ipc_codes
GROUP BY ipc4
ORDER BY patent_count DESC NULLS LAST, ipc_code
LIMIT 1;
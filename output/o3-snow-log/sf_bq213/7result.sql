WITH flat_ipc AS (
    SELECT
        p."publication_number",
        SUBSTR(f.value:"code"::STRING, 1, 4) AS "ipc4"
    FROM PATENTS.PATENTS.PUBLICATIONS AS p,
         LATERAL FLATTEN(input => p."ipc") AS f
    WHERE p."country_code" = 'US'
      AND p."kind_code" = 'B2'
      AND p."grant_date" BETWEEN 20220601 AND 20220831
)
SELECT
    "ipc4",
    COUNT(DISTINCT "publication_number") AS "num_patents"
FROM flat_ipc
GROUP BY "ipc4"
ORDER BY "num_patents" DESC NULLS LAST
LIMIT 1;
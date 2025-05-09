WITH filtered_pubs AS (
    SELECT 
        "publication_number",
        "ipc"
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "country_code" = 'US'
      AND "kind_code" = 'B2'
      AND "grant_date" BETWEEN 20220601 AND 20220831
)
SELECT 
    SUBSTR(ipc_item.value:"code"::STRING, 1, 4) AS "ipc4",
    COUNT(DISTINCT fp."publication_number")       AS "patent_count"
FROM filtered_pubs fp,
     LATERAL FLATTEN(input => fp."ipc") AS ipc_item
WHERE SUBSTR(ipc_item.value:"code"::STRING, 1, 4) IS NOT NULL
GROUP BY "ipc4"
ORDER BY "patent_count" DESC NULLS LAST
LIMIT 1;
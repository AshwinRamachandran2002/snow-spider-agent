WITH "US_B2_2022" AS (
    SELECT 
        p."publication_number",
        p."ipc"
    FROM PATENTS.PATENTS.PUBLICATIONS p
    WHERE p."country_code" = 'US'
      AND p."kind_code"   = 'B2'          -- granted US utility patents
      AND p."application_kind" = 'A'      -- exclude designs, provisionals, etc.
      AND p."grant_date" BETWEEN 20220601 AND 20220831   -- June‑Aug 2022
)

SELECT 
    SUBSTR(ipc_item.value:"code"::STRING, 1, 4) AS "ipc4",
    COUNT(*)                                      AS "code_count"
FROM "US_B2_2022",
     LATERAL FLATTEN(input => "US_B2_2022"."ipc") ipc_item
WHERE SUBSTR(ipc_item.value:"code"::STRING, 1, 4) IS NOT NULL
GROUP BY "ipc4"
ORDER BY "code_count" DESC NULLS LAST, "ipc4"
LIMIT 1;
SELECT
    SUBSTR(ipc_u.value:"code"::string, 1, 4) AS "IPC4",
    COUNT(DISTINCT p."publication_number")   AS "PATENT_COUNT"
FROM
    PATENTS.PATENTS.PUBLICATIONS AS p,
    LATERAL FLATTEN(INPUT => p."ipc") AS ipc_u
WHERE
    p."country_code"       = 'US'   -- U.S. patents
    AND p."kind_code"      = 'B2'   -- Granted publications
    AND p."application_kind" = 'A'  -- Utility patents
    AND p."grant_date" BETWEEN 20220601 AND 20220831  -- Jun–Aug 2022
    AND ipc_u.value:"code" IS NOT NULL
GROUP BY
    "IPC4"
ORDER BY
    "PATENT_COUNT" DESC NULLS LAST
LIMIT 1;
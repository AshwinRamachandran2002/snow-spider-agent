SELECT
    t."ipc4",
    t."cnt"
FROM (
    SELECT
        SUBSTR(ipc_f.value:"code"::STRING, 1, 4) AS "ipc4",
        COUNT(*) AS "cnt"
    FROM PATENTS.PATENTS.PUBLICATIONS AS p,
         LATERAL FLATTEN(input => p."ipc") AS ipc_f
    WHERE p."country_code"      = 'US'
      AND p."kind_code"         = 'B2'      -- utility‑patent grant
      AND p."application_kind"  = 'A'       -- patent (utility)
      AND p."grant_date" BETWEEN 20220601   -- 1 Jun 2022
                          AND 20220831       -- 31 Aug 2022
    GROUP BY SUBSTR(ipc_f.value:"code"::STRING, 1, 4)
) t
ORDER BY t."cnt" DESC NULLS LAST, t."ipc4"
LIMIT 1;
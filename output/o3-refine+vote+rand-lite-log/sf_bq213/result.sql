SELECT
    ipc4
FROM (
    SELECT
        SUBSTR(f.value:"code"::string, 1, 4) AS ipc4,
        COUNT(*) AS cnt
    FROM PATENTS.PATENTS.PUBLICATIONS AS p,
         LATERAL FLATTEN(INPUT => p."ipc") AS f
    WHERE p."country_code"      = 'US'
      AND p."kind_code"         = 'B2'
      AND p."application_kind"  = 'A'
      AND p."grant_date" BETWEEN 20220601 AND 20220831
      AND f.value:"code" IS NOT NULL
    GROUP BY ipc4
) AS t
ORDER BY
    cnt DESC NULLS LAST,
    ipc4
LIMIT 1;
-- Most common 4-digit IPC code among U.S. B2 utility patents granted Jun–Aug 2022
SELECT
    ipc4,
    COUNT(DISTINCT publication_number) AS pub_count
FROM (
    SELECT
        t."publication_number"                                   AS publication_number,
        SUBSTR(f.value:"code"::STRING, 1, 4)                     AS ipc4
    FROM PATENTS.PATENTS.PUBLICATIONS AS t,
         LATERAL FLATTEN(input => t."ipc") AS f
    WHERE t."country_code"     = 'US'
      AND t."kind_code"        = 'B2'
      AND t."application_kind" = 'A'
      AND t."grant_date" BETWEEN 20220601 AND 20220831
) AS sub
GROUP BY ipc4
ORDER BY pub_count DESC NULLS LAST
LIMIT 1;
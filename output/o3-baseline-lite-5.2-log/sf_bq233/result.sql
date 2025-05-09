WITH RELEVANT AS (  -- only .py / .r files + their contents
    SELECT
        f."path",
        c."content"
    FROM
        GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES   AS f
    JOIN
        GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS AS c
            ON f."id" = c."id"
    WHERE
        LOWER(f."path") LIKE '%.py'
        OR LOWER(f."path") LIKE '%.r'
),
LINES AS (          -- split every file into single lines
    SELECT
        r."path",
        SPLIT(r."content", '\n')    AS lines_arr
    FROM RELEVANT AS r
),
LINE AS (           -- one row per line
    SELECT
        l."path",
        f.value               AS line_txt
    FROM LINES AS l,
         LATERAL FLATTEN(input => l.lines_arr) AS f
),
EXTRACTED AS (      -- pull out imported / required module names
    SELECT
        CASE WHEN LOWER("path") LIKE '%.py' THEN 'Python' ELSE 'R' END  AS lang,
        COALESCE(
            /* Python  :  import xxxx                -> group 1 */
            REGEXP_SUBSTR(line_txt, '^\\s*import\\s+([A-Za-z0-9_]+)', 1, 1, 'e', 1),
            /* Python  :  from xxxx import yyy       -> group 1 */
            REGEXP_SUBSTR(line_txt, '^\\s*from\\s+([A-Za-z0-9_.]+)\\s+import', 1, 1, 'e', 1),
            /* R       :  library(xxxx)              -> group 1 */
            REGEXP_SUBSTR(line_txt, '\\blibrary\\s*\\(\\s*([A-Za-z0-9_.]+)\\s*\\)', 1, 1, 'e', 1)
        )                                               AS module_name
    FROM LINE
),
MODULES AS (        -- discard lines without a hit
    SELECT
        lang,
        module_name
    FROM EXTRACTED
    WHERE module_name IS NOT NULL
)
SELECT
    lang          AS "language",
    module_name   AS "module",
    COUNT(*)      AS "occurrences"
FROM MODULES
GROUP BY
    lang, module_name
ORDER BY
    lang,
    "occurrences" DESC NULLS LAST,
    "module";
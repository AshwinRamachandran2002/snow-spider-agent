WITH file_lines AS (   -- break every file into individual lines
    SELECT  c."id",
            TRIM(line.value) AS "line"
    FROM    GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS AS c,
            LATERAL SPLIT_TO_TABLE(c."content", '\n') AS line
), candidate_lines AS ( -- keep only lines that belong to multi-line import blocks
    SELECT  "line"
    FROM    file_lines
    WHERE   "line" LIKE 'import (%'      -- opening  line  e.g.  import (
        OR  "line" LIKE '%")'            -- closing  line  e.g.  )"
        OR  "line" LIKE '"%";%'          -- pkg line that ends with semicolon
        OR  "line" LIKE '"%"%'           -- pkg line that just has the quotes
), extracted_pkgs AS (  -- pull the text that is inside the double quotes
    SELECT  REGEXP_SUBSTR("line", '"([^"]+)"', 1, 1, 'e') AS "pkg"
    FROM    candidate_lines
)
SELECT  REPLACE("pkg", '"', '')          AS "package_name",
        COUNT(*)                         AS "occurrences"
FROM    extracted_pkgs
WHERE   "pkg" IS NOT NULL                -- ignore lines without a quoted package
GROUP BY "package_name"
ORDER BY "occurrences" DESC NULLS LAST
LIMIT  10;
/* Top-10 most frequent package names found inside multi-line
   Go-style  import ( ... )  blocks. */
WITH import_blocks AS (                                                  -- 1. grab full blocks
    SELECT REGEXP_SUBSTR("content",
                         'import \\([\\s\\S]*?\\)',                      -- dot-all
                         1, 1, 'e')     AS import_block
    FROM   GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS
    WHERE  "content" ILIKE '%import (%'
),
lines AS (                                                               -- 2. split into lines
    SELECT TRIM(s.VALUE) AS line
    FROM   import_blocks ib,
           LATERAL SPLIT_TO_TABLE(ib.import_block, '\n') s
    WHERE  ib.import_block IS NOT NULL
),
packages AS (                                                            -- 3. clean candidates
    SELECT REGEXP_REPLACE(
             SPLIT_PART(line, '--', 1),                                  -- drop “-- …” comments
             '[\\s"]', ''                                               -- remove spaces / quotes
           ) AS package
    FROM   lines
    WHERE  line LIKE '"%'                                                -- keep quoted lines
)
SELECT   package           AS "package_name",
         COUNT(*)          AS "frequency"
FROM     packages
WHERE    package IS NOT NULL
  AND    package <> ''
GROUP BY package
ORDER BY "frequency" DESC NULLS LAST
LIMIT 10;
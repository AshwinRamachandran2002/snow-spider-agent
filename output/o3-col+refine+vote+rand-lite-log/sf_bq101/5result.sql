/* Top-10 most frequently imported Java package names */
WITH java_files AS (                       -- Java source + body
  SELECT
    f."id",
    c."content"
  FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES    f
  JOIN GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS c
        ON f."id" = c."id"
  WHERE f."path" ILIKE '%.java'
),

import_lines AS (                          -- extract package part of import statements
  SELECT
    /* strip trailing .*   or   last .Class → keep only package segment */
    CASE
      WHEN raw_import LIKE '%.*'
           THEN REGEXP_REPLACE(raw_import, '\\.\\*$', '')
      ELSE REGEXP_REPLACE(raw_import,
                           '\\.[A-Za-z_][A-Za-z0-9_]*$', '')
    END AS package_name
  FROM java_files,
       LATERAL FLATTEN(INPUT => SPLIT("content", '\n')) f,        -- each line
       LATERAL (                                                 -- parse import line
         SELECT
           REGEXP_SUBSTR(                                        -- group-2 = full package
             TRIM(f.value::STRING),
             'import\\s+(static\\s+)?([A-Za-z_][A-Za-z0-9_]*(\\.[A-Za-z_][A-Za-z0-9_]*)*)',
             1, 1, 'e', 2)  AS raw_import,
           TRIM(f.value::STRING)          AS line_txt
       ) t
  WHERE t.line_txt ILIKE 'import %'
    AND raw_import IS NOT NULL
)

SELECT
  package_name,
  COUNT(*) AS import_count
FROM import_lines
GROUP BY package_name
ORDER BY import_count DESC NULLS LAST
LIMIT 10;
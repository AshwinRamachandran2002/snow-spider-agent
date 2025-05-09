/*-- Top-10 most frequently imported packages found inside
      parenthesised  import-blocks across all sample files */
SELECT
  REGEXP_REPLACE(                                  -- strip the quotes
       REGEXP_SUBSTR(line.value, '"[^"]+"'), '"', ''
  )                          AS "package",
  COUNT(*)                   AS "package_occurrences"
FROM  "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS"  src
     , LATERAL SPLIT_TO_TABLE(                      -- break the block into lines
         REGEXP_SUBSTR(                             -- isolate first “import (…)”
           src."content",
           'import \\([\\s\\S]*?\\)',               -- non-greedy, dot-including-newline
           1, 1, 's'
         ),
         '\n'
       )  line
WHERE src."content" ILIKE '%import (%'              -- only files that contain such block
  AND REGEXP_SUBSTR(line.value, '"[^"]+"') IS NOT NULL   -- keep lines with quoted pkg
GROUP BY "package"
HAVING "package" IS NOT NULL AND "package" <> ''    -- drop empty captures
ORDER BY "package_occurrences" DESC NULLS LAST
LIMIT 10;
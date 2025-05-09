/* Top-10 most frequently imported Java packages */
SELECT
  pkg      AS "import_package",
  COUNT(*) AS "import_count"
FROM (
  /* 1. Split every Java file into individual lines
     2. Keep only lines that start with a valid `import` statement
     3. Extract the fully-qualified import (drops the leading word “import”)
     4. Strip the trailing class / “*”, leaving only the package part        */
  SELECT
    REGEXP_REPLACE(
      REGEXP_SUBSTR(line, 'import\\s+([a-zA-Z0-9_\\.\\*]+)', 1, 1, 'e', 1),
      '\\.[^\\.\\*]+$'
    ) AS pkg
  FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS  AS c,
       LATERAL FLATTEN(INPUT => SPLIT(c."content", '\n')) AS f,
       LATERAL (SELECT f.value::STRING AS line)
  WHERE c."sample_path" ILIKE '%.java'               -- only Java sources
    AND f.value::STRING ILIKE 'import %'             -- keep import lines
    AND REGEXP_SUBSTR(f.value::STRING,
                      'import\\s+([a-zA-Z0-9_\\.\\*]+)', 1, 1, 'e', 1) IS NOT NULL
) AS sub
WHERE pkg IS NOT NULL
GROUP BY pkg
ORDER BY "import_count" DESC NULLS LAST
LIMIT 10;
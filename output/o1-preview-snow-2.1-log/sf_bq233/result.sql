SELECT 'Python' AS "Language",
       REGEXP_SUBSTR("content", 'import\\s+(\\w+)', 1, 1, 'i', 1) AS "Module_or_Library",
       COUNT(*) AS "Count"
FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS
WHERE "sample_path" LIKE '%.py' AND "content" ILIKE '%import %'
GROUP BY "Module_or_Library"
HAVING "Module_or_Library" IS NOT NULL AND "Module_or_Library" <> ''
UNION ALL
SELECT 'Python' AS "Language",
       REGEXP_SUBSTR("content", 'from\\s+(\\w+)\\s+import', 1, 1, 'i', 1) AS "Module_or_Library",
       COUNT(*) AS "Count"
FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS
WHERE "sample_path" LIKE '%.py' AND "content" ILIKE '%from % import %'
GROUP BY "Module_or_Library"
HAVING "Module_or_Library" IS NOT NULL AND "Module_or_Library" <> ''
UNION ALL
SELECT 'R' AS "Language",
       REGEXP_SUBSTR("content", 'library\\(([^)]+)\\)', 1, 1, 'i', 1) AS "Module_or_Library",
       COUNT(*) AS "Count"
FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS
WHERE ("sample_path" LIKE '%.R' OR "sample_path" LIKE '%.r') AND "content" ILIKE '%library(%'
GROUP BY "Module_or_Library"
HAVING "Module_or_Library" IS NOT NULL AND "Module_or_Library" <> ''
UNION ALL
SELECT 'R' AS "Language",
       REGEXP_SUBSTR("content", 'require\\(([^)]+)\\)', 1, 1, 'i', 1) AS "Module_or_Library",
       COUNT(*) AS "Count"
FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS
WHERE ("sample_path" LIKE '%.R' OR "sample_path" LIKE '%.r') AND "content" ILIKE '%require(%'
GROUP BY "Module_or_Library"
HAVING "Module_or_Library" IS NOT NULL AND "Module_or_Library" <> ''
ORDER BY "Language", "Count" DESC NULLS LAST
LIMIT 100;
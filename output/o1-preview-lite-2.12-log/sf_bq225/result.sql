SELECT mapping."language", COUNT(*) AS "file_count"
FROM "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_FILES" f
JOIN "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS" c
  ON f."id" = c."id"
JOIN (
  SELECT '.asm' AS "extension", 'Assembly' AS "language" UNION ALL
  SELECT '.nasm', 'Assembly' UNION ALL
  SELECT '.c', 'C' UNION ALL
  SELECT '.h', 'C' UNION ALL
  SELECT '.cs', 'C#' UNION ALL
  SELECT '.c++', 'C++' UNION ALL
  SELECT '.cpp', 'C++' UNION ALL
  SELECT '.h++', 'C++' UNION ALL
  SELECT '.hpp', 'C++' UNION ALL
  SELECT '.css', 'CSS' UNION ALL
  SELECT '.clj', 'Clojure' UNION ALL
  SELECT '.lisp', 'Common Lisp' UNION ALL
  SELECT '.d', 'D' UNION ALL
  SELECT '.dart', 'Dart' UNION ALL
  SELECT 'Dockerfile', 'Dockerfile' UNION ALL
  SELECT '.dockerfile', 'Dockerfile' UNION ALL
  SELECT '.ex', 'Elixir' UNION ALL
  SELECT '.exs', 'Elixir' UNION ALL
  SELECT '.erl', 'Erlang' UNION ALL
  SELECT '.go', 'Go' UNION ALL
  SELECT '.groovy', 'Groovy' UNION ALL
  SELECT '.html', 'HTML' UNION ALL
  SELECT '.htm', 'HTML' UNION ALL
  SELECT '.hs', 'Haskell' UNION ALL
  SELECT '.hx', 'Haxe' UNION ALL
  SELECT '.json', 'JSON' UNION ALL
  SELECT '.java', 'Java' UNION ALL
  SELECT '.js', 'JavaScript' UNION ALL
  SELECT '.cjs', 'JavaScript' UNION ALL
  SELECT '.jl', 'Julia' UNION ALL
  SELECT '.kt', 'Kotlin' UNION ALL
  SELECT '.ktm', 'Kotlin' UNION ALL
  SELECT '.kts', 'Kotlin' UNION ALL
  SELECT '.lua', 'Lua' UNION ALL
  SELECT '.matlab', 'MATLAB' UNION ALL
  SELECT '.m', 'MATLAB' UNION ALL
  SELECT '.md', 'Markdown' UNION ALL
  SELECT '.markdown', 'Markdown' UNION ALL
  SELECT '.mdown', 'Markdown' UNION ALL
  SELECT '.php', 'PHP' UNION ALL
  SELECT '.ps1', 'PowerShell' UNION ALL
  SELECT '.psd1', 'PowerShell' UNION ALL
  SELECT '.psm1', 'PowerShell' UNION ALL
  SELECT '.py', 'Python' UNION ALL
  SELECT '.r', 'R' UNION ALL
  SELECT '.rb', 'Ruby' UNION ALL
  SELECT '.rs', 'Rust' UNION ALL
  SELECT '.scss', 'SCSS' UNION ALL
  SELECT '.sql', 'SQL' UNION ALL
  SELECT '.sass', 'Sass' UNION ALL
  SELECT '.scala', 'Scala' UNION ALL
  SELECT '.sh', 'Shell' UNION ALL
  SELECT '.bash', 'Shell' UNION ALL
  SELECT '.swift', 'Swift' UNION ALL
  SELECT '.ts', 'TypeScript' UNION ALL
  SELECT '.vue', 'Vue' UNION ALL
  SELECT '.xml', 'XML' UNION ALL
  SELECT '.yml', 'YAML' UNION ALL
  SELECT '.yaml', 'YAML'
) AS mapping
ON (
  CASE
    WHEN LEFT(mapping."extension", 1) = '.'
    THEN LOWER(REGEXP_SUBSTR(REGEXP_SUBSTR(f."path", '[^/\\\\]+$'), '\\.[^\\.]+$')) = LOWER(mapping."extension")
    ELSE LOWER(REGEXP_SUBSTR(f."path", '[^/\\\\]+$')) = LOWER(mapping."extension")
  END
)
WHERE c."content" IS NOT NULL AND c."content" != ''
GROUP BY mapping."language"
ORDER BY "file_count" DESC NULLS LAST
LIMIT 10;
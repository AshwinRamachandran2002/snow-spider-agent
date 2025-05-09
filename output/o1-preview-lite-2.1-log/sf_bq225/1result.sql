SELECT "Language", COUNT(*) AS "File_Count"
FROM (
    SELECT
        CASE
            WHEN LOWER(REGEXP_SUBSTR("path", '\\.([^.\\/]+)$', 1, 1, 'e')) IN ('asm', 'nasm', 's') THEN 'Assembly'
            WHEN LOWER(REGEXP_SUBSTR("path", '\\.([^.\\/]+)$', 1, 1, 'e')) IN ('c', 'h') THEN 'C'
            WHEN LOWER(REGEXP_SUBSTR("path", '\\.([^.\\/]+)$', 1, 1, 'e')) = 'cs' THEN 'C#'
            WHEN LOWER(REGEXP_SUBSTR("path", '\\.([^.\\/]+)$', 1, 1, 'e')) IN ('cpp', 'c++', 'cxx', 'hpp', 'h++', 'cc', 'hh') THEN 'C++'
            WHEN LOWER(REGEXP_SUBSTR("path", '\\.([^.\\/]+)$', 1, 1, 'e')) IN ('css', 'scss', 'sass') THEN 'CSS'
            WHEN LOWER(REGEXP_SUBSTR("path", '\\.([^.\\/]+)$', 1, 1, 'e')) = 'clj' THEN 'Clojure'
            WHEN LOWER(REGEXP_SUBSTR("path", '\\.([^.\\/]+)$', 1, 1, 'e')) IN ('lisp', 'lsp') THEN 'Common Lisp'
            WHEN LOWER(REGEXP_SUBSTR("path", '\\.([^.\\/]+)$', 1, 1, 'e')) = 'd' THEN 'D'
            WHEN LOWER(REGEXP_SUBSTR("path", '\\.([^.\\/]+)$', 1, 1, 'e')) = 'dart' THEN 'Dart'
            WHEN LOWER("path") LIKE '%/dockerfile' OR REGEXP_REPLACE(LOWER(REGEXP_SUBSTR("path", '([^\\/]+)$')), '\\..*$', '') = 'dockerfile' THEN 'Dockerfile'
            WHEN LOWER(REGEXP_SUBSTR("path", '\\.([^.\\/]+)$', 1, 1, 'e')) IN ('ex', 'exs') THEN 'Elixir'
            WHEN LOWER(REGEXP_SUBSTR("path", '\\.([^.\\/]+)$', 1, 1, 'e')) = 'erl' THEN 'Erlang'
            WHEN LOWER(REGEXP_SUBSTR("path", '\\.([^.\\/]+)$', 1, 1, 'e')) = 'go' THEN 'Go'
            WHEN LOWER(REGEXP_SUBSTR("path", '\\.([^.\\/]+)$', 1, 1, 'e')) = 'groovy' THEN 'Groovy'
            WHEN LOWER(REGEXP_SUBSTR("path", '\\.([^.\\/]+)$', 1, 1, 'e')) IN ('htm', 'html') THEN 'HTML'
            WHEN LOWER(REGEXP_SUBSTR("path", '\\.([^.\\/]+)$', 1, 1, 'e')) = 'hs' THEN 'Haskell'
            WHEN LOWER(REGEXP_SUBSTR("path", '\\.([^.\\/]+)$', 1, 1, 'e')) = 'hx' THEN 'Haxe'
            WHEN LOWER(REGEXP_SUBSTR("path", '\\.([^.\\/]+)$', 1, 1, 'e')) = 'json' THEN 'JSON'
            WHEN LOWER(REGEXP_SUBSTR("path", '\\.([^.\\/]+)$', 1, 1, 'e')) = 'java' THEN 'Java'
            WHEN LOWER(REGEXP_SUBSTR("path", '\\.([^.\\/]+)$', 1, 1, 'e')) IN ('js', 'cjs', 'mjs', 'jsx') THEN 'JavaScript'
            WHEN LOWER(REGEXP_SUBSTR("path", '\\.([^.\\/]+)$', 1, 1, 'e')) = 'jl' THEN 'Julia'
            WHEN LOWER(REGEXP_SUBSTR("path", '\\.([^.\\/]+)$', 1, 1, 'e')) IN ('kt', 'ktm', 'kts') THEN 'Kotlin'
            WHEN LOWER(REGEXP_SUBSTR("path", '\\.([^.\\/]+)$', 1, 1, 'e')) = 'lua' THEN 'Lua'
            WHEN LOWER(REGEXP_SUBSTR("path", '\\.([^.\\/]+)$',1,1,'e')) IN ('matlab', 'm') THEN 'MATLAB'
            WHEN LOWER(REGEXP_SUBSTR("path", '\\.([^.\\/]+)$',1,1,'e')) IN ('md', 'markdown', 'mdown', 'mkd', 'mkdn', 'mdwn', 'mdtxt', 'mdtext') THEN 'Markdown'
            WHEN LOWER(REGEXP_SUBSTR("path", '\\.([^.\\/]+)$',1,1,'e')) IN ('php', 'php3', 'php4', 'php5', 'php7', 'phps', 'phtml') THEN 'PHP'
            WHEN LOWER(REGEXP_SUBSTR("path", '\\.([^.\\/]+)$',1,1,'e')) IN ('ps1', 'psd1', 'psm1') THEN 'PowerShell'
            WHEN LOWER(REGEXP_SUBSTR("path", '\\.([^.\\/]+)$',1,1,'e')) IN ('py', 'pyc', 'pyd', 'pyo', 'pyw', 'pyz') THEN 'Python'
            WHEN LOWER(REGEXP_SUBSTR("path", '\\.([^.\\/]+)$',1,1,'e')) = 'r' THEN 'R'
            WHEN LOWER(REGEXP_SUBSTR("path", '\\.([^.\\/]+)$',1,1,'e')) IN ('rb', 'rbw', 'rake') THEN 'Ruby'
            WHEN LOWER(REGEXP_SUBSTR("path", '\\.([^.\\/]+)$',1,1,'e')) = 'rs' THEN 'Rust'
            WHEN LOWER(REGEXP_SUBSTR("path", '\\.([^.\\/]+)$',1,1,'e')) = 'sql' THEN 'SQL'
            WHEN LOWER(REGEXP_SUBSTR("path", '\\.([^.\\/]+)$',1,1,'e')) IN ('scala', 'sc') THEN 'Scala'
            WHEN LOWER(REGEXP_SUBSTR("path", '\\.([^.\\/]+)$',1,1,'e')) IN ('sh', 'bash', 'bsh', 'csh', 'ksh', 'zsh') THEN 'Shell'
            WHEN LOWER(REGEXP_SUBSTR("path", '\\.([^.\\/]+)$',1,1,'e')) = 'swift' THEN 'Swift'
            WHEN LOWER(REGEXP_SUBSTR("path", '\\.([^.\\/]+)$',1,1,'e')) IN ('ts', 'tsx') THEN 'TypeScript'
            WHEN LOWER(REGEXP_SUBSTR("path", '\\.([^.\\/]+)$',1,1,'e')) = 'vue' THEN 'Vue'
            WHEN LOWER(REGEXP_SUBSTR("path", '\\.([^.\\/]+)$',1,1,'e')) IN ('xml', 'xsl', 'xsd') THEN 'XML'
            WHEN LOWER(REGEXP_SUBSTR("path", '\\.([^.\\/]+)$',1,1,'e')) IN ('yml', 'yaml') THEN 'YAML'
            ELSE NULL
        END AS "Language"
    FROM GITHUB_REPOS.GITHUB_REPOS."SAMPLE_FILES"
    WHERE REGEXP_SUBSTR("path", '\\.([^.\\/]+)$', 1, 1, 'e') IS NOT NULL
)
WHERE "Language" IS NOT NULL
GROUP BY "Language"
ORDER BY "File_Count" DESC NULLS LAST
LIMIT 10;
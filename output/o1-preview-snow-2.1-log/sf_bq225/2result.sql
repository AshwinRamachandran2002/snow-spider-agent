WITH extensions AS (
      SELECT 'Assembly' AS "Language", 'asm' AS "ext_or_file" UNION ALL
      SELECT 'Assembly', 'nasm' UNION ALL
      SELECT 'C', 'c' UNION ALL
      SELECT 'C', 'h' UNION ALL
      SELECT 'C#', 'cs' UNION ALL
      SELECT 'C++', 'c++' UNION ALL
      SELECT 'C++', 'cpp' UNION ALL
      SELECT 'C++', 'cxx' UNION ALL
      SELECT 'C++', 'h++' UNION ALL
      SELECT 'C++', 'hpp' UNION ALL
      SELECT 'C++', 'hh' UNION ALL
      SELECT 'CSS', 'css' UNION ALL
      SELECT 'Clojure', 'clj' UNION ALL
      SELECT 'Common Lisp', 'lisp' UNION ALL
      SELECT 'Common Lisp', 'lsp' UNION ALL
      SELECT 'D', 'd' UNION ALL
      SELECT 'Dart', 'dart' UNION ALL
      SELECT 'Dockerfile', 'dockerfile' UNION ALL
      SELECT 'Elixir', 'ex' UNION ALL
      SELECT 'Elixir', 'exs' UNION ALL
      SELECT 'Erlang', 'erl' UNION ALL
      SELECT 'Go', 'go' UNION ALL
      SELECT 'Groovy', 'groovy' UNION ALL
      SELECT 'HTML', 'html' UNION ALL
      SELECT 'HTML', 'htm' UNION ALL
      SELECT 'Haskell', 'hs' UNION ALL
      SELECT 'Haxe', 'hx' UNION ALL
      SELECT 'JSON', 'json' UNION ALL
      SELECT 'Java', 'java' UNION ALL
      SELECT 'JavaScript', 'js' UNION ALL
      SELECT 'JavaScript', 'cjs' UNION ALL
      SELECT 'Julia', 'jl' UNION ALL
      SELECT 'Kotlin', 'kt' UNION ALL
      SELECT 'Kotlin', 'ktm' UNION ALL
      SELECT 'Kotlin', 'kts' UNION ALL
      SELECT 'Lua', 'lua' UNION ALL
      SELECT 'MATLAB', 'matlab' UNION ALL
      SELECT 'MATLAB', 'm' UNION ALL
      SELECT 'Markdown', 'md' UNION ALL
      SELECT 'Markdown', 'markdown' UNION ALL
      SELECT 'Markdown', 'mdown' UNION ALL
      SELECT 'PHP', 'php' UNION ALL
      SELECT 'PowerShell', 'ps1' UNION ALL
      SELECT 'PowerShell', 'psd1' UNION ALL
      SELECT 'PowerShell', 'psm1' UNION ALL
      SELECT 'Python', 'py' UNION ALL
      SELECT 'R', 'r' UNION ALL
      SELECT 'Ruby', 'rb' UNION ALL
      SELECT 'Rust', 'rs' UNION ALL
      SELECT 'SCSS', 'scss' UNION ALL
      SELECT 'Sass', 'sass' UNION ALL
      SELECT 'SQL', 'sql' UNION ALL
      SELECT 'Scala', 'scala' UNION ALL
      SELECT 'Shell', 'sh' UNION ALL
      SELECT 'Shell', 'bash' UNION ALL
      SELECT 'Swift', 'swift' UNION ALL
      SELECT 'TypeScript', 'ts' UNION ALL
      SELECT 'Vue', 'vue' UNION ALL
      SELECT 'XML', 'xml' UNION ALL
      SELECT 'YAML', 'yml' UNION ALL
      SELECT 'YAML', 'yaml'
    ),
    files AS (
      SELECT
        LOWER(SPLIT_PART("path", '/', -1)) AS "filename",
        CASE
          WHEN POSITION('.' IN LOWER(SPLIT_PART("path", '/', -1))) > 0 THEN
            LOWER(SPLIT_PART(LOWER(SPLIT_PART("path", '/', -1)), '.', -1))
          ELSE NULL
        END AS "ext_or_file"
      FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES
      WHERE "path" IS NOT NULL
    )
    SELECT
      "Language",
      COUNT(*) AS "File_Count"
    FROM files
    JOIN extensions ON files."ext_or_file" = extensions."ext_or_file"
    WHERE files."ext_or_file" IS NOT NULL
    GROUP BY "Language"
    ORDER BY "File_Count" DESC NULLS LAST
    LIMIT 10;
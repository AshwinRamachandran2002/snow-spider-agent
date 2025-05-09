WITH RECURSIVE
  letters(word, pos, ch) AS (                    -- break each word into letters
      SELECT words, 1, substr(words,1,1)
      FROM word_list
    UNION ALL
      SELECT word,
             pos+1,
             substr(word,pos+1,1)
      FROM letters
      WHERE pos+1 <= length(word)
),
  ordered_letters AS (                           -- alphabetise letters per word
      SELECT word, ch
      FROM letters
      ORDER BY word, ch
),
  signatures AS (                                -- build “signature” for each word
      SELECT word,
             group_concat(ch,'') AS signature,
             length(word)         AS len
      FROM ordered_letters
      GROUP BY word
),
  sig_counts AS (                                -- keep signatures shared by >1 word
      SELECT signature, len, COUNT(*) AS anagram_count
      FROM signatures
      GROUP BY signature, len
      HAVING anagram_count > 1
)
SELECT s.word,
       sc.anagram_count
FROM   signatures AS s
JOIN   sig_counts  AS sc
       ON s.signature = sc.signature
      AND s.len       = sc.len
WHERE  s.len BETWEEN 4 AND 5           -- 4–5 characters long
  AND  s.word GLOB 'r*'                -- starts with lower‑case ‘r’
ORDER BY s.word
LIMIT 10;
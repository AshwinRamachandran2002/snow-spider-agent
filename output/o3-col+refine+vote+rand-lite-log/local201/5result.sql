WITH RECURSIVE letters(word,pos,ch) AS (
    -- break each 4- or 5-letter word into individual characters
    SELECT words AS word,
           1      AS pos,
           substr(words,1,1) AS ch
    FROM   word_list
    WHERE  LENGTH(words) BETWEEN 4 AND 5

    UNION ALL
    SELECT word,
           pos+1,
           substr(word,pos+1,1)
    FROM   letters
    WHERE  pos+1 <= LENGTH(word)
),
-- build a sorted-letter “signature” for every word
sig AS (
    SELECT word,
           group_concat(ch,'') AS signature
    FROM   (
        SELECT word, ch
        FROM   letters
        ORDER  BY word, ch          -- sort letters inside each word
    )
    GROUP BY word
),
-- how many words share each signature (i.e. size of the anagram set)
grp AS (
    SELECT signature,
           COUNT(*) AS anagrams_count
    FROM   sig
    GROUP BY signature
    HAVING COUNT(*) > 1            -- keep only signatures with ≥2 words
)
-- final selection: words that start with “r”, length 4–5, with anagrams
SELECT s.word,
       g.anagrams_count
FROM   sig AS s
JOIN   grp AS g
  ON   s.signature = g.signature
WHERE  s.word GLOB 'r???'   -- 4-letter words starting with r
   OR  s.word GLOB 'r????'  -- 5-letter words starting with r
ORDER BY s.word
LIMIT 10;
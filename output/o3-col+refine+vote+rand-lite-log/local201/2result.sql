WITH RECURSIVE chars AS (
  -- start with every 4-5 letter word beginning with “r”
  SELECT
      words AS word,
      1     AS pos,
      substr(words,1,1) AS ch,
      length(words)     AS len
  FROM word_list
  WHERE (length(words) = 4 OR length(words) = 5)
    AND substr(words,1,1) = 'r'

  UNION ALL
  
  -- advance through each character of each word
  SELECT
      word,
      pos + 1,
      substr(word, pos + 1, 1) AS ch,
      len
  FROM chars
  WHERE pos < len
),
-- build an alphabetically-sorted character “signature” for every word
signatures AS (
  SELECT
      word,
      (SELECT group_concat(ch,'')
         FROM (SELECT ch
                 FROM chars c2
                WHERE c2.word = chars.word
             ORDER BY ch)
      ) AS signature
  FROM chars
  GROUP BY word
),
-- keep only signatures that have at least one anagram partner
sig_counts AS (
  SELECT
      signature,
      COUNT(*) AS family_cnt
  FROM signatures
  GROUP BY signature
  HAVING COUNT(*) > 1
)
-- final list: first 10 words (alphabetical) and their anagram counts
SELECT
    s.word,
    sc.family_cnt - 1 AS anagram_count          -- exclude the word itself
FROM signatures AS s
JOIN sig_counts  AS sc USING (signature)
ORDER BY s.word
LIMIT 10;
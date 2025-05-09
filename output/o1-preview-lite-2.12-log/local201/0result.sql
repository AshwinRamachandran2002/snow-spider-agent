WITH input_words AS (
  SELECT "words" AS word
  FROM "word_list"
  WHERE LENGTH("words") BETWEEN 4 AND 5 AND "words" LIKE 'r%'
),
letters AS (
  SELECT word,
         SUBSTR(word, 1, 1) AS l1,
         SUBSTR(word, 2, 1) AS l2,
         SUBSTR(word, 3, 1) AS l3,
         SUBSTR(word, 4, 1) AS l4,
         SUBSTR(word, 5, 1) AS l5
  FROM input_words
),
sorted_letters AS (
  SELECT word,
         (SELECT GROUP_CONCAT(letter, '')
          FROM (
            SELECT letter FROM (
              SELECT l1 AS letter UNION ALL
              SELECT l2 UNION ALL
              SELECT l3 UNION ALL
              SELECT l4 UNION ALL
              SELECT l5
            )
            WHERE letter <> ''
            ORDER BY letter
          )
         ) AS signature
  FROM letters
),
anagram_counts AS (
  SELECT signature, COUNT(*) AS anagram_count
  FROM sorted_letters
  GROUP BY signature
  HAVING COUNT(*) > 1
),
words_with_counts AS (
  SELECT sw.word, ac.anagram_count
  FROM sorted_letters sw
  JOIN anagram_counts ac ON sw.signature = ac.signature
)
SELECT word AS Word, anagram_count AS Anagram_Count
FROM words_with_counts
ORDER BY word
LIMIT 10;
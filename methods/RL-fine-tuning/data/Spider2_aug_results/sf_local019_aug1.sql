-- Task: List matches in the NXT promotion, including the title, match duration, and names of the two wrestlers involved (excluding matches for titles with 'title change' in the title name). Limit the results to 100 matches.
SELECT
    B."name" AS "titles",
    M."duration" AS "match_duration",
    W1."name" AS "wrestler1",
    W2."name" AS "wrestler2",
    M."win_type" AS "win_type",
    L."name" AS "location",
    E."name" AS "event"
FROM 
    WWE.WWE.BELTS B
INNER JOIN WWE.WWE.MATCHES M ON M."title_id" = B."id"
INNER JOIN WWE.WWE.WRESTLERS W1 ON W1."id" = M."winner_id"
INNER JOIN WWE.WWE.WRESTLERS W2 ON W2."id" = M."loser_id"
INNER JOIN WWE.WWE.CARDS C ON C."id" = M."card_id"
INNER JOIN WWE.WWE.LOCATIONS L ON L."id" = C."location_id"
INNER JOIN WWE.WWE.EVENTS E ON E."id" = C."event_id"
INNER JOIN WWE.WWE.PROMOTIONS P ON P."id" = C."promotion_id"
WHERE
    P."name" = 'NXT'
    AND M."duration" <> ''
    AND B."name" <> ''
    AND B."name" NOT LIKE '%title change%'
LIMIT 100
/*  Games each bowler won with a handicap score ≤ 190               */
/*  at the three requested venues.                                  */
/*  Only bowlers who have such a win at ALL THREE venues are kept.   */
SELECT
    bs."BowlerID",
    b."BowlerFirstName",
    b."BowlerLastName",
    bs."MatchID",
    bs."GameNumber",
    bs."HandiCapScore",
    t."TourneyDate",
    t."TourneyLocation"
FROM BOWLINGLEAGUE.BOWLINGLEAGUE.BOWLER_SCORES       AS bs
JOIN BOWLINGLEAGUE.BOWLINGLEAGUE.TOURNEY_MATCHES      AS tm
     ON tm."MatchID" = bs."MatchID"
JOIN BOWLINGLEAGUE.BOWLINGLEAGUE.TOURNAMENTS          AS t
     ON t."TourneyID" = tm."TourneyID"
JOIN BOWLINGLEAGUE.BOWLINGLEAGUE.BOWLERS              AS b
     ON b."BowlerID" = bs."BowlerID"
WHERE
      bs."WonGame"        = 1
  AND bs."HandiCapScore" <= 190
  AND t."TourneyLocation" IN ('Thunderbird Lanes',
                              'Totem Lanes',
                              'Bolero Lanes')
  /* keep only bowlers who satisfied the condition at ALL 3 venues */
  AND bs."BowlerID" IN (
        SELECT bs2."BowlerID"
        FROM BOWLINGLEAGUE.BOWLINGLEAGUE.BOWLER_SCORES  AS bs2
        JOIN BOWLINGLEAGUE.BOWLINGLEAGUE.TOURNEY_MATCHES AS tm2
              ON tm2."MatchID" = bs2."MatchID"
        JOIN BOWLINGLEAGUE.BOWLINGLEAGUE.TOURNAMENTS     AS t2
              ON t2."TourneyID" = tm2."TourneyID"
        WHERE
              bs2."WonGame"        = 1
          AND bs2."HandiCapScore" <= 190
          AND t2."TourneyLocation" IN ('Thunderbird Lanes',
                                       'Totem Lanes',
                                       'Bolero Lanes')
        GROUP BY bs2."BowlerID"
        HAVING COUNT(DISTINCT t2."TourneyLocation") = 3
  )
ORDER BY
    bs."BowlerID",
    t."TourneyDate",
    bs."GameNumber";
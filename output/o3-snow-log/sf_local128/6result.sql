SELECT
    bs."BowlerID",
    bl."BowlerFirstName",
    bl."BowlerLastName",
    bs."MatchID",
    bs."GameNumber",
    bs."HandiCapScore",
    tr."TourneyDate",
    tr."TourneyLocation"
FROM BOWLINGLEAGUE.BOWLINGLEAGUE.BOWLER_SCORES            AS bs
JOIN BOWLINGLEAGUE.BOWLINGLEAGUE.TOURNEY_MATCHES           AS tm  ON bs."MatchID" = tm."MatchID"
JOIN BOWLINGLEAGUE.BOWLINGLEAGUE.TOURNAMENTS               AS tr  ON tm."TourneyID" = tr."TourneyID"
JOIN BOWLINGLEAGUE.BOWLINGLEAGUE.BOWLERS                   AS bl  ON bs."BowlerID" = bl."BowlerID"
WHERE
      bs."WonGame" = 1
  AND bs."HandiCapScore" <= 190
  AND tr."TourneyLocation" IN ('Thunderbird Lanes', 'Totem Lanes', 'Bolero Lanes')
  AND bs."BowlerID" IN (
        SELECT
            bs2."BowlerID"
        FROM BOWLINGLEAGUE.BOWLINGLEAGUE.BOWLER_SCORES      AS bs2
        JOIN BOWLINGLEAGUE.BOWLINGLEAGUE.TOURNEY_MATCHES     AS tm2 ON bs2."MatchID" = tm2."MatchID"
        JOIN BOWLINGLEAGUE.BOWLINGLEAGUE.TOURNAMENTS         AS tr2 ON tm2."TourneyID" = tr2."TourneyID"
        WHERE
              bs2."WonGame" = 1
          AND bs2."HandiCapScore" <= 190
          AND tr2."TourneyLocation" IN ('Thunderbird Lanes', 'Totem Lanes', 'Bolero Lanes')
        GROUP BY
            bs2."BowlerID"
        HAVING
            COUNT(DISTINCT tr2."TourneyLocation") = 3
  )
ORDER BY
    bl."BowlerLastName",
    bl."BowlerFirstName",
    tr."TourneyDate",
    bs."MatchID",
    bs."GameNumber"
;
WITH Qualifying AS (
    /* 1.  All individual games that meet the requirements               */
    SELECT
        bs."BowlerID",
        b."BowlerFirstName",
        b."BowlerLastName",
        bs."MatchID",
        bs."GameNumber",
        bs."HandiCapScore",
        t."TourneyDate",
        t."TourneyLocation"
    FROM "Bowler_Scores"      AS bs
    JOIN "Tourney_Matches"    AS tm ON tm."MatchID"  = bs."MatchID"
    JOIN "Tournaments"        AS t  ON t."TourneyID" = tm."TourneyID"
    JOIN "Bowlers"            AS b  ON b."BowlerID"  = bs."BowlerID"
    WHERE bs."WonGame"      = 1
      AND bs."HandiCapScore" <= 190
      AND t."TourneyLocation" IN ('Thunderbird Lanes',
                                  'Totem Lanes',
                                  'Bolero Lanes')
),
BowlersAllThree AS (
    /* 2.  Bowlers who have such a win at *each* of the three venues     */
    SELECT "BowlerID"
    FROM Qualifying
    GROUP BY "BowlerID"
    HAVING COUNT(DISTINCT "TourneyLocation") = 3
)
/* 3.  Return only the qualifying game rows for those bowlers            */
SELECT
    q."BowlerID",
    q."BowlerFirstName",
    q."BowlerLastName",
    q."MatchID",
    q."GameNumber",
    q."HandiCapScore",
    q."TourneyDate",
    q."TourneyLocation"
FROM Qualifying AS q
JOIN BowlersAllThree AS ba ON ba."BowlerID" = q."BowlerID"
ORDER BY
    q."BowlerLastName",
    q."BowlerFirstName",
    q."BowlerID",
    q."TourneyDate",
    q."MatchID",
    q."GameNumber";
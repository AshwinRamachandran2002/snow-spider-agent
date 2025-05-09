/*  Shahrukh-number 2: actors who
    1) acted in a film with at least one “Shahrukh-number 1” actor,
    2) never acted in a film that includes Shah Rukh Khan himself, and
    3) are not Shah Rukh Khan nor any Shahrukh-number 1 actor.
*/
SELECT COUNT(*) AS num_shahrukh_number_2
FROM (
        /* all candidates who appeared with a Shahrukh-number 1 actor */
        SELECT DISTINCT TRIM(mc.PID) AS PID
        FROM M_Cast AS mc
        WHERE mc.MID IN (
                /* films that feature at least one Shahrukh-number 1 actor */
                SELECT DISTINCT m2.MID
                FROM M_Cast AS m2
                WHERE TRIM(m2.PID) IN (
                        /* list of Shahrukh-number 1 actors */
                        SELECT DISTINCT TRIM(c.PID)
                        FROM M_Cast AS c
                        WHERE c.MID IN (                  -- movies with Shah Rukh Khan
                                SELECT DISTINCT k.MID
                                FROM M_Cast AS k
                                WHERE TRIM(k.PID) IN (SELECT PID
                                                      FROM Person
                                                      WHERE Name LIKE '%Shah%Khan%')
                        )
                        AND TRIM(c.PID) NOT IN (          -- exclude Shah Rukh Khan himself
                                SELECT PID
                                FROM Person
                                WHERE Name LIKE '%Shah%Khan%'
                        )
                )
        )

        /* Exclude Shah Rukh Khan himself */
        AND TRIM(mc.PID) NOT IN (SELECT PID
                                 FROM Person
                                 WHERE Name LIKE '%Shah%Khan%')

        /* Exclude all Shahrukh-number 1 actors */
        AND TRIM(mc.PID) NOT IN (
                SELECT DISTINCT TRIM(c.PID)
                FROM M_Cast AS c
                WHERE c.MID IN (
                        SELECT DISTINCT k.MID
                        FROM M_Cast AS k
                        WHERE TRIM(k.PID) IN (SELECT PID
                                              FROM Person
                                              WHERE Name LIKE '%Shah%Khan%')
                )
                AND TRIM(c.PID) NOT IN (SELECT PID
                                        FROM Person
                                        WHERE Name LIKE '%Shah%Khan%')
        )
) AS t;
/* Compare total road lengths (meters) for Amsterdam vs. Rotterdam
   Amsterdam  -> QUADKEYs starting with '12020210'
   Rotterdam  -> QUADKEYs starting with '12020211' */

SELECT
  "CLASS",
  "SUBCLASS",
  /* total length for Amsterdam (sum only when quadkey starts with 12020210) */
  SUM(
      CASE 
        WHEN "QUADKEY" LIKE '12020210%' 
        THEN TRY_TO_DOUBLE("LENGTH_M") 
      END
  ) AS "AMSTERDAM_LENGTH_M",
  /* total length for Rotterdam (sum only when quadkey starts with 12020211) */
  SUM(
      CASE 
        WHEN "QUADKEY" LIKE '12020211%' 
        THEN TRY_TO_DOUBLE("LENGTH_M") 
      END
  ) AS "ROTTERDAM_LENGTH_M"
FROM NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS."V_ROAD"
/* keep only the two relevant quadkey segments to reduce scan size */
WHERE "QUADKEY" LIKE '12020210%' 
   OR "QUADKEY" LIKE '12020211%'
GROUP BY
  "CLASS",
  "SUBCLASS"
ORDER BY
  "CLASS",
  "SUBCLASS";
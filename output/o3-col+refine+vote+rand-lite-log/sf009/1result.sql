/*  Building class & subclass comparison: Amsterdam vs Rotterdam  */
WITH city_buildings AS (
    SELECT
        b."CLASS",
        b."SUBCLASS",
        TRY_TO_NUMBER(b."SURFACE_AREA_SQ_M")                            AS "SURF_SQM",
        f.value::VARIANT:"addr:city"::STRING                           AS "CITY"
    FROM  "NETHERLANDS_OPEN_MAP_DATA"."NETHERLANDS"."V_BUILDING"  b,
          LATERAL FLATTEN( INPUT => PARSE_JSON(b."CONTAINS_ADDRESSES") ) f
)
SELECT
    "CLASS",
    "SUBCLASS",
    /*  total number of buildings  */
    COALESCE( SUM(CASE WHEN "CITY" ILIKE '%amsterdam%' THEN 1 END), 0 )        AS "AMSTERDAM_BUILDING_COUNT",
    COALESCE( SUM(CASE WHEN "CITY" ILIKE '%rotterdam%' THEN 1 END), 0 )        AS "ROTTERDAM_BUILDING_COUNT",
    /*  total surface area (m²)  */
    COALESCE( SUM(CASE WHEN "CITY" ILIKE '%amsterdam%' THEN "SURF_SQM" END),0) AS "AMSTERDAM_TOTAL_SURF_SQM",
    COALESCE( SUM(CASE WHEN "CITY" ILIKE '%rotterdam%' THEN "SURF_SQM" END),0) AS "ROTTERDAM_TOTAL_SURF_SQM"
FROM   city_buildings
WHERE  "CITY" ILIKE ANY ( '%amsterdam%', '%rotterdam%' )
GROUP  BY "CLASS", "SUBCLASS"
ORDER  BY "CLASS", "SUBCLASS";
SELECT
    CASE
        WHEN t."CONTAINS_ADDR_POSTCODE" LIKE '10%' THEN 'Amsterdam'
        WHEN t."CONTAINS_ADDR_POSTCODE" LIKE '30%' THEN 'Rotterdam'
        WHEN t."CONTAINS_ADDR_STREET" ILIKE '%Amsterdam%' THEN 'Amsterdam'
        WHEN t."CONTAINS_ADDR_STREET" ILIKE '%Rotterdam%' THEN 'Rotterdam'
        WHEN t."BUILDING_LOCATION" ILIKE '%Amsterdam%' THEN 'Amsterdam'
        WHEN t."BUILDING_LOCATION" ILIKE '%Rotterdam%' THEN 'Rotterdam'
    END AS "City",
    t."CLASS" AS "Class",
    t."SUBCLASS" AS "Subclass",
    ROUND(SUM(TRY_TO_NUMERIC(t."SURFACE_AREA_SQ_M")), 4) AS "Total_Surface_Area_Sq_M",
    COUNT(*) AS "Number_of_Buildings"
FROM NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS.V_BUILDING t
WHERE (t."CONTAINS_ADDR_POSTCODE" LIKE '10%' OR t."CONTAINS_ADDR_POSTCODE" LIKE '30%')
   OR (t."CONTAINS_ADDR_STREET" ILIKE '%Amsterdam%' OR t."CONTAINS_ADDR_STREET" ILIKE '%Rotterdam%')
   OR (t."BUILDING_LOCATION" ILIKE '%Amsterdam%' OR t."BUILDING_LOCATION" ILIKE '%Rotterdam%')
GROUP BY "City", "Class", "Subclass"
HAVING "City" IS NOT NULL
ORDER BY "City", "Number_of_Buildings" DESC NULLS LAST;
WITH t2_studies AS (
    SELECT DISTINCT "StudyInstanceUID"
    FROM IDC.IDC_V17.DICOM_PIVOT
    WHERE "collection_id" = 'qin_prostate_repeatability'
      AND "Modality" = 'MR'
      AND "SeriesDescription" ILIKE '%T2%'
      AND ("SeriesDescription" ILIKE '%AX%' OR "SeriesDescription" ILIKE '%AXIAL%')
),
pz_studies AS (
    SELECT DISTINCT p."StudyInstanceUID"
    FROM IDC.IDC_V17.SEGMENTATIONS         AS s
    JOIN IDC.IDC_V17.DICOM_PIVOT           AS p
      ON p."SeriesInstanceUID" = s."SeriesInstanceUID"
    WHERE p."collection_id" = 'qin_prostate_repeatability'
      AND CAST(s."SegmentedPropertyType" AS STRING) ILIKE '%peripheral zone%'
)
SELECT DISTINCT "StudyInstanceUID"
FROM t2_studies
INTERSECT
SELECT DISTINCT "StudyInstanceUID"
FROM pz_studies;
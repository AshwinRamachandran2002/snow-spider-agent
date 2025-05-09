-- Distinct studies in the “qin_prostate_repeatability” collection that
-- (1) contain axial T2-weighted MR series and
-- (2) have segmentations of the peripheral zone
SELECT  DISTINCT seg."StudyInstanceUID"
FROM    IDC.IDC_V17.SEGMENTATIONS AS seg
JOIN   (
          SELECT DISTINCT "StudyInstanceUID"
          FROM   IDC.IDC_V17.DICOM_ALL
          WHERE  "collection_id"    = 'qin_prostate_repeatability'
            AND  "Modality"         = 'MR'
            AND  "SeriesDescription" ILIKE '%t2%'   -- T2-weighted
            AND  "SeriesDescription" ILIKE '%ax%'   -- axial
       ) AS t2
       ON seg."StudyInstanceUID" = t2."StudyInstanceUID"
WHERE   seg."SegmentedPropertyType"::STRING ILIKE '%peripheral%zone%';
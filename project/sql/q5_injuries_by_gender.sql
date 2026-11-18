-- Query 5: Injury gender breakdown by injury severity.
-- Show: gender, injury_severity, and the number of cells for each combination.
-- Order by cell count descending.
-- Table: injuries
-- Uses: SELECT, COUNT, GROUP BY, ORDER BY

SELECT gender,
       injury_severity,
       COUNT(*) AS cell_count
FROM injuries
GROUP BY gender, injury_severity
ORDER BY cell_count DESC;

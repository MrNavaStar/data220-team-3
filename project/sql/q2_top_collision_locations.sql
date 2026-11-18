-- Query 2: Top collision locations ranked by collision count.
-- Show: location_description and collision_count, ordered by count descending.
-- Table: locations
-- Uses: SELECT, FROM, ORDER BY, LIMIT

SELECT location_description,
       collision_count
FROM locations
ORDER BY collision_count DESC
LIMIT 10;

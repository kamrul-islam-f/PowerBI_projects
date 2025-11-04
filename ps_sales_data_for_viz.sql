
-- Create a new view called 'ps_sales_cleaned' for our analysis
-- A view acts like a virtual table without storing duplicate data

CREATE VIEW ps_sales_cleaned AS
SELECT
    game,
    console,
    name,
    publisher,
    developer,
    COALESCE(total_shipped, 0) AS total_shipped,
    COALESCE(total_sales, 0) AS total_sales,
    COALESCE(na_sales, 0) AS na_sales,
    COALESCE(pal_sales, 0) AS pal_sales,
    COALESCE(japan_sales, 0) AS japan_sales,
    COALESCE(other_sales, 0) AS other_sales,
    release_date,
    last_update,
    rating,
    ratings_count,
    metacritic,
    genres,
    platforms,
    
    -- *** FEATURE ENGINEERING: Create PlayStation Exclusive Flag ***
    -- Logic: A game is exclusive if it's NOT available on any major non-PlayStation platform
    
    CASE 
        WHEN platforms NOT LIKE '%PC%' 
         AND platforms NOT LIKE '%Xbox%' 
         AND platforms NOT LIKE '%Nintendo%' 
         AND platforms NOT LIKE '%iOS%' 
         AND platforms NOT LIKE '%Android%' 
         AND platforms NOT LIKE '%macOS%' 
         AND platforms NOT LIKE '%Web%'
        THEN 'Yes'  -- Game is only on PlayStation platforms
        ELSE 'No'   -- Game is also available on other platforms
    END AS is_exclusive

FROM [ServerProject1.2]..ps_sales;

-- Test the view to see the newly created 'is_exclusive' column in action
SELECT TOP 5
name, publisher, platforms, is_exclusive, total_sales
FROM ps_sales_cleaned

-- Creating Insightful SQL Queries for visualization
-- Top Publishers by Total Sales

SELECT TOP 5
    CAST(publisher AS VARCHAR) AS publisher,
    ROUND(SUM(total_sales), 2) AS total_sales_millions
FROM ps_sales_cleaned
GROUP BY CAST(publisher AS VARCHAR)
ORDER BY total_sales_millions DESC

-- Regional Sales Analysis by Genre

SELECT TOP 5
    CAST(genres AS VARCHAR) AS genres,
    ROUND(SUM(na_sales), 2) AS na_sales,
    ROUND(SUM(pal_sales), 2) AS pal_sales,
    ROUND(SUM(japan_sales), 2) AS japan_sales,
    ROUND(SUM(other_sales), 2) AS other_sales
FROM ps_sales_cleaned
WHERE CAST(genres AS VARCHAR) IS NOT NULL
GROUP BY CAST(genres AS VARCHAR)
ORDER BY na_sales DESC;

-- Critical vs. Commercial Success

WITH RatingCTE AS (
    SELECT 
        CASE 
            WHEN metacritic >= 90 THEN '90-100 (Exceptional)'
            WHEN metacritic >= 80 THEN '80-89 (Great)'
            WHEN metacritic >= 70 THEN '70-79 (Good)'
            WHEN metacritic >= 60 THEN '60-69 (Fair)'
            ELSE 'Below 60 or Unrated'
        END AS rating_bucket,
        total_sales
    FROM ps_sales_cleaned
)
SELECT 
    rating_bucket,
    COUNT(*) AS number_of_games,
    ROUND(AVG(total_sales), 2) AS average_sales_millions
FROM RatingCTE
GROUP BY rating_bucket
ORDER BY average_sales_millions DESC;


-- Console Generation Comparison

SELECT 
    CAST(console AS VARCHAR) AS console,
    COUNT(*) AS number_of_games,
    ROUND(SUM(total_sales), 2) AS total_sales_millions,
    ROUND(AVG(total_sales), 2) AS average_sales_per_game
FROM ps_sales_cleaned
WHERE CAST(console AS VARCHAR) IN ('PS3', 'PS4')
GROUP BY CAST(console AS VARCHAR);

-- Exclusive vs. Non-Exclusive Performance

SELECT 
    is_exclusive,
    COUNT(*) AS number_of_games,
    ROUND(SUM(total_sales), 2) AS total_sales_millions,
    ROUND(AVG(total_sales), 2) AS average_sales_per_game
FROM ps_sales_cleaned
GROUP BY is_exclusive;
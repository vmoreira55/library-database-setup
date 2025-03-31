/*
The library wants to generate a loan activity report, showing:
Most popular books (most borrowed in the last 6 months).
Patrons with the most borrowed books in the last 6 months.
A combination of these two results into a single query.
*/

/*
Errors and Performance Issues

Unnecessary subqueries within the SELECT statement

(SELECT COUNT(*) FROM loans l WHERE l.book_id = b.book_id)
This recalculates the loan count for each row, instead of performing an efficient JOIN.
(SELECT COUNT(*) FROM loans WHERE user_id = u.user_id)
Instead of counting in the GROUP BY, this subquery performs an extra search for each user, making the query extremely slow.

Evaluates YEAR() on every row, which breaks indexes and causes the database to scan all records.

It doesn't use JOIN, which causes the query to do a "Cartesian product" if not filtered properly.

HAVING total loans > 3 doesn't work because totale loans is a subquery and not a calculated column in the GROUP BY.

Each part of UNION ALL attempts to order individually
*/

-- Most borrowed books in the last 6 months (inefficient version)
SELECT 'Top Books' AS category, 
       b.book_id, 
       b.title, 
       (SELECT COUNT(*) FROM loans l WHERE l.book_id = b.book_id) AS total_loans, 
       NULL AS user_id, 
       NULL AS full_name
FROM books b, loans l
WHERE b.book_id = l.book_id
AND YEAR(l.loan_date) = YEAR(CURRENT_DATE) - 1 -- Bad practice (YEAR() on each row)
GROUP BY b.book_id, b.title
HAVING total_loans > 3 -- Incorrect, total_loans is not defined
ORDER BY total_loans DESC

UNION ALL

-- Users with the most loans in the last 6 months (inefficient version)
SELECT 'Top Users' AS category, 
       NULL AS book_id, 
       NULL AS title, 
       (SELECT COUNT(*) FROM loans WHERE user_id = u.user_id) AS total_loans, 
       u.user_id, 
       u.first_name || ' ' || u.last_name AS full_name
FROM users u, loans l
WHERE u.user_id = l.user_id
AND l.loan_date BETWEEN ADD_MONTHS(CURRENT_DATE, -6) AND CURRENT_DATE
GROUP BY u.user_id, u.first_name, u.last_name
HAVING total_loans > 5 -- Incorrect, total_loans is not defined
ORDER BY total_loans DESC;

/*
UNION ALL to combine two queries

The first part retrieves the most borrowed books.
The second part retrieves the users with the most borrowed books.
These are combined into a single query with UNION ALL, allowing both sets to be retrieved in a single execution.
A JOIN is used with the same table twice to query both the most borrowed books and the most active users.
Use HAVING COUNT(l.loan id) > 3 to filter only books with more than 3 loans. Use HAVING COUNT(l.loan_id) > 5 to filter only users with more than 5 loans.
Since the first part queries books, it has neither user_id nor full_name, so it returns NULL.
Since the second part queries users, it has neither book_id nor title, so it returns NULL.
*/

-- Most borrowed books in the last 6 months
SELECT 'Top Books' AS category, 
       b.book_id, 
       b.title, 
       COUNT(l.loan_id) AS total_loans, 
       NULL AS user_id, 
       NULL AS full_name
FROM books b
JOIN loans l ON b.book_id = l.book_id
WHERE l.loan_date >= ADD_MONTHS(TRUNC(CURRENT_DATE), -6)
AND l.loan_date <= TRUNC(CURRENT_DATE)
GROUP BY b.book_id, b.title
HAVING COUNT(l.loan_id) > 3  -- Filter only the most popular books
ORDER BY total_loans DESC

UNION ALL

-- Users with the most loans in the last 6 months
SELECT 'Top Users' AS category, 
       NULL AS book_id, 
       NULL AS title, 
       COUNT(l.loan_id) AS total_loans, 
       u.user_id, 
       u.first_name || ' ' || u.last_name AS full_name
FROM users u
JOIN loans l ON u.user_id = l.user_id
WHERE l.loan_date >= ADD_MONTHS(TRUNC(CURRENT_DATE), -6)
AND l.loan_date <= TRUNC(CURRENT_DATE)
GROUP BY u.user_id, u.first_name, u.last_name
HAVING COUNT(l.loan_id) > 5  -- Filter only the most active users
ORDER BY total_loans DESC;
----------------------------------------------------------------------------------------------------------------------------------------------------------
/*
A poor query to find books borrowed more than once in the last year. This query is inefficient because:
It doesn't use indexes properly (inefficient filters with YEAR() in the condition).
It creates an unnecessary nested query.
It uses GROUP BY and HAVING when they could be solved with an optimized subquery.

This query has the following problems:

YEAR(l.loan_date) = YEAR(NOW()) - 1 causes the database to calculate YEAR() for each row, instead of directly comparing to a date range.
It uses HAVING COUNT(l.loan_id) > 1, which forces the database to group the entire table before filtering, instead of using an optimized subquery.
It directly joins the books table with loans without checking for indexes on book_id, which can affect performance in large tables.
*/

SELECT b.title, COUNT(l.loan_id) AS times_borrowed
FROM books b
JOIN loans l ON b.book_id = l.book_id
WHERE YEAR(l.loan_date) = YEAR(NOW()) - 1
GROUP BY b.title

/*
Optimization explanation:

Eliminates the evaluation of YEAR() on each row, reducing CPU usage.
Uses indexes on book_id and loan_date, ensuring fast searches.
Avoid counting more data than necessary thanks to HAVING with aliases.
*/

SELECT b.title, COUNT(l.loan_id) AS times_borrowed
FROM books b
JOIN loans l ON b.book_id = l.book_id
WHERE l.loan_date >= ADD_MONTHS(TRUNC(CURRENT_DATE), -12)
AND l.loan_date <= TRUNC(CURRENT_DATE)
GROUP BY b.book_id, b.title
HAVING COUNT(l.loan_id) > 1;
----------------------------------------------------------------------------------------------------------------------------------------------------------
/*
The library wants to identify the most active users over the past 6 months, obtaining:
User who has borrowed the most books
Number of books borrowed
Date of last loan
Average loan length (in days)
*/

/*
Errors and Performance Issues

A subquery is used to count loans instead of a direct COUNT(), causing unnecessary table access repetitions.
Instead of a simple MAX(loan_date), the query performs an extra search for each user, making the process unnecessarily costly.
Another subquery is used to calculate the average loan, duplicating work instead of calculating it in the GROUP BY.
The old JOIN syntax is used, which can cause problems in large databases and makes the code difficult to read.
BETWEEN is less efficient and less clear in certain database engines; it's better to use >= and <=.
*/
SELECT u.user_id, 
       u.first_name || ' ' || u.last_name AS full_name, 
       (SELECT COUNT(*) FROM loans l WHERE l.user_id = u.user_id) AS total_loans,
       (SELECT MAX(loan_date) FROM loans WHERE user_id = u.user_id) AS last_loan_date,
       (SELECT AVG(return_date - loan_date) FROM loans WHERE user_id = u.user_id) AS avg_loan_duration
FROM users u, loans l
WHERE u.user_id = l.user_id
AND loan_date BETWEEN ADD_MONTHS(CURRENT_DATE, -6) AND CURRENT_DATE
GROUP BY u.user_id, u.first_name, u.last_name
ORDER BY total_loans DESC;

/*
Efficient JOIN: Joins the users table with loans using user_id.
Optimized WHERE: Filters loans only from the last 6 months (ADD_MONTHS(CURRENT_DATE, -6)).
MAX(): Returns the date of the last loan.
AVG(return_date - loan_date): Calculates the average number of loan days (by subtracting dates in Oracle).
HAVING COUNT(l.loan_id) > 5: Only users with more than 5 loans.
ORDER BY total_loans DESC, last_loan_date DESC: Lists the most active loans first.
*/

SELECT u.user_id, 
       u.first_name || ' ' || u.last_name AS full_name, 
       COUNT(l.loan_id) AS total_loans,
       MAX(l.loan_date) AS last_loan_date,
       ROUND(AVG(l.return_date - l.loan_date), 2) AS avg_loan_duration
FROM users u
JOIN loans l ON u.user_id = l.user_id
WHERE l.loan_date >= ADD_MONTHS(TRUNC(CURRENT_DATE), -6) 
AND l.loan_date <= TRUNC(CURRENT_DATE)
GROUP BY u.user_id, u.first_name, u.last_name
HAVING COUNT(l.loan_id) > 5
ORDER BY total_loans DESC, last_loan_date DESC;

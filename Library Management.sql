-- [Project Tasks]
select * from issued_status
select * from branch
select * from books
select * from book_counts
select * from employees
select * from members
select * from return_status


-- Task 1.Create a New Book Record 
-- "978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')"

INSERT INTO books(isbn , book_title , category , rental_price , status , author , publisher )
VALUES ('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')

-- Task 2: Update an Existing Member's Address

UPDATE members
SET member_address = '125 Oak St'
WHERE member_id = 'C103';

-- Task 3: Delete a Record from the Issued Status Table 

DELETE FROM issued_status
WHERE   issued_id =   'IS121';

-- Task 4: Retrieve All Books Issued by a Specific Employee

SELECT * FROM issued_status
WHERE issued_emp_id = 'E101'

-- Task 5: List Members Who Have Issued More Than One Book 

with sub_table
as
(SELECT issued_member_id,count(*) as sales
FROM issued_status
group by 1)


select issued_member_id from sub_table
where sales > 1

SELECT issued_member_id,count(*) as sales
FROM issued_status
GROUP BY 1
HAVING COUNT(*)>1


-- Task 6: Create Summary Tables : Used CTAS to generate new tables based on query results - each book and total book_issued_cnt
-- CTAS (Create Table As Select)

CREATE TABLE book_counts
AS
SELECT isbn,book_title,COUNT(*) as Count
FROM books as a
JOIN
issued_status as b 
ON 
b.issued_book_isbn = a.isbn
GROUP BY 1

-- Task 7: Retrieve All Books in a Specific Category :

SELECT * FROM books
WHERE category = 'Dystopian'

-- Task 8: Find Total Rental Income by Category:


SELECT category,sum(rental_price),count(*)
FROM book_coun
GROUP BY 1

-- OR 

SELECT 
    b.category,
    SUM(b.rental_price),
    COUNT(*)
FROM 
issued_status as ist
JOIN
books as b
ON b.isbn = ist.issued_book_isbn
GROUP BY 1

-- 9.List Members Who Registered in the Last 180 Days : (no data within 180 days , if needed insert few )

SELECT * FROM members
WHERE reg_date >= current_date - interval '180 days'

-- 10.List Employees with Their Branch Manager's Name and their branch details:

SELECT x.emp_id,x.emp_name,y.*
FROM
employees AS x
JOIN 
branch AS y
ON
x.branch_id = y.branch_id 

-- OR

SELECT 
    e1.emp_id,
    e1.emp_name,
    e1.position,
    e1.salary,
    b.*,
    e2.emp_name as manager
FROM employees as e1
JOIN 
branch as b
ON e1.branch_id = b.branch_id    
JOIN
employees as e2
ON e2.emp_id = b.manager_id


-- Task 11.Create a Table of Books with Rental Price Above a Certain Threshold :


CREATE TABLE expensive_books
AS
SELECT * FROM books
WHERE rental_price > 7.00

-- Task 12:Retrieve the List of Books Not Yet Returned :

SELECT issued_book_name
FROM 
issued_status as A
LEFT JOIN
return_status as B
ON
A.issued_id = B.issued_id
WHERE B.issued_id IS NULL

/* Task 13: Identify Members with Overdue Books**  
Write a query to identify members who have overdue books (assume a 30-day return period). 
Display the member's_id, member's name, book title, issue date, and days overdue.
*/

SELECT 

B.member_id,
B.member_name,
C.book_title,
A.issued_id,
CURRENT_DATE - issued_date as Overdue

FROM 
issued_status AS A
JOIN 
members AS B
ON 
B.member_id = A.issued_member_id
JOIN
books AS C
ON
C.isbn = A.issued_book_isbn
LEFT JOIN 
return_status AS D
ON
D.issued_id = A.issued_id
WHERE return_date IS NULL
AND 
(CURRENT_DATE - issued_date) > 30 
ORDER BY 1

/*Task 14: Update Book Status on Return**  
Write a query to update the status of books in the books table to "Yes" 
when they are returned (based on entries in the return_status table) */


CREATE OR REPLACE PROCEDURE book_updation(p_return_id VARCHAR (10),p_issued_id VARCHAR (10))
LANGUAGE plpgsql
AS $$
DECLARE 

    v_isbn VARCHAR(50);
	v_book VARCHAR(80);

BEGIN

   INSERT INTO return_status (return_id,issued_id,return_date)
   VALUES (p_return_id,p_issued_id,CURRENT_DATE);


   SELECT issued_book_isbn,issued_book_name
   INTO v_isbn,v_book
   FROM issued_status
   WHERE issued_id = p_issued_id;


   UPDATE books
   SET status = 'yes'
   WHERE isbn = v_isbn;

   RAISE NOTICE 'THANKS FOR RETURNING THE BOOK : % ' , v_book ;


END;
$$

SELECT * FROM return_status
SELECT * FROM books
where isbn = '978-0-375-41398-8'
SELECT * FROM issued_status
WHERE issued_id = 'IS135'

-- 978-0-307-58837-1
-- IS135

CALL book_updation('RS120','IS135')



/* Task 15: Branch Performance Report 
Create a query that generates a performance report for each branch, showing the number of books issued, 
the number of books returned, and the total revenue generated from book rentals.*/


CREATE TABLE branch_report
AS
SELECT 
    
	B.branch_id,
    B.manager_id,
    COUNT(issue.issued_id) as number_book_issued,
    COUNT(return.return_id) as number_of_book_return,
    SUM(bk.rental_price) as total_revenue

FROM 
issued_status AS issue
JOIN
employees AS emp
ON
issue.issued_emp_id = emp.emp_id
JOIN 
branch AS B
ON 
B.branch_id = emp.branch_id
LEFT JOIN
return_status AS return
ON
issue.issued_id = return.issued_id
JOIN
books AS bk
ON
bk.isbn = issue.issued_book_isbn
GROUP BY 1,2

SELECT * FROM branch_report


/* Task 16: CTAS: Create a Table of Active Members
Use the CREATE TABLE AS (CTAS) statement to create a new table 
active_members containing members who have issued at least one book in the last 2 months. */

CREATE TABLE active_members
AS
SELECT issued_member_id,issued_date
FROM issued_status
WHERE (CURRENT_DATE - issued_date) < 60
                    

SELECT * FROM active_members

/* Task 17: Find Employees with the Most Book Issues Processed**  
Write a query to find the top 3 employees who have processed the most book issues. 
Display the employee name, number of books processed, and their branch.*/

SELECT 
emp.emp_name,
count(issued_book_name) AS No_of_Books,
branch.branch_id
FROM 
issued_status as issue
JOIN
employees as emp
ON
issue.issued_emp_id = emp.emp_id
JOIN
branch AS branch
ON
emp.branch_id = branch.branch_id
GROUP BY 1,3
ORDER BY 2 DESC
LIMIT 3

/* Task 18: Identify Members Issuing High-Risk Books**  
Write a query to identify members 
who have issued books more than twice with the status "damaged" in the books table. 
Display the member name, book title, and the number of times they've issued damaged books. */   

SELECT 
member_name,
issued_book_name,
count(issued_book_name) AS Total
FROM
issued_status AS issue
JOIN
members AS mem
ON
issued_member_id = member_id
GROUP BY 1,2
ORDER BY 3 DESC  -- AS I DON'T HAVE THE BOOK_QUALITY COLUMN , I HAVE'NT SATISFIED THE QUERY

















